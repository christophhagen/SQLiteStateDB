
protocol DoubleConvertible {

    var doubleValue: Double { get }

    init?(doubleValue: Double)
}

extension Double {

    func converted<T>(to: T.Type = T.self) -> T? where T: DoubleConvertible {
        .init(doubleValue: self)
    }
}
