import Foundation

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
#endif

final class MemoryWarningObserver {
    private var handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        #endif
    }

    deinit {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        NotificationCenter.default.removeObserver(self)
        #endif
    }

    @objc private func didReceiveMemoryWarning() {
        handler()
    }
}

final class MemoryCache<Key: Hashable> {

    private class Node {
        let key: Key
        var value: Any
        var expiryTimestamp: TimeInterval
        weak var prev: Node?
        var next: Node?

        init(key: Key, value: Any, expiryTimestamp: TimeInterval) {
            self.key = key
            self.value = value
            self.expiryTimestamp = expiryTimestamp
        }
    }

    private let expiryInterval: TimeInterval
    private let countLimit: Int
    private var dict: [Key: Node] = [:]
    private var head: Node?
    private var tail: Node?
    private let lock = NSLock()
    private var memoryObserver: MemoryWarningObserver?

    init(expiryInterval: TimeInterval,
         countLimit: Int,
         clearOnLowMemory: Bool = true) {
        self.expiryInterval = expiryInterval
        self.countLimit = countLimit

        if clearOnLowMemory {
            memoryObserver = MemoryWarningObserver { [weak self] in
                self?.removeAll()
            }
        }
    }

    func set(_ value: Any, forKey key: Key) {
        lock.lock()
        let now = currentTimestamp()

        if let node = dict[key] {
            node.value = value
            node.expiryTimestamp = now + expiryInterval
            moveToHead(node)
        } else {
            let node = Node(key: key, value: value, expiryTimestamp: now + expiryInterval)
            dict[key] = node
            insertAtHead(node)
        }

        // Evict expired entries first (from tail)
        removeExpiredFromTail()

        // Then enforce count limit
        if dict.count > countLimit {
            removeTail()
        }

        lock.unlock()
    }

    func get<T>(forKey key: Key) -> T? {
        lock.lock()

        guard let node = dict[key] else {
            lock.unlock()
            return nil
        }

        // Refresh expiry and move to head
        node.expiryTimestamp = currentTimestamp() + expiryInterval
        moveToHead(node)
        
        lock.unlock()

        return node.value as? T
    }

    func removeAll() {
        lock.lock()
        dict.removeAll()
        head = nil
        tail = nil
        lock.unlock()
    }

    // MARK: - Private Helpers

    private func removeExpiredFromTail() {
        let now = currentTimestamp()
        while let t = tail, t.expiryTimestamp <= now {
            dict.removeValue(forKey: t.key)
            removeNode(t)
        }
    }

    private func insertAtHead(_ node: Node) {
        node.next = head
        node.prev = nil
        head?.prev = node
        head = node
        if tail == nil {
            tail = node
        }
    }

    private func moveToHead(_ node: Node) {
        guard node !== head else { return }
        removeNode(node)
        insertAtHead(node)
    }

    private func removeTail() {
        if let t = tail {
            dict.removeValue(forKey: t.key)
            removeNode(t)
        }
    }

    private func removeNode(_ node: Node) {
        let prev = node.prev
        let next = node.next

        if let p = prev {
            p.next = next
        } else {
            head = next
        }

        if let n = next {
            n.prev = prev
        } else {
            tail = prev
        }

        node.prev = nil
        node.next = nil
    }

    private func currentTimestamp() -> TimeInterval {
        Date().timeIntervalSinceReferenceDate
    }
}
