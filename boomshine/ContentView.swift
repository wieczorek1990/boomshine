import SwiftUI
import CoreGraphics

// --- App ---

@main
struct BoomShineApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// --- Extensions ---

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

// --- Constants ---

let USER_COLOR = Color.blue

let COLORS: [Color] = [
    Color.red, Color.green, Color.yellow, Color.brown,
    Color.cyan, Color.gray, Color.indigo, Color.mint,
    Color.orange, Color.pink, Color.teal,
]

let CIRCLE_COUNT: Int = 32
let DEFAULT_LINE_WIDTH: Float = 1.0
let DEFAULT_SIZE_MULTIPLIER: Float = 1.025
let EPSILON: Float = 0.5
let MINIMUM_CIRCLE_RADIUS: Float = 2.0
let MAXIMUM_CIRCLE_RADIUS: Float = MINIMUM_CIRCLE_RADIUS * 32.0
let STEP_SIZE: Int = 2

// --- Classes ---

class Circle {
    var x: Int
    var y: Int
    var radius: Float
    let color: Color

    init(x: Int, y: Int, radius: Float, color: Color) {
        self.x = x
        self.y = y
        self.radius = radius
        self.color = color
    }

    func touches(_ other: Circle) -> Bool {
        let dx = Float(self.x) - Float(other.x)
        let dy = Float(self.y) - Float(other.y)
        let distanceSquared = dx * dx + dy * dy

        let sumR = self.radius + other.radius
        let diffR = abs(self.radius - other.radius)

        return distanceSquared <= diffR * diffR || distanceSquared < sumR * sumR
    }
}

class BoomingCircle {
    var circle: Circle
    var fall: Bool = false
    var fallCount: Int = 0
    var untoucheable: Bool = false

    init(circle: Circle) {
        self.circle = circle
    }

    func boom() {
        if !fall {
            if fallCount >= 1 {
                if circle.radius > EPSILON {
                    circle.radius /= DEFAULT_SIZE_MULTIPLIER
                } else {
                    circle.radius = 0.0
                    untoucheable = true
                }
                return
            }

            if circle.radius > MAXIMUM_CIRCLE_RADIUS {
                fall = true
                fallCount += 1
            }
            circle.radius *= DEFAULT_SIZE_MULTIPLIER
        } else {
            if circle.radius < MINIMUM_CIRCLE_RADIUS {
                fall = false
            }
            circle.radius /= DEFAULT_SIZE_MULTIPLIER
        }
    }
}

class MovingCircle {
    var circle: Circle
    var direction: (Int, Int)
    var running: Bool

    init(_ circle: Circle, _ direction: (Int, Int)) {
        self.circle = circle
        self.direction = direction
        self.running = true
    }

    func stop() {
        running = false
    }

    func maximumX(_ maxX: Int) {
        if circle.x > maxX {
            direction.0 = 1
        } else if circle.x < 0 {
            direction.0 = 0
        }
    }

    func maximumY(_ maxY: Int) {
        if circle.y > maxY {
            direction.1 = 1
        } else if circle.y < 0 {
            direction.1 = 0
        }
    }

    func stepX() {
        if direction.0 == 0 {
            circle.x += STEP_SIZE
        } else if direction.0 == 1 {
            circle.x -= STEP_SIZE
        }
    }

    func stepY() {
        if direction.1 == 0 {
            circle.y += STEP_SIZE
        } else if direction.1 == 1 {
            circle.y -= STEP_SIZE
        }
    }

    func move(_ maxX: Int, _ maxY: Int) {
        if !running { return }
        maximumX(maxX)
        maximumY(maxY)
        stepX()
        stepY()
    }

    func touches(_ boomingCircles: [BoomingCircle]) -> Bool {
        for bc in boomingCircles {
            if bc.untoucheable { continue }
            if circle.touches(bc.circle) { return true }
        }
        return false
    }
}

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

// --- ContentView ---

struct ContentView: View {
    @State private var started: Bool = false
    @State private var score: Int = 0
    @State private var screenWidth: Int = 0
    @State private var screenHeight: Int = 0

    @State private var circles: [Circle] = []
    @State private var movingCircles: [MovingCircle] = []
    @State private var boomingCircles: [BoomingCircle] = []

    func appear(_ proxy: GeometryProxy) {
        let width = Int(proxy.size.width)
        let height = Int(proxy.size.height)

        screenWidth = width
        screenHeight = height

        var rng = SystemRandomNumberGenerator()

        for _ in 0..<CIRCLE_COUNT {
            let x = rng.nextUnsignedInteger(width)
            let y = rng.nextUnsignedInteger(height)
            let colorIndex = rng.nextUnsignedInteger(COLORS.count)
            let color = COLORS[colorIndex]

            circles.append(Circle(x: x, y: y, radius: MINIMUM_CIRCLE_RADIUS, color: color))
        }

        takeRandomDestinations()
    }

    func move() {
        guard started else { return }
        for mc in movingCircles {
            mc.move(screenWidth, screenHeight)
        }
    }

    func draw(context: GraphicsContext, size: CGSize) {
        let drawer = CircleDrawer(context, size)

        for mc in movingCircles {
            drawer.draw(mc.circle.x, mc.circle.y, mc.circle.radius, mc.circle.color)
        }
        for bc in boomingCircles {
            drawer.draw(bc.circle.x, bc.circle.y, bc.circle.radius, bc.circle.color)
        }
    }

    func takeRandomDestinations() {
        for circle in circles {
            let dx = Int.random(in: 0...1)
            let dy = Int.random(in: 0...1)
            movingCircles.append(MovingCircle(circle, (dx, dy)))
        }
    }

    func makeInitialBoom(_ point: CGPoint) {
        let x = point.x.toRoundedInt()
        let y = point.y.toRoundedInt()

        let boomCircle = Circle(x: x, y: y, radius: MINIMUM_CIRCLE_RADIUS, color: USER_COLOR)
        boomingCircles.append(BoomingCircle(circle: boomCircle))
    }

    func touch() {
        guard started else { return }
        var indicesToRemove: [Int] = []
        var newBoomingCircles: [BoomingCircle] = []
        var scoreDelta = 0

        for (index, mc) in movingCircles.enumerated().reversed() {
            if mc.touches(boomingCircles) {
                indicesToRemove.append(index)
                mc.stop()
                scoreDelta += 1
                newBoomingCircles.append(BoomingCircle(circle: mc.circle))
            }
        }

        if !indicesToRemove.isEmpty || !newBoomingCircles.isEmpty || scoreDelta != 0 {
            for index in indicesToRemove.sorted() {
                movingCircles.remove(at: index)
            }
            boomingCircles.append(contentsOf: newBoomingCircles)
            score += scoreDelta
        }
    }

    func boom() {
        for bc in boomingCircles {
            bc.boom()
        }
    }

    @ViewBuilder
    func status() -> some View {
        if !started {
            Text("Press anywhere to start.")
        } else {
            if score < CIRCLE_COUNT {
                Text("Score: \(score)")
            } else {
                Text("Done! 🎉")
            }
        }
    }

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.periodic(from: .now, by: 1.0 / 60.0)) { context in
                Canvas { ctx, size in
                    draw(context: ctx, size: size)
                }
                .onChange(of: context.date) { _, _ in
                    move()
                    touch()
                    boom()
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            if !started {
                                started = true
                            } else {
                                makeInitialBoom(value.location)
                            }
                        }
                )
                .overlay(alignment: .bottom) {
                    status()
                        .padding()
                }
            }
            .onAppear {
                appear(proxy)
            }
        }
    }
}

#Preview {
    ContentView()
}
