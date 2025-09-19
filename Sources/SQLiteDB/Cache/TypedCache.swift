import Foundation

/**
 A cache for a single type with LRU eviction when the capacity is reached.

 A predefined fraction of all contained elements will be removed, based on their last access.
 */
final class TypedCache<Key: Hashable, Value> {

    private struct Entry {
        var value: Value
        var lastAccess: TimeInterval
    }

    private var storage: [Key: Entry] = [:]

    /// The total maximum of items
    private let maxCount: Int

    /// The maximum number of items after cleanup
    private let desiredCountAfterEviction: Int

    /// The number of items currently in the cache
    var count: Int { storage.count }

    init(maxCount: Int, evictionFraction: Double = 0.2) {
        precondition(maxCount > 0, "maxCount must be positive")
        precondition(evictionFraction > 0 && evictionFraction <= 1, "evictionFraction must be in (0,1]")
        self.maxCount = maxCount
        self.desiredCountAfterEviction = maxCount - Int(Double(maxCount) * evictionFraction)

    }

    func set(_ value: Value, for key: Key) {
        if storage.count >= maxCount {
            evictLeastRecentlyUsed()
        }

        let now = Date().timeIntervalSinceReferenceDate
        storage[key] = Entry(value: value, lastAccess: now)
    }

    func get(_ key: Key) -> Value? {
        guard var entry = storage[key] else { return nil }
        entry.lastAccess = Date().timeIntervalSinceReferenceDate
        storage[key] = entry
        return entry.value
    }

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

    func removeAll() {
        storage.removeAll()
    }
}
