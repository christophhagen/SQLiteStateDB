import Foundation
import SQLite
import StateModel

struct HistoryInstanceTable {

    private let database: Connection

    private let table: Table

    private let modelId = Expression<Int>("m")

    private let instanceId = Expression<Int>("i")

    private let timestamp = Expression<Double>("t")

    private let value = Expression<Int>("v")

    init(name: String, database: Connection) throws {
        self.database = database
        self.table = Table(name)

        /*
        CREATE TABLE int_records (
            m INTEGER NOT NULL,
            i INTEGER NOT NULL,
            t DOUBLE NOT NULL,
            v INTEGER NOT NULL,
            PRIMARY KEY (m, i)
        ) WITHOUT ROWID;
        */
        let createQuery = table.create(ifNotExists: true, withoutRowid: true) {
            $0.column(modelId)
            $0.column(instanceId)
            $0.column(timestamp)
            $0.column(value)
            $0.primaryKey(modelId, instanceId)
        }

        try database.run(createQuery)

        let indexQuery = table.createIndex(modelId, instanceId, timestamp.desc, ifNotExists: true)
        try database.run(indexQuery)
    }

    func all<T>(model: ModelKey, where predicate: (_ instance: InstanceKey, _ status: InstanceStatus, _ date: Date) -> T?) throws -> [T] {
        let query = table
            .filter(modelId == model)
        return try database.prepare(query).compactMap { row in
            guard let status = InstanceStatus(rawValue: UInt8(row[value])) else {
                return nil
            }
            let instance = row[instanceId]
            return predicate(instance, status, Date(timeIntervalSince1970: row[timestamp]))
        }
    }

    func update(value: InstanceStatus, model: ModelKey, instance: InstanceKey, timestamp: Date = Date()) throws {
        let query = table.insert(or: .replace,
            modelId <- model,
            instanceId <- instance,
            self.timestamp <- timestamp.timeIntervalSince1970,
            self.value <- Int(value.rawValue)
        )
        try database.run(query)
    }

    /**
     Get a value for a path.
     - Parameter path: The path to search for in the table.
     - Returns: The value for the row with the given path, or `nil`, if the value column is `NULL` or if no row exists for the given path.
     */
    func value(for model: ModelKey, instance: InstanceKey) throws -> Timestamped<InstanceStatus>? {
        let query = table
            .filter(modelId == model && instanceId == instance)
            .order(timestamp.desc)
            .limit(1)
        guard let row = try database.pluck(query) else {
            return nil
        }
        let raw = UInt8(row[value])
        guard let value = InstanceStatus(rawValue: raw) else {
            return nil
        }
        let date = Date(timeIntervalSince1970: row[timestamp])
        return .init(value: value, date: date)
    }

    var count: Int {
        (try? database.scalar(table.count)) ?? 0
    }
}
