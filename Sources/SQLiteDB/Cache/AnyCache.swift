import Foundation

/**
 A cache for arbitrary types with LRU eviction when the capacity is reached.

 A predefined fraction of all contained elements will be removed, based on their last access.
 */
public final class AnyCache<Key: Hashable> {

    private struct Entry {
        var value: Any
        var lastAccess: TimeInterval
    }

    private var storage: [Key: Entry] = [:]

    /// The total maximum of items
    private let maxCount: Int

    /// The maximum number of items after cleanup
    private let desiredCountAfterEviction: Int

    /// The number of items currently in the cache
    public var count: Int { storage.count }

    public init(maxCount: Int = 1000, evictionFraction: Double = 0.2) {
        precondition(maxCount > 0, "maxCount must be positive")
        precondition(evictionFraction > 0 && evictionFraction <= 1, "evictionFraction must be in (0,1]")
        self.maxCount = maxCount
        self.desiredCountAfterEviction = maxCount - Int(Double(maxCount) * evictionFraction)

    }

    public func setAny(_ value: Any, for key: Key) {
        if storage.count >= maxCount {
            evictLeastRecentlyUsed()
        }

        let now = Date().timeIntervalSinceReferenceDate
        storage[key] = Entry(value: value, lastAccess: now)
    }

    public func getAny(_ key: Key) -> Any? {
        guard var entry = storage[key] else { return nil }
        entry.lastAccess = Date().timeIntervalSinceReferenceDate
        storage[key] = entry
        return entry.value
    }

    func get<T>(_ key: Key, as type: T.Type) -> T? {
        guard var entry = storage[key] else { return nil }
        entry.lastAccess = Date().timeIntervalSinceReferenceDate
        storage[key] = entry
        return entry.value as? T
    }

    /**
     Remove the cache items that are least recently used,
     leaving only a specific number of items in the cache
     */
    private func evictLeastRecentlyUsed() {
        let removeCount = storage.count - desiredCountAfterEviction
        guard removeCount > 0 else { return }

        // Sort keys by lastAccess ascending (least recently used first)
        let sortedKeys = storage.keys.sorted {
            storage[$0]!.lastAccess < storage[$1]!.lastAccess
        }

        for key in sortedKeys.prefix(removeCount) {
            storage.removeValue(forKey: key)
        }
    }

    public func removeAll() {
        storage.removeAll()
    }
}

extension AnyCache: SQLiteCache {

    public func getInt(_ key: Key) -> Int64?? {
        get(key, as: Int64?.self)
    }
    
    public func getDouble(_ key: Key) -> Double?? {
        get(key, as: Double?.self)
    }
    
    public func getString(_ key: Key) -> String?? {
        get(key, as: String?.self)
    }
    
    public func getData(_ key: Key) -> Data?? {
        get(key, as: Data?.self)
    }
    
    public func setInt(_ value: Int64?, for key: Key) {
        setAny(value as Any, for: key)
    }
    
    public func setDouble(_ value: Double?, for key: Key) {
        setAny(value as Any, for: key)
    }
    
    public func setString(_ value: String?, for key: Key) {
        setAny(value as Any, for: key)
    }
    
    public func setData(_ value: Data?, for key: Key) {
        setAny(value as Any, for: key)
    }
}
