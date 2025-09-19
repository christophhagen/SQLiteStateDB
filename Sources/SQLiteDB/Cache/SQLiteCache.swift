import Foundation

/**
 A cache that can be used with a SQLite database.
 */
public protocol SQLiteCache {

    associatedtype Key: Hashable

    func getInt(_ key: Key) -> Int64??

    func getDouble(_ key: Key) -> Double??

    func getString(_ key: Key) -> String??

    func getData(_ key: Key) -> Data??

    func getAny(_ key: Key) -> Any?

    func setInt(_ value: Int64?, for key: Key)

    func setDouble(_ value: Double?, for key: Key)

    func setString(_ value: String?, for key: Key)

    func setData(_ value: Data?, for key: Key)

    func setAny(_ value: Any, for key: Key)
}
