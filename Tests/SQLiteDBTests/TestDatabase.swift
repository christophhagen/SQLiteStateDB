import Foundation
import StateModel
import SQLiteDB

typealias TestDatabase = SQLiteDatabase<JSONEncoder, JSONDecoder>
typealias TestBaseModel = Model<Int, Int, Int>

extension SQLiteDatabase {

    convenience init(encoder: Encoder, decoder: Decoder) throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbFolder = tempDir.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dbFolder, withIntermediateDirectories: true)
        let file = dbFolder.appendingPathComponent("db.sqlite3")
        try self.init(file: file, encoder: encoder, decoder: decoder)
    }
}

extension TestDatabase {

    convenience init() throws {
        try self.init(encoder: JSONEncoder(), decoder: JSONDecoder())
    }
}
