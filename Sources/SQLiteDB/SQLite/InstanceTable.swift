import Foundation
import SQLite
import StateModel

struct InstanceTable {

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
            PRIMARY KEY (m, i, t)
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

    func all<T>(model: Int, where predicate: (_ instance: Int, _ status: InstanceStatus) -> T?) throws -> [T] {
        let query = table
            .filter(modelId == model)
        return try database.prepare(query).compactMap { row in
            guard let status = InstanceStatus(rawValue: UInt8(row[value])) else {
                return nil
            }
            let instance = row[instanceId]
            return predicate(instance, status)
        }
    }

    func update(value: InstanceStatus, model: Int, instance: Int, timestamp: Date = Date()) throws {
        let query = table.insert(or: .replace,
            modelId <- model,
            instanceId <- instance,
            self.timestamp <- timestamp.timeIntervalSince1970,
            self.value <- Int(value.rawValue)
        )
        try database.run(query)
    }
}
