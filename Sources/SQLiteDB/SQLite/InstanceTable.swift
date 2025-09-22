import SQLite
import StateModel

struct InstanceTable {

    private let database: Connection

    private let table: Table

    private let modelId = Expression<Int>("m")

    private let instanceId = Expression<Int>("i")

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
            $0.column(value)
            $0.primaryKey(modelId, instanceId)
        }

        try database.run(createQuery)

        let indexQuery = table.createIndex(modelId, instanceId, ifNotExists: true)
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

    func update(value: InstanceStatus, model: Int, instance: Int) throws {
        let query = table.insert(or: .replace,
            modelId <- model,
            instanceId <- instance,
            self.value <- Int(value.rawValue)
        )
        try database.run(query)
    }

    /**
     Get a value for a path.
     - Parameter path: The path to search for in the table.
     - Returns: The value for the row with the given path, or `nil`, if the value column is `NULL` or if no row exists for the given path.
     */
    func value(for model: Int, instance: Int) throws -> InstanceStatus? {
        let query = table
            .filter(modelId == model && instanceId == instance)
            .limit(1)
        guard let row = try database.pluck(query) else {
            return nil
        }
        let raw = UInt8(row[value])
        return .init(rawValue: raw)
    }

    var count: Int {
        (try? database.scalar(table.count)) ?? 0
    }
}
