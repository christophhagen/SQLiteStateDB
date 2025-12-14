import Testing
import SQLiteDB
import BinaryCodable
import StateModel

@Model(id: 1)
private final class InstanceModel {

    @Property(id: 1)
    var state: InstanceStatus = .deleted
}

@Suite("Instance status")
struct InstanceStatusTests {

    @Test("Get/set non-instance property")
    func testInstanceStatusProperty() throws {
        let database = try SQLiteDatabase()
        let instance: InstanceModel = database.create(id: 123)

        #expect(instance.state == .deleted)
        instance.state = .created
        #expect(instance.state == .created)
        instance.state = .deleted
        #expect(instance.state == .deleted)
    }

    @Test("Get/set non-status on instance path")
    func testNonStatusInstancePathProperty() throws {
        let database = try SQLiteDatabase()
        let path = Path(model: 1, instance: 1, property: Int.instanceId)
        let value: Int? = database.get(path)
        #expect(value == nil)
        database.set(123, for: path)
        let newValue: Int? = database.get(path)
        #expect(newValue == 123)
    }
}
