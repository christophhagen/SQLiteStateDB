import Foundation
import Testing
import SQLiteDB
import StateModel

private extension TestDatabase {
    func testGetSet<T: Codable & Equatable>(_ value: T, of type: T.Type = T.self, property: Int = 1) {
        let path = Path(model: 1, instance: 1, property: property)
        set(value, for: path)
        guard let retrievedValue: T = get(path) else {
            Issue.record("Could not find value in database for '\(value)' (\(T.self))")
            return
        }
        #expect(retrievedValue == value)
    }
}

@Suite("Primitives")
struct PrimitivesTests {

    @Test("Double")
    func testDoubleGetSet() throws {
        let database = try TestDatabase()

        database.testGetSet(3.14)
    }

    @Test("Double?")
    func testOptionalDoubleGetSet() throws {
        let database = try TestDatabase()

        database.testGetSet(3.14, of: Double?.self, property: 1)
        database.testGetSet(nil, of: Double?.self, property: 2)
    }

    @Test("String")
    func testStringGetSet() throws {
        let database = try TestDatabase()

        database.testGetSet("abc")
    }

    @Test("String?")
    func testOptionalStringGetSet() throws {
        let database = try TestDatabase()

        database.testGetSet("abc", of: String?.self, property: 1)
        database.testGetSet(nil, of: String?.self, property: 2)
    }

    @Test("Data")
    func testDataGetSet() throws {
        let database = try TestDatabase()

        database.testGetSet(Data(repeating: 3, count: 4), of: Data.self, property: 1)
        database.testGetSet(Data(), of: Data.self, property: 2)
    }

    @Test("Data?")
    func testOptionalDataGetSet() throws {
        let database = try TestDatabase()

        database.testGetSet(Data(repeating: 3, count: 4), of: Data?.self, property: 1)
        database.testGetSet(nil, of: Data?.self, property: 2)
    }

    @Test("Int??")
    func testDoubleOptionalIntGetSet() throws {
        let database = try TestDatabase()

        database.testGetSet(nil, of: Int??.self, property: 1)
        database.testGetSet(.some(nil), of: Int??.self, property: 2)
        database.testGetSet(.some(.some(1)), of: Int??.self, property: 3)
    }

    @Test("Int???")
    func testTripleOptionalIntGetSet() throws {
        let database = try TestDatabase()

        database.testGetSet(nil, of: Int???.self, property: 1)
        database.testGetSet(.some(nil), of: Int???.self, property: 2)
        database.testGetSet(.some(.some(1)), of: Int???.self, property: 3)

        // Special case:
        // Due to a bug in JSONEncoder (or the restrictions of the JSON format)
        // `nil` values in double optionals are always decoded as top level `nil` values,
        // so we adapt the test
        let value: Int??? = .some(.some(nil))

        let path = Path(model: 1, instance: 1, property: 1)
        database.set(value, for: path)
        guard let retrievedValue = database.get(path, of: Int???.self) else {
            Issue.record("Could not find value for triple optional")
            return
        }
        // We still retain one level of nesting that SQLite tables provide with NULL values
        let expected: Int??? = .some(nil)
        #expect(retrievedValue == expected)
    }

}
