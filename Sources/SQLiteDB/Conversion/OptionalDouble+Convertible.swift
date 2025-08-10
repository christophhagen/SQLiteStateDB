
extension Optional: OptionalDoubleConvertible where Wrapped: DoubleConvertible {

    var doubleValue: Double? {
        self?.doubleValue
    }

    init?(doubleValue: Double?) {
        guard let doubleValue else {
            self = .none
            return
        }
        guard let wrapped = Wrapped(doubleValue: doubleValue) else {
            self = .none
            return
        }
        self = .some(wrapped)
    }
}
