import CoreFoundation
import Testing
import StateModel

@Model(id: 1)
private final class NumberModel {

    @Property(id: 1)
    var int: Int?

    @Property(id: 2)
    var int8: Int8?

    @Property(id: 3)
    var int16: Int16?

    @Property(id: 4)
    var int32: Int32?

    @Property(id: 5)
    var int64: Int64?

    @Property(id: 6)
    var uint: UInt?

    @Property(id: 7)
    var uint8: UInt8?

    @Property(id: 8)
    var uint16: UInt16?

    @Property(id: 9)
    var uint32: UInt32?

    @Property(id: 10)
    var uint64: UInt64?

    @Property(id: 11)
    var double: Double?

    @Property(id: 12)
    var float: Float?

    @Property(id: 13)
    var float16: Float16?

    @Property(id: 14)
    var cgFloat: CGFloat?
}

@Suite("Optional properties")
struct OptionalNumberPropertyTests {

    @Test("Int")
    func testPropertyGetSetInt() throws {
        let database = try TestDatabase()

        let model: NumberModel = database.create(id: 123)
        #expect(model.int == nil)
        model.int = 42
        #expect(model.int == 42)
        model.int = Int.min
        #expect(model.int == Int.min)
    }

    @Test("Int8")
    func testPropertyGetSetInt8() throws {
        let database = try TestDatabase()

        let model: NumberModel = database.create(id: 123)
        #expect(model.int8 == nil)
        model.int8 = 42
        #expect(model.int8 == 42)
        model.int8 = Int8.min
        #expect(model.int8 == Int8.min)
    }

    @Test("Int16")
    func testPropertyGetSetInt16() throws {
        let database = try TestDatabase()

        let model: NumberModel = database.create(id: 123)
        #expect(model.int16 == nil)
        model.int16 = 42
        #expect(model.int16 == 42)
        model.int16 = Int16.min
        #expect(model.int16 == Int16.min)
    }

    @Test("Int32")
    func testPropertyGetSetInt32() throws {
        let database = try TestDatabase()

        let model: NumberModel = database.create(id: 123)
        #expect(model.int32 == nil)
        model.int32 = 42
        #expect(model.int32 == 42)
        model.int32 = Int32.min
        #expect(model.int32 == Int32.min)
    }

    @Test("Int64")
    func testPropertyGetSetInt64() throws {
        let database = try TestDatabase()

        let model: NumberModel = database.create(id: 123)
        #expect(model.int64 == nil)
        model.int64 = 42
        #expect(model.int64 == 42)
        model.int64 = Int64.min
        #expect(model.int64 == Int64.min)
    }

    @Test("UInt")
    func testPropertyGetSetUInt() throws {
        let database = try TestDatabase()

        let model: NumberModel = database.create(id: 123)
        #expect(model.uint == nil)
        model.uint = 42
        #expect(model.uint == 42)
        model.uint = UInt.max
        #expect(model.uint == UInt.max)
    }

    @Test("UInt8")
    func testPropertyGetSetUInt8() throws {
        let database = try TestDatabase()

        let model: NumberModel = database.create(id: 123)
        #expect(model.uint8 == nil)
        model.uint8 = 42
        #expect(model.uint8 == 42)
        model.uint8 = UInt8.max
        #expect(model.uint8 == UInt8.max)
        model.uint8 = nil
        #expect(model.uint8 == nil)
    }

    @Test("UInt16")
    func testPropertyGetSetUInt16() throws {
        let database = try TestDatabase()

        let model: NumberModel = database.create(id: 123)
        #expect(model.uint16 == nil)
        model.uint16 = 42
        #expect(model.uint16 == 42)
        model.uint16 = UInt16.max
        #expect(model.uint16 == UInt16.max)
        model.uint16 = nil
        #expect(model.uint16 == nil)
    }

    @Test("UInt32")
    func testPropertyGetSetUInt32() throws {
        let database = try TestDatabase()

        let model: NumberModel = database.create(id: 123)
        #expect(model.uint32 == nil)
        model.uint32 = 42
        #expect(model.uint32 == 42)
        model.uint32 = UInt32.max
        #expect(model.uint32 == UInt32.max)
        model.uint32 = nil
        #expect(model.uint32 == nil)
    }

    @Test("UInt64")
    func testPropertyGetSetUInt64() throws {
        let database = try TestDatabase()

        let model: NumberModel = database.create(id: 123)
        #expect(model.uint64 == nil)
        model.uint64 = 42
        #expect(model.uint64 == 42)
        model.uint64 = UInt64.max
        #expect(model.uint64 == UInt64.max)
        model.uint64 = nil
        #expect(model.uint64 == nil)
    }

    @Test("Double")
    func testPropertyGetSetDouble() throws {
        let database = try TestDatabase()

        let model: NumberModel = database.create(id: 123)
        #expect(model.double == nil)
        model.double = 42.123
        #expect(model.double == 42.123)
        model.double = .greatestFiniteMagnitude
        #expect(model.double == .greatestFiniteMagnitude)
        model.double = nil
        #expect(model.double == nil)
    }

    @Test("Float")
    func testPropertyGetSetFloat() throws {
        let database = try TestDatabase()

        let model: NumberModel = database.create(id: 123)
        #expect(model.float == nil)
        model.float = 42
        #expect(model.float == 42)
        model.float = .greatestFiniteMagnitude
        #expect(model.float == .greatestFiniteMagnitude)
        model.float = nil
        #expect(model.float == nil)
    }

    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
    @Test("Float16")
    func testPropertyGetSetFloat16() throws {
        let database = try TestDatabase()

        let model: NumberModel = database.create(id: 123)
        #expect(model.float16 == nil)
        model.float16 = 42
        #expect(model.float16 == 42)
        model.float16 = .greatestFiniteMagnitude
        #expect(model.float16 == .greatestFiniteMagnitude)
        model.float16 = nil
        #expect(model.float16 == nil)
    }

    @Test("CGFloat")
    func testPropertyGetSetCGFloat() throws {
        let database = try TestDatabase()

        let model: NumberModel = database.create(id: 123)
        #expect(model.cgFloat == nil)
        model.cgFloat = 42
        #expect(model.cgFloat == 42)
        model.cgFloat = .greatestFiniteMagnitude
        #expect(model.cgFloat == .greatestFiniteMagnitude)
        model.cgFloat = nil
        #expect(model.cgFloat == nil)
    }
}
