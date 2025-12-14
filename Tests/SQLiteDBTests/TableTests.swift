import Foundation
import Testing
import SQLiteDB
import StateModel

@Suite("Tables")
struct TableTests {

    /**
     Check that inserting a value for the same timestamp updates the value
     instead of creating an additional entry.
     */
    @Test("Insert twice")
    func insertSameTimestampTwice() async throws {

        do {
            let database = try SQLiteHistoryDatabase()

            #expect(database.numberOfIntegerValues == 0)
            let now = Date()
            database.set(123, model: 1, instance: 1, property: 1, at: now)
            #expect(database.numberOfIntegerValues == 1)
            database.set(124, model: 1, instance: 1, property: 1, at: now)
            #expect(database.numberOfIntegerValues == 1)

            database.set(123, model: 1, instance: 1, property: 1, at: now.addingTimeInterval(1))
            #expect(database.numberOfIntegerValues == 2)
        }

        do {
            let database = try SQLiteTimestampedDatabase()

            #expect(database.numberOfIntegerValues == 0)
            database.set(123, model: 1, instance: 1, property: 1)
            #expect(database.numberOfIntegerValues == 1)
            database.set(124, model: 1, instance: 1, property: 1)
            #expect(database.numberOfIntegerValues == 1)

            database.set(123, model: 1, instance: 1, property: 1)
            #expect(database.numberOfIntegerValues == 1)
        }
    }

    /**
     Check that inserting an instance status with an old value does not update the instance table.
     */
    @Test("Insert old instance status")
    func insertOldStatus() async throws {

        let database = try SQLiteHistoryDatabase()

        #expect(database.numberOfInstances == 0)
        #expect(database.numberOfIntegerValues == 0)
        let now = Date()
        database.set(InstanceStatus.created, model: 1, instance: 1, property: Int.instanceId, at: now)
        #expect(database.numberOfInstances == 1)
        #expect(database.numberOfIntegerValues == 1)

        // Insert older value
        database.set(InstanceStatus.deleted, model: 1, instance: 1, property: Int.instanceId, at: now.addingTimeInterval(-1.0))
        #expect(database.numberOfInstances == 1)
        #expect(database.numberOfIntegerValues == 2)

        let data: Timestamped<InstanceStatus>? = database.get(model: 1, instance: 1, property: Int.instanceId, at: now)
        #expect(data != nil)
        #expect(data?.value == .created)

        let currentData: Timestamped<InstanceStatus>? = database.get(model: 1, instance: 1, property: Int.instanceId, at: nil)
        #expect(currentData != nil)
        let current: InstanceStatus? = database.get(model: 1, instance: 1, property: Int.instanceId)
        #expect(current != nil)
    }
}
