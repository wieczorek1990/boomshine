import CoreGraphics

extension CGFloat {
    func toRoundedInt() -> Int {
        return Int(self.rounded())
    }
}
