
extension Optional: OptionalIntegerConvertible where Wrapped: IntegerConvertible {

    var intValue: Int64? {
        self?.intValue
    }

    init(intValue: Int64?) {
        guard let intValue else {
            self = .none
            return
        }
        guard let wrapped = Wrapped(intValue: intValue) else {
            self = .none
            return
        }
        self = .some(wrapped)
    }
}
