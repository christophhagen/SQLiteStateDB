import Foundation
import SQLite
import StateModel

/**
 A SQLite Database suitable to act as a database for StateModel.

 The database separates the values into separate databases for integers, doubles, strings, and data.
 An additional table tracks the model instance status properties to provide the model selection functionality.
 All values are stored with a timestamp to provide a history.
 */
public final class SQLiteDatabase<Encoder: GenericEncoder, Decoder: GenericDecoder>: Database<Int, Int, Int> {

    public typealias KeyPath = Path<Int, Int, Int>

    public typealias Record = StateModel.Record<ModelKey, InstanceKey, PropertyKey>

    /// The connection to the database
    private let connection: Connection

    /// The table to store all values that can be converted to integers
    private let integerTable: DatabaseTable<Int64>

    /// The table to store all values that can be converted to double values
    private let doubleTable: DatabaseTable<Double>

    /// The table to store strings and optional strings
    private let stringTable: DatabaseTable<String>

    /// The table to store binary values and any encodable types that don't match the other tables
    private let binaryTable: DatabaseTable<Data>

    /// The table to store the current status for all instances for quicker retrieval on select queries
    private let instanceTable: InstanceTable

    /// The encoder to use for `Codable` types that do not match as integers, doubles or strings
    private let encoder: Encoder

    ///The decoder to use for `Codable` types that do not match as integers, doubles or strings
    private let decoder: Decoder

    /**
     Create or open a SQLite database.

     The required tables and indices will be created if they don't exist in the database.

     - Parameter file: The path to the database file.
     - Parameter encoder: The encoder to use for `Codable` types.
     - Parameter decoder: The decoder to use for `Codable` types.
     - Throws: `SQLite.Result` errors if the database could not be opened, or tables and indices could not be created.
     */
    public init(file: URL, encoder: Encoder, decoder: Decoder) throws {
        self.encoder = encoder
        self.decoder = decoder

        let database = try Connection(file.path)
        self.connection = database

        self.integerTable = try .init(name: "i", database: database)
        self.doubleTable = try .init(name: "d", database: database)
        self.stringTable = try .init(name: "s", database: database)
        self.binaryTable = try .init(name: "b", database: database)
        self.instanceTable = try .init(name: "o", database: database)
        super.init()
    }


    // MARK: Generic functions

    /**
     Internal function to set properties.
     */
    private func storeThrowing<Value>(_ value: Value, for path: KeyPath) throws where Value: Codable {
        switch Value.self {
        case is InstanceStatus.Type:
            // Catch instance status updates first,
            // which are additionally stored in a separate table for selecting models
            try storeStatus(value as! InstanceStatus, for: path)
        case is IntegerConvertible.Type:
            // Detect integers next, since those are assumed the most likely
            try storeInt((value as! IntegerConvertible).intValue, for: path)
        case is OptionalIntegerConvertible.Type:
            try storeInt((value as! OptionalIntegerConvertible).intValue, for: path)
        case is DoubleConvertible.Type:
            try storeDouble((value as! DoubleConvertible).doubleValue, for: path)
        case is OptionalDoubleConvertible.Type:
            try storeDouble((value as! OptionalDoubleConvertible).doubleValue, for: path)
        case is String.Type:
            try storeString(value as! String?, for: path)
        case is String?.Type:
            // We check against the type instead of using `as?`,
            // since this would match other nil values as well
            try storeString(value as! String?, for: path)
        case is Data.Type:
            try storeData(value as! Data?, for: path)
        case is Data?.Type:
            // We check against the type instead of using `as?`,
            // since this would match other nil values as well
            try storeData(value as! Data?, for: path)
        case is CodableOptional.Type:
            try storeOptionalCodable(value as! CodableOptional, for: path)
        default:
            try storeCodable(value, for: path)
        }
    }

    private func readThrowing<Value>(_ path: KeyPath) throws -> Value? where Value: Codable {
        switch Value.self {
        case is InstanceStatus.Type:
            // First match instance information
            // The info is still stored in the integer table,
            // so we get the info from there
            return try readStatus(path).asResult()
        case let IntValue as IntegerConvertible.Type:
            // Get all integer values
            return try readInt(path)?.converted(to: IntValue.self).asResult()
        case let IntValue as OptionalIntegerConvertible.Type:
            return try readOptionalInt(path).map { IntValue.init(intValue: $0) as! Value }
        case let DoubleValue as DoubleConvertible.Type:
            return try readDouble(path)?.converted(to: DoubleValue.self).asResult()
        case let DoubleValue as OptionalDoubleConvertible.Type:
            return try readOptionalDouble(path).map { DoubleValue.init(doubleValue: $0) as! Value }
        case is String.Type:
            return try readString(path).asResult()
        case is String?.Type:
            return try readOptionalString(path).asResult()
        case is Data.Type:
            return try readData(path).asResult()
        case is Data?.Type:
            return try readOptionalData(path).asResult()
        case let OptionalValue as CodableOptional.Type:
            return try read(codableOptional: OptionalValue.self, path).asResult()
        default:
            return try read(codable: Value.self, path)
        }
    }

    // MARK: Typed setters

    func storeStatus(_ value: InstanceStatus, for path: KeyPath) throws {
        // If the instance status really targets an instance, also save the info to an additional table
        // This is used to improve the select queries, where only the most recent values are of interest
        if path.property == PropertyKey.instanceId {
            try instanceTable.update(value: value, model: path.model, instance: path.instance)
        }
        // We still need to save the full sample, to get the history
        return try storeInt(value.rawValue.intValue, for: path)
    }

    func storeOptionalCodable(_ value: any CodableOptional, for path: KeyPath) throws {
        // For Codable types, unpack one level of Optionals which is
        // handled by SQLite NULL values
        if value.isNil {
            try binaryTable.insert(value: nil, for: path)
        } else {
            let data: Data? = try value.encodeWrapped(with: encoder)
            try storeData(data, for: path)
        }
    }

    @inline(__always)
    func storeCodable<Value: Codable>(_ value: Value, for path: KeyPath) throws {
        // Encode non-optionals
        let data: Data? = try encoder.encode(value)
        return try storeData(data, for: path)
    }

    @inline(__always)
    func storeInt(_ value: Int64?, for path: KeyPath) throws {
        try integerTable.insert(value: value, for: path)
    }

    @inline(__always)
    func storeDouble(_ value: Double?, for path: KeyPath) throws {
        try doubleTable.insert(value: value, for: path)
    }

    @inline(__always)
    func storeString(_ value: String?, for path: KeyPath) throws {
        try stringTable.insert(value: value, for: path)
    }

    @inline(__always)
    func storeData(_ value: Data?, for path: KeyPath) throws {
        try binaryTable.insert(value: value, for: path)
    }

    // MARK: Typed getters

    @inline(__always)
    func readStatus(_ path: KeyPath) throws -> InstanceStatus? {
        if path.property == PropertyKey.instanceId {
            return try instanceTable.value(for: path.model, instance: path.instance)
        }
        return try readInt(path)?.converted(to: InstanceStatus.self)
    }

    @inline(__always)
    func readInt(_ path: KeyPath) throws -> Int64? {
        try integerTable.value(for: path)
    }

    @inline(__always)
    func readOptionalInt(_ path: KeyPath) throws -> Int64?? {
        try integerTable.optionalValue(for: path)
    }

    @inline(__always)
    func readDouble(_ path: KeyPath) throws -> Double? {
        try doubleTable.value(for: path)
    }

    @inline(__always)
    func readOptionalDouble(_ path: KeyPath) throws -> Double?? {
        try doubleTable.optionalValue(for: path)
    }

    @inline(__always)
    func readString(_ path: KeyPath) throws -> String? {
        try stringTable.value(for: path)
    }

    @inline(__always)
    func readOptionalString(_ path: KeyPath) throws -> String?? {
        try stringTable.optionalValue(for: path)
    }

    @inline(__always)
    func readData(_ path: KeyPath) throws -> Data? {
        try binaryTable.value(for: path)
    }

    @inline(__always)
    func readOptionalData(_ path: KeyPath) throws -> Data?? {
        try binaryTable.optionalValue(for: path)
    }

    @inline(__always)
    func read<T>(codableOptional: T.Type, _ path: KeyPath) throws -> T? where T: CodableOptional {
        guard let data = try readOptionalData(path) else {
            return nil
        }
        if let data {
            return try T.decodeWrapped(from: data, with: decoder)
        } else {
            return T.nilValue
        }
    }

    @inline(__always)
    func read<Value>(codable: Value.Type, _ path: KeyPath) throws -> Value? where Value: Codable {
        guard let data = try readData(path) else {
            return nil
        }
        return try decoder.decode(Value.self, from: data)
    }

// MARK: Database protocol

    /**
     Get the value for a specific property.
     - Parameter path: The unique identifier of the property
     - Returns: The value of the property, if one exists
     */
    public override func get<Value>(model: Int, instance: Int, property: Int) -> Value? where Value : DatabaseValue {
        let path = Path(model: model, instance: instance, property: property)
        do {
            return try readThrowing(path)
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
    public override func set<Value>(_ value: Value, model: Int, instance: Int, property: Int) where Value : DatabaseValue {
        let path = Path(model: model, instance: instance, property: property)
        do {
            return try storeThrowing(value, for: path)
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
    public override func all<T>(model: Int, where predicate: (_ instanceId: Int, _ status: InstanceStatus) -> T?) -> [T] {
        do {
            return try instanceTable.all(model: model, where: predicate)
        } catch {
            print("Failed to select \(String(describing: T.self)): \(error)")
            return []
        }
    }
}
