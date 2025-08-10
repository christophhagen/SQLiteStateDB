import Foundation
import SQLite
import StateModel

/**
 A SQLite Database suitable to act as a database for StateModel.

 The database separates the values into separate databases for integers, doubles, strings, and data.
 An additional table tracks the model instance status properties to provide the model selection functionality.
 All values are stored with a timestamp to provide a history.
 */
public final class SQLiteDatabase<Encoder: GenericEncoder, Decoder: GenericDecoder> {

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
    }


    // MARK: Throwing functions

    /**
     Internal function to set properties.
     */
    private func setThrowing<Value>(_ value: Value, for path: KeyPath) throws where Value: Codable {
        switch Value.self {
        case is InstanceStatus.Type:
            // Catch instance status updates first,
            // which are additionally stored in a separate table for selecting models
            let status = value as! InstanceStatus
            // If the instance status really targets an instance, also save the info to an additional table
            // This is used to improve the select queries, where only the most recent values are of interest
            if path.property == PropertyKey.instanceId {
                try instanceTable.update(value: status, model: path.model, instance: path.instance)
            }
            // We still need to save the full sample, to get the history
            return try integerTable.insert(value: status.rawValue.intValue, for: path)
        case is IntegerConvertible.Type:
            // Detect integers next, since those are assumed the most likely
            return try integerTable.insert(value: (value as! IntegerConvertible).intValue, for: path)
        case is OptionalIntegerConvertible.Type:
            return try integerTable.insert(value: (value as! OptionalIntegerConvertible).intValue, for: path)
        case is DoubleConvertible.Type:
            return try doubleTable.insert(value: (value as! DoubleConvertible).doubleValue, for: path)
        case is OptionalDoubleConvertible.Type:
            return try doubleTable.insert(value: (value as! OptionalDoubleConvertible).doubleValue, for: path)
        case is String.Type:
            return try stringTable.insert(value: (value as! String), for: path)
        case is String?.Type:
            // We check against the type instead of using `as?`,
            // since this would match other nil values as well
            return try stringTable.insert(value: (value as! String?), for: path)
        case is Data.Type:
            return try binaryTable.insert(value: (value as! Data), for: path)
        case is Data?.Type:
            // We check against the type instead of using `as?`,
            // since this would match other nil values as well
            return try binaryTable.insert(value: (value as! Data?), for: path)
        case is CodableOptional.Type:
            // For Codable types, unpack one level of Optionals which is
            // handled by SQLite NULL values
            let optionalValue = value as! CodableOptional
            if optionalValue.isNil {
                return try binaryTable.insert(value: nil, for: path)
            } else {
                let data = try optionalValue.encodeWrapped(with: encoder)
                return try binaryTable.insert(value: data, for: path)
            }
        default:
            // Encode non-optionals
            let data = try encoder.encode(value)
            return try binaryTable.insert(value: data, for: path)

        }
    }

    private func getThrowing<Value>(_ path: KeyPath) throws -> Value? where Value: Codable {
        switch Value.self {
        case is InstanceStatus.Type:
            // First match instance information
            // The info is still stored in the integer table,
            // so we get the info from there
            return try integerTable.value(for: path)?.asInt(of: UInt8.self).map { InstanceStatus(rawValue: $0) as! Value }
        case let IntValue as IntegerConvertible.Type:
            // Get all integer values
            return try integerTable.value(for: path)?.asInt(of: IntValue.self).map { $0 as! Value }
        case let IntValue as OptionalIntegerConvertible.Type:
            return try integerTable.optionalValue(for: path).map { IntValue.init(intValue: $0) as! Value }
        case let DoubleValue as DoubleConvertible.Type:
            return try doubleTable.value(for: path)?.asDouble(of: DoubleValue.self).map { $0 as! Value }
        case let DoubleValue as OptionalDoubleConvertible.Type:
            return try doubleTable.optionalValue(for: path).map { DoubleValue.init(doubleValue: $0) as! Value }
        case is String.Type:
            return try stringTable.value(for: path).map { $0 as! Value }
        case is String?.Type:
            return try stringTable.optionalValue(for: path).map { $0 as! Value }
        case is Data.Type:
            return try binaryTable.value(for: path).map { $0 as! Value }
        case is Data?.Type:
            return try binaryTable.optionalValue(for: path).map { $0 as! Value }
        case let OptionalValue as CodableOptional.Type:
            guard let data = try binaryTable.optionalValue(for: path) else {
                return nil
            }
            if let data {
                return (try OptionalValue.decodeWrapped(from: data, with: decoder) as! Value)
            } else {
                return (OptionalValue.nilValue as! Value)
            }
        default:
            guard let data = try binaryTable.value(for: path) else {
                return nil
            }
            return try decoder.decode(Value.self, from: data)
        }
    }
}

// MARK: Database protocol

extension SQLiteDatabase: Database {

    /**
     Get the value for a specific property.
     - Parameter path: The unique identifier of the property
     - Returns: The value of the property, if one exists
     */
    public func get<Value>(_ path: KeyPath) -> Value? where Value: Codable {
        do {
            return try getThrowing(path)
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
    public func set<Value>(_ value: Value, for path: KeyPath) where Value: Codable {
        do {
            return try setThrowing(value, for: path)
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
    public func select<T>(
        modelId: ModelKey,
        propertyId: PropertyKey,
        where predicate: (_ instanceId: InstanceKey, _ status: InstanceStatus) -> T?
    ) -> [T] {
        do {
            return try instanceTable.all(model: modelId, where: predicate)
        } catch {
            print("Failed to select \(String(describing: T.self)): \(error)")
            return []
        }
    }
}
