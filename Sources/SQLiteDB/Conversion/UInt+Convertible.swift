
extension UInt8: IntegerConvertible {

    var intValue: Int64 {
        Int64(self)
    }

    init?(intValue: Int64) {
        self.init(exactly: intValue)
    }
}

extension UInt16: IntegerConvertible {

    var intValue: Int64 {
        Int64(self)
    }

    init?(intValue: Int64) {
        self.init(exactly: intValue)
    }
}

extension UInt32: IntegerConvertible {

    var intValue: Int64 {
        Int64(self)
    }

    init?(intValue: Int64) {
        self.init(exactly: intValue)
    }
}

extension UInt64: IntegerConvertible {

    var intValue: Int64 {
        Int64(bitPattern: self)
    }

    init(intValue: Int64) {
        self.init(bitPattern: intValue)
    }
}

extension UInt: IntegerConvertible {

    var intValue: Int64 {
        Int64(bitPattern: UInt64(self))
    }

    init(intValue: Int64) {
        self = UInt(UInt64(bitPattern: intValue))
    }
}
