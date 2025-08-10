
extension Int8: IntegerConvertible {

    var intValue: Int64 {
        Int64(self)
    }

    init?(intValue: Int64) {
        self.init(exactly: intValue)
    }
}

extension Int16: IntegerConvertible {

    var intValue: Int64 {
        Int64(self)
    }

    init?(intValue: Int64) {
        self.init(exactly: intValue)
    }
}

extension Int32: IntegerConvertible {

    var intValue: Int64 {
        Int64(self)
    }

    init?(intValue: Int64) {
        self.init(exactly: intValue)
    }
}

extension Int64: IntegerConvertible {

    var intValue: Int64 { self }

    init(intValue: Int64) {
        self = intValue
    }
}

extension Int: IntegerConvertible {

    var intValue: Int64 { Int64(self) }

    init(intValue: Int64) {
        self = Int(intValue)
    }
}
