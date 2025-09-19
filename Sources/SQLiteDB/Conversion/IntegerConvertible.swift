
protocol IntegerConvertible {

    var intValue: Int64 { get }

    init?(intValue: Int64)
}

extension Int64 {

    func converted<T>(to: T.Type = T.self) -> T? where T: IntegerConvertible {
        .init(intValue: self)
    }

    func converted<T>(to type: T.Type = T.self) -> T? where T: RawRepresentable, T.RawValue: IntegerConvertible {
        guard let raw = T.RawValue.init(intValue: self) else {
            return nil
        }
        return T.init(rawValue: raw)
    }
}
