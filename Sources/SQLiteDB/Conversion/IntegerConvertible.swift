
protocol IntegerConvertible {

    var intValue: Int64 { get }

    init?(intValue: Int64)
}

extension Int64 {

    func asInt<T>(of: T.Type = T.self) -> T? where T: IntegerConvertible {
        .init(intValue: self)
    }
}
