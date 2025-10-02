import Foundation
import StateModel
import SQLite

public final class CachedSQLiteDatabase<Cache: SQLiteCache>: Database where Cache.Key == Path {

    let db: SQLiteDatabase

    let cache: Cache

    /**
     Create or open a SQLite database with caching.

     The required tables and indices will be created if they don't exist in the database.

     - Parameter file: The path to the database file.
     - Parameter encoder: The encoder to use for `Codable` types.
     - Parameter decoder: The decoder to use for `Codable` types.
     - Throws: `SQLite.Result` errors if the database could not be opened, or tables and indices could not be created.
     */
    public init(file: URL, encoder: any GenericEncoder, decoder: any GenericDecoder, cache: Cache) throws {
        self.db = try .init(file: file, encoder: encoder, decoder: decoder)
        self.cache = cache
    }

    func storeThrowing<Value>(_ value: Value, for path: Path) throws where Value : Decodable, Value : Encodable {
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

    private func readThrowing<Value>(_ path: Path) throws -> Value? where Value: Codable {
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

    func storeStatus(_ value: InstanceStatus, for path: Path) throws {
        cache.setInt(value.intValue, for: path)
        try db.storeStatus(value, for: path)
    }

    func storeOptionalCodable(_ value: any CodableOptional, for path: Path) throws {
        cache.setAny(value, for: path)
        try db.storeOptionalCodable(value, for: path)
    }

    func storeCodable<Value: Codable>(_ value: Value, for path: Path) throws {
        cache.setAny(value, for: path)
        try db.storeCodable(value, for: path)
    }

    func storeInt(_ value: Int64?, for path: Path) throws {
        cache.setInt(value, for: path)
        try db.storeInt(value, for: path)
    }

    func storeDouble(_ value: Double?, for path: Path) throws {
        cache.setDouble(value, for: path)
        try db.storeDouble(value, for: path)
    }

    func storeString(_ value: String?, for path: Path) throws {
        cache.setString(value, for: path)
        try db.storeString(value, for: path)
    }

    func storeData(_ value: Data?, for path: Path) throws {
        cache.setData(value, for: path)
        try db.storeData(value, for: path)
    }

    // MARK: Typed getters

    @inline(__always)
    func readStatus(_ path: Path) throws -> InstanceStatus? {
        if let cachedValue = cache.getInt(path), let cachedValue {
            return .init(rawValue: UInt8(cachedValue))
        }
        let value = try db.readStatus(path)
        cache.setInt(value?.intValue, for: path)
        return value
    }

    @inline(__always)
    func readInt(_ path: Path) throws -> Int64? {
        if let cachedValue = cache.getInt(path) {
            return cachedValue
        }
        let value = try db.readInt(path)
        cache.setInt(value, for: path)
        return value
    }

    @inline(__always)
    func readOptionalInt(_ path: Path) throws -> Int64?? {
        if let cachedValue = cache.getInt(path) {
            return cachedValue
        }
        guard let value = try db.readOptionalInt(path) else {
            cache.setInt(nil, for: path)
            return nil
        }
        cache.setInt(value, for: path)
        return value
    }

    @inline(__always)
    func readDouble(_ path: Path) throws -> Double? {
        if let cachedValue = cache.getDouble(path) {
            return cachedValue
        }
        let value = try db.readDouble(path)
        cache.setDouble(value, for: path)
        return value
    }

    @inline(__always)
    func readOptionalDouble(_ path: Path) throws -> Double?? {
        if let cachedValue = cache.getDouble(path) {
            return cachedValue
        }
        guard let value = try db.readOptionalDouble(path) else {
            cache.setDouble(nil, for: path)
            return nil
        }
        cache.setDouble(value, for: path)
        return value
    }

    @inline(__always)
    func readString(_ path: Path) throws -> String? {
        if let cachedValue = cache.getString(path) {
            return cachedValue
        }
        let value = try db.readString(path)
        cache.setString(value, for: path)
        return value
    }

    @inline(__always)
    func readOptionalString(_ path: Path) throws -> String?? {
        if let cachedValue = cache.getString(path) {
            return cachedValue
        }
        guard let value = try db.readOptionalString(path) else {
            cache.setString(nil, for: path)
            return nil
        }
        cache.setString(value, for: path)
        return value
    }

    @inline(__always)
    func readData(_ path: Path) throws -> Data? {
        if let cachedValue = cache.getData(path) {
            return cachedValue
        }
        let value = try db.readData(path)
        cache.setData(value, for: path)
        return value
    }

    @inline(__always)
    func readOptionalData(_ path: Path) throws -> Data?? {
        if let cachedValue = cache.getData(path) {
            return cachedValue
        }
        guard let value = try db.readOptionalData(path) else {
            cache.setData(nil, for: path)
            return nil
        }
        cache.setData(value, for: path)
        return value
    }

    @inline(__always)
    func read<T>(codableOptional: T.Type, _ path: Path) throws -> T? where T: CodableOptional {
        if let anyValue = cache.getAny(path), let value = anyValue as? T {
            return value
        }
        guard let value = try db.read(codableOptional: T.self, path) else {
            cache.setAny(T.nilValue, for: path)
            return nil
        }
        cache.setAny(value as Any, for: path)
        return value
    }

    @inline(__always)
    func read<Value>(codable: Value.Type, _ path: Path) throws -> Value? where Value: Codable {
        if let anyValue: Any = cache.getAny(path), let value = anyValue as? Value {
            return value
        }
        let value = try db.read(codable: codable, path)
        cache.setAny(value as Any, for: path)
        return value
    }

    // MARK: Database protocol

    public func get<Value>(_ path: Path) -> Value? where Value : DatabaseValue {
        do {
            return try readThrowing(path)
        } catch {
            print("Failed to get \(path): \(error)")
            return nil
        }
    }

    public func set<Value>(_ value: Value, for path: Path) where Value : DatabaseValue {
        do {
            return try storeThrowing(value, for: path)
        } catch {
            print("Failed to set \(path) to \(value): \(error)")
        }
    }

    public func all<T>(model: ModelKey, where predicate: (_ instanceId: InstanceKey, _ status: InstanceStatus) -> T?) -> [T] {
        db.all(model: model, where: predicate)
    }

}
