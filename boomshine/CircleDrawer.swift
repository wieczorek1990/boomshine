import SwiftUI

class CircleDrawer {
  private static let zeroAngle = Angle(degrees: 0)
  private static let fullCircleAngle = Angle(degrees: 360)

  var context: GraphicsContext

  func draw(_ centerX: Int, _ centerY: Int, _ radius: Float, _ color: Color) {
    var path = Path()
    let center = CGPoint(x: centerX, y: centerY)
    let r = CGFloat(radius)
    let lineWidth = CGFloat(DEFAULT_LINE_WIDTH)

    path.addArc(center: center, radius: r, startAngle: Self.zeroAngle, endAngle: Self.fullCircleAngle, clockwise: true)
    context.fill(path, with: .color(color))
    context.stroke(path, with: .color(color), lineWidth: lineWidth)
  }

  init(_ context: GraphicsContext) {
    self.context = context
  }
}
