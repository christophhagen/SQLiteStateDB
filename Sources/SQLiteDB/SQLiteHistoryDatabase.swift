import Foundation
import SQLite
import StateModel

typealias Timestamped<T> = (value: T, date: Date)

/**
 A SQLite Database suitable to act as a database for StateModel.

 The database separates the values into separate databases for integers, doubles, strings, and data.
 An additional table tracks the model instance status properties to provide the model selection functionality.
 All values are stored with a timestamp to provide a history.
 */
public final class SQLiteHistoryDatabase: HistoryDatabase {

    /// The connection to the database
    private let connection: Connection

    /// The table to store all values that can be converted to integers
    private let integerTable: TimestampedDatabaseTable<Int64>

    /// The table to store all values that can be converted to double values
    private let doubleTable: TimestampedDatabaseTable<Double>

    /// The table to store strings and optional strings
    private let stringTable: TimestampedDatabaseTable<String>

    /// The table to store binary values and any encodable types that don't match the other tables
    private let binaryTable: TimestampedDatabaseTable<Data>

    /// The table to store the current status for all instances for quicker retrieval on select queries
    private let instanceTable: TimestampedInstanceTable

    /// The encoder to use for `Codable` types that do not match as integers, doubles or strings
    private let encoder: any GenericEncoder

    ///The decoder to use for `Codable` types that do not match as integers, doubles or strings
    private let decoder: any GenericDecoder

    /**
     Create or open a SQLite database.

     The required tables and indices will be created if they don't exist in the database.

     - Parameter file: The path to the database file.
     - Parameter encoder: The encoder to use for `Codable` types.
     - Parameter decoder: The decoder to use for `Codable` types.
     - Throws: `SQLite.Result` errors if the database could not be opened, or tables and indices could not be created.
     */
    public init(file: URL, encoder: any GenericEncoder, decoder: any GenericDecoder) throws {
        self.encoder = encoder
        self.decoder = decoder

        let database = try Connection(file.path)
        self.connection = database

        self.integerTable = try .init(name: "i", database: database)
        self.doubleTable = try .init(name: "d", database: database)
        self.stringTable = try .init(name: "s", database: database)
        self.binaryTable = try .init(name: "b", database: database)
        self.instanceTable = try .init(name: "o", database: database)
    }


    // MARK: Generic functions

    /**
     Internal function to set properties.
     */
    private func storeThrowing<Value>(_ value: Value, for path: Path, at date: Date?) throws where Value: Codable {
        let storedDate = date ?? Date()
        switch Value.self {
        case is InstanceStatus.Type:
            // Catch instance status updates first,
            // which are additionally stored in a separate table for selecting models
            try storeStatus(value as! InstanceStatus, for: path, at: storedDate)
        case is IntegerConvertible.Type:
            // Detect integers next, since those are assumed the most likely
            try storeInt((value as! IntegerConvertible).intValue, for: path, at: storedDate)
        case is OptionalIntegerConvertible.Type:
            try storeInt((value as! OptionalIntegerConvertible).intValue, for: path, at: storedDate)
        case is DoubleConvertible.Type:
            try storeDouble((value as! DoubleConvertible).doubleValue, for: path, at: storedDate)
        case is OptionalDoubleConvertible.Type:
            try storeDouble((value as! OptionalDoubleConvertible).doubleValue, for: path, at: storedDate)
        case is String.Type:
            try storeString(value as! String?, for: path, at: storedDate)
        case is String?.Type:
            // We check against the type instead of using `as?`,
            // since this would match other nil values as well
            try storeString(value as! String?, for: path, at: storedDate)
        case is Data.Type:
            try storeData(value as! Data?, for: path, at: storedDate)
        case is Data?.Type:
            // We check against the type instead of using `as?`,
            // since this would match other nil values as well
            try storeData(value as! Data?, for: path, at: storedDate)
        case is CodableOptional.Type:
            try storeOptionalCodable(value as! CodableOptional, for: path, at: storedDate)
        default:
            try storeCodable(value, for: path, at: storedDate)
        }
    }

    private func readThrowing<Value>(_ path: Path, at date: Date?) throws -> (value: Value, date: Date)? where Value: DatabaseValue {
        switch Value.self {
        case is InstanceStatus.Type:
            // First match instance information
            // The info is still stored in the integer table,
            // so we get the info from there
            return try readStatus(path, at: date).asResult()
        case let IntValue as IntegerConvertible.Type:
            // Get all integer values
            guard let (value, date) = try readInt(path, at: date) else { return nil }
            return (value.converted(to: IntValue.self).asResult(), date)
        case let IntValue as OptionalIntegerConvertible.Type:
            guard let (value, date) = try readOptionalInt(path, at: date) else { return nil }
            return (IntValue.init(intValue: value) as! Value, date)
        case let DoubleValue as DoubleConvertible.Type:
            guard let (value, date) = try readDouble(path, at: date) else { return nil }
            return (value.converted(to: DoubleValue.self).asResult(), date)
        case let DoubleValue as OptionalDoubleConvertible.Type:
            guard let (value, date) = try readDouble(path, at: date) else { return nil }
            return (DoubleValue.init(doubleValue: value) as! Value, date)
        case is String.Type:
            return try readString(path, at: date).asResult()
        case is String?.Type:
            return try readOptionalString(path, at: date).asResult()
        case is Data.Type:
            return try readData(path, at: date).asResult()
        case is Data?.Type:
            return try readOptionalData(path, at: date).asResult()
        case let OptionalValue as CodableOptional.Type:
            return try read(codableOptional: OptionalValue.self, path, at: date).asResult()
        default:
            return try read(codable: Value.self, path, at: date)
        }
    }

    // MARK: Typed setters

    func storeStatus(_ value: InstanceStatus, for path: Path, at date: Date) throws {
        // If the instance status really targets an instance, also save the info to an additional table
        // This is used to improve the select queries, where only the most recent values are of interest
        // Storage is only performed only if the timestamp of the current sample is newer
        if path.property == PropertyKey.instanceId {
            try storeInstanceStatus(value, for: path, at: date)
        }
        // We still need to save the full sample, to get the history
        return try storeInt(value.rawValue.intValue, for: path, at: date)
    }

    private func storeInstanceStatus(_ value: InstanceStatus, for path: Path, at date: Date) throws {
        if let previous = try instanceTable.value(for: path.model, instance: path.instance)?.date,
           previous > date {
            return
        }
        try instanceTable.update(value: value, model: path.model, instance: path.instance, timestamp: date)
    }

    func storeOptionalCodable(_ value: any CodableOptional, for path: Path, at date: Date) throws {
        // For Codable types, unpack one level of Optionals which is
        // handled by SQLite NULL values
        if value.isNil {
            try binaryTable.insert(value: nil, for: path, at: date)
        } else {
            let data: Data? = try value.encodeWrapped(with: encoder)
            try storeData(data, for: path, at: date)
        }
    }

    @inline(__always)
    func storeCodable<Value: Codable>(_ value: Value, for path: Path, at date: Date) throws {
        // Encode non-optionals
        let data: Data? = try encoder.encode(value)
        return try storeData(data, for: path, at: date)
    }

    @inline(__always)
    func storeInt(_ value: Int64?, for path: Path, at date: Date) throws {
        try integerTable.insert(value: value, for: path, at: date)
    }

    @inline(__always)
    func storeDouble(_ value: Double?, for path: Path, at date: Date) throws {
        try doubleTable.insert(value: value, for: path, at: date)
    }

    @inline(__always)
    func storeString(_ value: String?, for path: Path, at date: Date) throws {
        try stringTable.insert(value: value, for: path, at: date)
    }

    @inline(__always)
    func storeData(_ value: Data?, for path: Path, at date: Date) throws {
        try binaryTable.insert(value: value, for: path, at: date)
    }

    // MARK: Typed getters

    @inline(__always)
    func readStatus(_ path: Path, at date: Date?) throws -> Timestamped<InstanceStatus>? {
        if path.property == PropertyKey.instanceId, date == nil {
            return try instanceTable.value(for: path.model, instance: path.instance)
        }
        guard let (raw, date) = try readInt(path, at: date),
              let value = raw.converted(to: InstanceStatus.self) else {
            return nil
        }
        return (value, date)
    }

    @inline(__always)
    func readInt(_ path: Path, at date: Date?) throws -> Timestamped<Int64>? {
        try integerTable.value(for: path, at: date)
    }

    @inline(__always)
    func readOptionalInt(_ path: Path, at date: Date?) throws -> Timestamped<Int64?>? {
        try integerTable.optionalValue(for: path, at: date)
    }

    @inline(__always)
    func readDouble(_ path: Path, at date: Date?) throws -> Timestamped<Double>? {
        try doubleTable.value(for: path, at: date)
    }

    @inline(__always)
    func readOptionalDouble(_ path: Path, at date: Date?) throws -> Timestamped<Double?>? {
        try doubleTable.optionalValue(for: path, at: date)
    }

    @inline(__always)
    func readString(_ path: Path, at date: Date?) throws -> Timestamped<String>? {
        try stringTable.value(for: path, at: date)
    }

    @inline(__always)
    func readOptionalString(_ path: Path, at date: Date?) throws -> Timestamped<String?>? {
        try stringTable.optionalValue(for: path, at: date)
    }

    @inline(__always)
    func readData(_ path: Path, at date: Date?) throws -> Timestamped<Data>? {
        try binaryTable.value(for: path, at: date)
    }

    @inline(__always)
    func readOptionalData(_ path: Path, at date: Date?) throws -> Timestamped<Data?>? {
        try binaryTable.optionalValue(for: path, at: date)
    }

    @inline(__always)
    func read<T>(codableOptional: T.Type, _ path: Path, at date: Date?) throws -> Timestamped<T>? where T: CodableOptional {
        guard let (data, date) = try readOptionalData(path, at: date) else {
            return nil
        }
        if let data {
            let value = try T.decodeWrapped(from: data, with: decoder)
            return (value, date)
        } else {
            return (T.nilValue, date)
        }
    }

    @inline(__always)
    func read<Value>(codable: Value.Type, _ path: Path, at date: Date?) throws -> Timestamped<Value>? where Value: Codable {
        guard let (data, date) = try readData(path, at: date) else {
            return nil
        }
        let value = try decoder.decode(Value.self, from: data)
        return (value, date)
    }

// MARK: Database protocol

    /**
     Get the value for a specific property.
     - Parameter path: The unique identifier of the property
     - Returns: The value of the property, if one exists
     */
    public func get<Value>(_ path: Path, at date: Date?) -> (value: Value, date: Date)? where Value: DatabaseValue {
        do {
            return try readThrowing(path, at: date)
        } catch {
            print("Failed to get \(path): \(error)")
            return nil
        }
    }

    /**
     Set the value for a specific property.
     - Parameter value: The new value to set for the property
     - Parameter path: The unique identifier of the property
     */
    public func set<Value>(_ value: Value, for path: Path, at date: Date?) where Value: DatabaseValue {
        do {
            return try storeThrowing(value, for: path, at: date)
        } catch {
            print("Failed to set \(path) to \(value): \(error)")
        }
    }

    /**
     Provide specific properties in the database to a conversion function.

     This function must provide all properties in the database that match a model id and a property id,
     and that are of type `InstanceStatus`. This function is used to select all instances of a model with specific properties.
     - Parameter modelId: The model id to match
     - Parameter propertyId: The property id to match
     - Parameter predicate: The conversion function to call for each result of the search
     - Parameter instanceId: The instance id of the path that contained the `status`
     - Parameter status: The instance status of the path.
     - Returns: The list of all search results that were returned by the `predicate`
     */
    public func all<T>(
        model: ModelKey,
        at date: Date?,
        where predicate: (_ instance: InstanceKey, _ status: InstanceStatus, _ date: Date) -> T?
    ) -> [T] {
        do {
            return try instanceTable.all(model: model, where: predicate)
        } catch {
            print("Failed to select \(String(describing: T.self)): \(error)")
            return []
        }
    }

    // MARK: Counting

    /// The number of entries in the table for integer values
    public var numberOfIntegerValues: Int {
        integerTable.count
    }

    /// The number of entries in the table for double values
    public var numberOfDoubleValues: Int {
        doubleTable.count
    }

    /// The number of entries in the table for string values
    public var numberOfStringValues: Int {
        stringTable.count
    }

    /// The number of entries in the table for data values
    public var numberOfBinaryValues: Int {
        binaryTable.count
    }

    /// The number of entries in the table for instance values
    public var numberOfInstances: Int {
        instanceTable.count
    }
}
