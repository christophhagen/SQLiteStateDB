import Foundation
import StateModel
import SQLiteDB

typealias TestDatabase = SQLiteDatabase
typealias TestBaseModel = ModelProtocol

extension SQLiteDatabase {

    convenience init(encoder: any GenericEncoder, decoder: any GenericDecoder) throws {
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


typealias TestHistoryDatabase = SQLiteHistoryDatabase

extension SQLiteHistoryDatabase {

    convenience init(encoder: any GenericEncoder, decoder: any GenericDecoder) throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbFolder = tempDir.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dbFolder, withIntermediateDirectories: true)
        let file = dbFolder.appendingPathComponent("db.sqlite3")
        try self.init(file: file, encoder: encoder, decoder: decoder)
    }
}

extension TestHistoryDatabase {

    convenience init() throws {
        try self.init(encoder: JSONEncoder(), decoder: JSONDecoder())
    }
}
