import Foundation
import Testing
import StateModel
@testable import SQLiteDB
import BinaryCodable

extension BinaryCodable.BinaryEncoder: SQLiteDB.GenericEncoder { }
extension BinaryCodable.BinaryDecoder: SQLiteDB.GenericDecoder { }

extension SQLiteDatabase<BinaryCodable.BinaryEncoder, BinaryCodable.BinaryDecoder> {

    convenience init() throws {
        try self.init(encoder: .init(), decoder: .init())
    }
}

@Test("Test primitive read/write")
func testPrimitiveReadWrite() throws {
    let database = try SQLiteDatabase<BinaryCodable.BinaryEncoder, BinaryCodable.BinaryDecoder>()

    var property = 1

    func testGetSet<T: Codable & Equatable>(_ value: T, of type: T.Type = T.self) {
        let path = TestDatabase.KeyPath(model: 1, instance: 1, property: property)
        database.set(value, for: path)
        guard let retrievedValue = database.get(path, of: T.self) else {
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
    let encoded = try BinaryCodable.BinaryEncoder().encode(value)
    print(encoded)
    let decoded = try BinaryCodable.BinaryDecoder().decode(Int??.self, from: encoded)
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
