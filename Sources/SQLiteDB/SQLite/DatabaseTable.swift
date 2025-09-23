import SQLite
import StateModel

/**
 A generic table to store values of a SQLite type.
 */
struct DatabaseTable<M: Value & ModelKeyType, I: Value & InstanceKeyType, P: Value & PropertyKeyType, T> where T: Value, M.Datatype: Equatable, I.Datatype: Equatable, P.Datatype: Equatable {

    typealias KeyPath = Path<M, I, P>

    /// The database connection to retrieve and insert values
    private let database: Connection

    /// The definition of the table
    private let table: Table

    /// The column for the model id of the path
    private let modelId = Expression<M>("m")

    /// The column for the instance id of the path
    private let instanceId = Expression<I>("i")

    /// The column for the property id of the path
    private let propertyId = Expression<P>("p")

    /// The column for the value itself
    private let value = Expression<T?>("v")

    /**
     Create a table object.

     Creating an object will automatically create the table and an index if either doesn't exist.
     */
    init(name: String, database: Connection) throws {
        self.database = database
        self.table = Table(name)

        /*
        CREATE TABLE int_records (
            m INTEGER NOT NULL,
            i INTEGER NOT NULL,
            p INTEGER NOT NULL,
            t DOUBLE NOT NULL,
            v <T>,
            PRIMARY KEY (m, i, p)
        ) WITHOUT ROWID;
        */
        let createQuery = table.create(ifNotExists: true, withoutRowid: true) {
            $0.column(modelId)
            $0.column(instanceId)
            $0.column(propertyId)
            $0.column(value)
            $0.primaryKey(modelId, instanceId, propertyId)
        }

        try database.run(createQuery)

        let indexQuery = table.createIndex(modelId, instanceId, propertyId, ifNotExists: true)
        try database.run(indexQuery)
    }

    /**
     Get a value for a path.
     - Parameter path: The path to search for in the table.
     - Returns: The value for the row with the given path, or `nil`, if the value column is `NULL` or if no row exists for the given path.
     */
    func value(for path: KeyPath) throws -> T? {
        let query = table
            .filter(modelId == path.model && instanceId == path.instance && propertyId == path.property)
        guard let row = try database.pluck(query) else {
            return nil
        }
        return row[value]
    }

    /**
     Get a value for a path if it exists.

     This function distinguishes between the presence of a `NULL` value (where it returns `.some(nil)`) and the absence of a row for the path (where it returns `nil`).
     - Parameter path: The path to search for in the table.
     - Returns: The value for the row with the given path,`nil`, if no row exists for the given path, or `.some(nil)`, if the value column is `NULL`.
     */
    func optionalValue(for path: KeyPath) throws -> T?? {
        let query = table
            .filter(modelId == path.model && instanceId == path.instance && propertyId == path.property)
            .limit(1)
        guard let row = try database.pluck(query) else {
            return .none
        }
        return .some(row[value])
    }

    func insert(value: T?, for path: KeyPath) throws {
        let query = table.insert(
            or: .replace,
            modelId <- path.model,
            instanceId <- path.instance,
            propertyId <- path.property,
            self.value <- value
        )

        try database.run(query)
    }

    var count: Int {
        (try? database.scalar(table.count)) ?? 0
    }
}
