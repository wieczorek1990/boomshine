import SwiftUI

class CircleDrawer {
  var context: GraphicsContext

  func draw(_ centerX: Int, _ centerY: Int, _ radius: Float, _ color: Color) {
    var path = Path()
    let center = CGPoint(x: centerX, y: centerY)
    let r = CGFloat(radius)
    let lineWidth = CGFloat(DEFAULT_LINE_WIDTH)
    let zero = Angle(degrees: 0)
    let fullCircle = Angle(degrees: 360)

    path.addArc(center: center, radius: r, startAngle: zero, endAngle: fullCircle, clockwise: true)
    context.fill(path, with: .color(color))
    context.stroke(path, with: .color(color), lineWidth: lineWidth)
  }

  init(_ context: GraphicsContext) {
    self.context = context
  }
}
