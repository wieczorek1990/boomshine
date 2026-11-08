import SwiftUI

struct LogoView: View {
    let circleSize: CGFloat = 24

    // Define circle positions for a star/burst pattern
    // Center circle + rings of circles forming a star shape
    private var logoCircles: [(position: (CGFloat, CGFloat), color: Color, scale: CGFloat)] {
        var circles: [(position: (CGFloat, CGFloat), color: Color, scale: CGFloat)] = []

        // Center circle - largest
        circles.append(((0, 0), COLORS[0], 1.8))

        // Inner ring - 6 circles
        let innerRadius: CGFloat = 50
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3
            let x = cos(angle) * innerRadius
            let y = sin(angle) * innerRadius
            circles.append(((x, y), COLORS[i % COLORS.count], 1.2))
        }

        // Outer ring - 8 circles forming a burst
        let outerRadius: CGFloat = 90
        for i in 0..<8 {
            let angle = CGFloat(i) * .pi / 4 - .pi / 8
            let x = cos(angle) * outerRadius
            let y = sin(angle) * outerRadius
            circles.append(((x, y), COLORS[(i + 2) % COLORS.count], 1.0))
        }

        // Tips of the burst - 4 circles at the points
        let tipRadius: CGFloat = 120
        for i in 0..<4 {
            let angle = CGFloat(i) * .pi / 2 - .pi / 4
            let x = cos(angle) * tipRadius
            let y = sin(angle) * tipRadius
            circles.append(((x, y), COLORS[(i + 5) % COLORS.count], 0.8))
        }

        return circles
    }

    var body: some View {
        ZStack {
            ForEach(Array(logoCircles.enumerated()), id: \.offset) { index, circle in
                CircleShape()
                    .fill(circle.color)
                    .frame(width: circleSize * circle.scale, height: circleSize * circle.scale)
                    .offset(x: circle.position.0, y: circle.position.1)
                    .shadow(color: circle.color.opacity(0.5), radius: 5)
            }
        }
        .frame(width: 280, height: 280)
    }
}

struct CircleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = rect.width / 2
        path.addArc(center: center, radius: radius, startAngle: .zero, endAngle: Angle(degrees: 360), clockwise: true)
        return path
    }
}

#Preview {
    LogoView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}
