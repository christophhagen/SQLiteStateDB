
extension Bool: IntegerConvertible {

    var intValue: Int64 {
        self ? 1 : 0
    }

    init?(intValue: Int64) {
        self = intValue != 0
    }
}

