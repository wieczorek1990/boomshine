extension SystemRandomNumberGenerator {
    mutating func nextUnsignedInteger(_ value: Int) -> Int {
        return Int(next(upperBound: UInt(value)))
    }
}
