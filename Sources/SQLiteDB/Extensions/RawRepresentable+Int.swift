
extension RawRepresentable where RawValue: IntegerConvertible {

    init?(intValue: Int64) {
        guard let raw = RawValue.init(intValue: intValue) else {
            return nil
        }
        self.init(rawValue: raw)
    }

    var intValue: Int64 {
        rawValue.intValue
    }
}
