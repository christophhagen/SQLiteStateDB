import Foundation

/**
 A protocol to cover optional types that are encodable.

 This protocol is used to strip one level of optionality from values encoded in the database,
 since SQLite can store `NULL` values.
 */
protocol CodableOptional: Codable {

    var isNil: Bool { get }

    static var nilValue: Self { get }

    static func decodeWrapped(from data: Data, with decoder: GenericDecoder) throws -> Self

    func encodeWrapped(with encoder: GenericEncoder) throws -> Data
}

extension Optional: CodableOptional where Wrapped: Codable {

    var isNil: Bool {
        self == nil
    }

    static var nilValue: Optional<Wrapped> {
        .none
    }

    static func decodeWrapped(from data: Data, with decoder: GenericDecoder) throws -> Self {
        let wrapped = try decoder.decode(Wrapped.self, from: data)
        return .some(wrapped)
    }

    func encodeWrapped(with encoder: GenericEncoder) throws -> Data {
        switch self {
        case .none:
            throw EncodingError.invalidValue("", .init(codingPath: [], debugDescription: "Tried to encode nil of an encodable optional"))
        case .some(let wrapped):
            return try encoder.encode(wrapped)
        }
    }
}
