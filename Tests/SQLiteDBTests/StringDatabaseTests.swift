import Foundation
import Testing
import SQLiteDB
import StateModel
import SQLite

extension String: @retroactive PropertyKeyType {

    public static let instanceId: String = "instance"
}

private typealias StringDatabase = SQLiteDatabase<String, String, String>

private final class StringModel: Model<String, String, String> {

    static let modelId: String = "model"

    @Property(id: "value")
    var value: Int
}

extension UInt8: @retroactive Value {

    public static func fromDatatypeValue(_ datatypeValue: Int) throws -> UInt8 {
        UInt8(datatypeValue)
    }
    
    public var datatypeValue: Int {
        Int(self)
    }
    
    public typealias Datatype = Int

    public static let declaredDatatype = "INTEGER"
}

extension UInt32: @retroactive Value {

    public typealias Datatype = Int

    public static let declaredDatatype = "INTEGER"

    public static func fromDatatypeValue(_ datatypeValue: Int) throws -> UInt32 {
        UInt32(datatypeValue)
    }

    public var datatypeValue: Int {
        Int(self)
    }
}

private typealias EfficientDatabase = SQLiteDatabase<UInt8, UInt32, UInt8>

private final class EfficientModel: Model<UInt8, UInt32, UInt8> {

    static let modelId: UInt8 = 1

    @Property(id: UInt8(1))
    var value: Int
}

@Suite("String database")
struct StringDatabaseTests {

    @Test("Property")
    func testGetSet() throws {
        let database = try StringDatabase(encoder: JSONEncoder(), decoder: JSONDecoder())

        let instance = database.create(id: "one", of: StringModel.self)
        instance.value = 123
        #expect(instance.value == 123)
    }

    @Test("Efficient paths")
    func testEfficientPaths() throws {
        let database = try EfficientDatabase(encoder: JSONEncoder(), decoder: JSONDecoder())

        let instance = database.create(id: 213, of: EfficientModel.self)
        instance.value = 123
        #expect(instance.value == 123)
    }
}
