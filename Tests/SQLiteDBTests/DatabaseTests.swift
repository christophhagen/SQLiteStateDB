import Foundation
import Testing
import StateModel
@testable import SQLiteDB
import BinaryCodable

extension BinaryEncoder: GenericEncoder { }
extension BinaryDecoder: GenericDecoder { }

extension SQLiteDatabase<BinaryEncoder, BinaryDecoder> {

    convenience init() throws {
        try self.init(encoder: .init(), decoder: .init())
    }
}

@Suite("Database tests")
struct DatabaseTests {

    @Test("Test primitive read/write")
    func testPrimitiveReadWrite() throws {
        let database = try SQLiteDatabase<BinaryEncoder, BinaryDecoder>()

        var property = 1

        func testGetSet<T: Codable & Equatable>(_ value: T, of type: T.Type = T.self) {
            let path = TestDatabase.KeyPath(model: 1, instance: 1, property: property)
            database.set(value, for: path)
            guard let retrievedValue: T = database.get(path) else {
                Issue.record("Could not find value in database for '\(value)' (\(T.self))")
                return
            }
            #expect(retrievedValue == value)
            property += 1
        }

        testGetSet(1)

        testGetSet(.none, of: Int?.self)
        testGetSet(1, of: Int?.self)

        testGetSet(.none, of: Int??.self)
        testGetSet(.some(.none), of: Int??.self)
        testGetSet(1, of: Int??.self)

        testGetSet(.none, of: Int???.self)
        testGetSet(.some(.none), of: Int???.self)
        testGetSet(.some(.some(.none)), of: Int???.self)
        testGetSet(1, of: Int???.self)
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
