import Foundation
import Testing
import StateModel
@testable import SQLiteDB
import BinaryCodable

extension BinaryEncoder: @retroactive GenericEncoder { }
extension BinaryDecoder: @retroactive GenericDecoder { }


@Suite("Database tests")
struct DatabaseTests {

    @Test("Test primitive read/write")
    func testPrimitiveReadWrite() throws {
        let database = try SQLiteDatabase(encoder: BinaryEncoder(), decoder: BinaryDecoder())

        var property = 1

        func testGetSet<T: Codable & Equatable>(_ value: T, of type: T.Type = T.self) {
            let path = Path(model: 1, instance: 1, property: property)
            database.set(value, for: path)
            guard let retrievedValue: T = database.get(path) else {
                Issue.record("Could not find value in database for '\(value)' (\(T.self))")
                return
            }
            #expect(retrievedValue == value)
            property += 1
        }

        testGetSet(1)
        #expect(database.numberOfIntegerValues == 1)

        testGetSet(.none, of: Int?.self)
        #expect(database.numberOfIntegerValues == 2)
        testGetSet(1, of: Int?.self)
        #expect(database.numberOfIntegerValues == 3)

        testGetSet(.none, of: Int??.self)
        #expect(database.numberOfIntegerValues == 3)
        #expect(database.numberOfBinaryValues == 1)
        testGetSet(.some(.none), of: Int??.self)
        #expect(database.numberOfBinaryValues == 2)
        testGetSet(1, of: Int??.self)
        #expect(database.numberOfBinaryValues == 3)

        testGetSet(.none, of: Int???.self)
        #expect(database.numberOfBinaryValues == 4)
        testGetSet(.some(.none), of: Int???.self)
        #expect(database.numberOfBinaryValues == 5)
        testGetSet(.some(.some(.none)), of: Int???.self)
        #expect(database.numberOfBinaryValues == 6)
        testGetSet(1, of: Int???.self)
        #expect(database.numberOfBinaryValues == 7)
    }

    @Test("Invalid JSON optional encoding")
    func invalidJsonDecoding() async throws {
        let database = try SQLiteDatabase()

        let path = Path(model: 1, instance: 1, property: 1)

        let value: Int??? = .some(.some(.none))
        database.set(value, for: path)
        guard let retrievedValue: Int??? = database.get(path) else {
            Issue.record("Could not find value in database")
            return
        }
        // The database encodes .some(.none), which gets decoded to .none
        // The additional layer is captured by NULL/NOT NULL values in the database table
        let expected: Int??? = .some(nil)
        #expect(retrievedValue == expected)
        #expect(retrievedValue != value)
    }

    @Test("Top-level nested optional encoding")
    func testNestedOptionalEncoding() throws {
        let value: Int?? = .some(nil)
        let encoded = try BinaryEncoder().encode(value)
        print(encoded)
        let decoded = try BinaryDecoder().decode(Int??.self, from: encoded)
        #expect(value == decoded)
    }

    @Test("Nil detection for nested optionals")
    func testAnyOptionalComparison() {
        func testOptional<T>(_ value: T, isOptional: Bool) {
            if let opt = value as? CodableOptional {
                #expect(opt.isNil == isOptional)
            } else {
                Issue.record("\(T.self) does not conform to AnyOptional")
            }
        }
        var value: Int?? = .some(.none)
        testOptional(value, isOptional: false)
        value = .none
        testOptional(value, isOptional: true)
        value = 1
        testOptional(value, isOptional: false)
    }
}
