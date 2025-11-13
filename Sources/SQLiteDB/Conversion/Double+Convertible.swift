import CoreFoundation

extension Double: DoubleConvertible {

    var doubleValue: Double { self }

    init(doubleValue: Double) { self = doubleValue }
}

extension Float: DoubleConvertible {

    var doubleValue: Double { Double(self) }

    init(doubleValue: Double) {
        self.init(doubleValue)
    }
}

#if canImport(CoreGraphics)
extension CGFloat: DoubleConvertible {

    var doubleValue: Double { Double(self) }

    init(doubleValue: Double) {
        self.init(doubleValue)
    }
}
#endif

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension Float16: DoubleConvertible {

    var doubleValue: Double { Double(self) }

    init(doubleValue: Double) {
        self.init(doubleValue)
    }
}


