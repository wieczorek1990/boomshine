import SwiftUI

class CircleDrawer {
    let zero: Angle = Angle(degrees: 0)
    let fullCircle: Angle = Angle(degrees: 360)
    var context: GraphicsContext
    var size: CGSize

    func draw(_ centerX: Int, _ centerY: Int, _ radius: Float, _ color: Color) {
        var path = Path()
        let center = CGPoint(x: centerX, y: centerY)
        let r = CGFloat(radius)
        let lineWidth = CGFloat(DEFAULT_LINE_WIDTH)

        path.addArc(center: center, radius: r, startAngle: zero, endAngle: fullCircle, clockwise: true)
        context.fill(path, with: .color(color))
        context.stroke(path, with: .color(color), lineWidth: lineWidth)
    }

    init(_ context: GraphicsContext, _ size: CGSize) {
        self.context = context
        self.size = size
    }
}
