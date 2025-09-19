import Foundation

/**
 A simple cache that is based on a dictionary of structs with LRU eviction when a maximum count is reached.
 */
public final class BasicCache<Key: Hashable> {

    let intCache: TypedCache<Key, Int64?>

    let doubleCache: TypedCache<Key, Double?>

    let stringCache: TypedCache<Key, String?>

    let dataCache: TypedCache<Key, Data?>

    let anyCache: AnyCache<Key>

    public struct Configuration {
        public let integers: Int
        public let doubles: Int
        public let strings: Int
        public let data: Int
        public let anyValues: Int

        public init(integers: Int = 3000,
                    doubles: Int = 2000,
                    strings: Int = 1000,
                    data: Int = 1000,
                    anyValues: Int = 1000) {
            self.integers = integers
            self.doubles = doubles
            self.strings = strings
            self.data = data
            self.anyValues = anyValues
        }
    }

    public init(configuration: Configuration) {
        self.intCache = .init(maxCount: configuration.integers)
        self.doubleCache = .init(maxCount: configuration.doubles)
        self.stringCache = .init(maxCount: configuration.strings)
        self.dataCache = .init(maxCount: configuration.data)
        self.anyCache = .init(maxCount: configuration.anyValues)
    }

    public init(integers: Int = 3000,
                doubles: Int = 2000,
                strings: Int = 1000,
                dataValues: Int = 1000,
                anyValues: Int = 1000) {
        self.intCache = .init(maxCount: integers)
        self.doubleCache = .init(maxCount: doubles)
        self.stringCache = .init(maxCount: strings)
        self.dataCache = .init(maxCount: dataValues)
        self.anyCache = .init(maxCount: anyValues)
    }
}

extension BasicCache: SQLiteCache {

    public func getInt(_ key: Key) -> Int64?? {
        intCache.get(key)
    }

    public func getDouble(_ key: Key) -> Double?? {
        doubleCache.get(key)
    }

    public func getString(_ key: Key) -> String?? {
        stringCache.get(key)
    }

    public func getData(_ key: Key) -> Data?? {
        dataCache.get(key)
    }

    public func getAny(_ key: Key) -> Any? {
        anyCache.getAny(key)
    }

    public func setInt(_ value: Int64?, for key: Key) {
        intCache.set(value, for: key)
    }

    public func setDouble(_ value: Double?, for key: Key) {
        doubleCache.set(value, for: key)
    }

    public func setString(_ value: String?, for key: Key) {
        stringCache.set(value, for: key)
    }

    public func setData(_ value: Data?, for key: Key) {
        dataCache.set(value, for: key)
    }

    public func setAny(_ value: Any, for key: Key) {
        anyCache.setAny(value, for: key)
    }
}
