
protocol DoubleConvertible {

    var doubleValue: Double { get }

    init?(doubleValue: Double)
}

extension Double {

    func asDouble<T>(of: T.Type = T.self) -> T? where T: DoubleConvertible {
        .init(doubleValue: self)
    }
}
