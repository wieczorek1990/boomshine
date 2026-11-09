import CoreGraphics

extension SystemRandomNumberGenerator {
  mutating func nextUnsignedInteger(_ value: Int) -> Int {
    return Int(next(upperBound: UInt(value)))
  }
}

extension CGFloat {
  func toRoundedInt() -> Int {
    return Int(self.rounded())
  }
}
