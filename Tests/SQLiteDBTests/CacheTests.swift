import Foundation
import BinaryCodable
import Testing
import StateModel
@testable import SQLiteDB

typealias CacheTestDatabase<Cache: SQLiteCache> = CachedSQLiteDatabase<Int, Int, Int, Cache> where Cache.Key == Path<Int, Int, Int>

extension CachedSQLiteDatabase {

    convenience init(cache: Cache) throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbFolder = tempDir.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dbFolder, withIntermediateDirectories: true)
        let file = dbFolder.appendingPathComponent("db.sqlite3")
        try self.init(file: file, encoder: BinaryEncoder(), decoder: BinaryDecoder(), cache: cache)
    }
}

@Suite("AnyCache")
struct CacheTests {

    @Test("Storage")
    func testStorageInCache() throws {
        let cache = AnyCache<Path<Int, Int, Int>>(maxCount: 1000)
        let database = try CacheTestDatabase(cache: cache)

        let path = Path(model: 1, instance: 1, property: 1)

        let value = "abc"
        database.set(value, for: path)
        #expect(cache.count == 1)

        let retrieved: String? = database.get(path)
        #expect(retrieved == value)

        struct Complex: Codable, Equatable {
            let a: Int
            let b: String
        }

        let value2 = Complex(a: 123, b: "abc")
        let path2 = Path(model: 1, instance: 1, property: 2)
        database.set(value2, for: path2)
        #expect(cache.count == 2)

        // change value in database, to see if it's returned from the cache
        let value3 = Complex(a: 456, b: "def")
        database.db.set(value3, for: path2)

        let retrieved2: Complex? = database.get(path2)
        #expect(retrieved2 == value2)

        // Clear the cache and get value from the database
        cache.removeAll()

        let retrieved3: Complex? = database.get(path2)
        #expect(retrieved3 == value3)
    }

    @Test("Eviction")
    func testCacheEviction() throws {
        let cache = AnyCache<Path<Int, Int, Int>>(maxCount: 1000, evictionFraction: 0.5)
        let database = try CachedSQLiteDatabase(cache: cache)

        #expect(cache.count == 0)
        for value in 1...1000 {
            database.set(value, for: Path(model: 1, instance: 1, property: value))
        }

        #expect(cache.count == 1000)

        database.set(1, for: Path(model: 1, instance: 1, property: 1001))

        #expect(cache.count == 501)
    }
}
