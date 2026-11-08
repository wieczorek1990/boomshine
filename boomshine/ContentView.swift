import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var started: Bool = false
    @State private var score: Int = 0
    @State private var screenWidth: Int = 0
    @State private var screenHeight: Int = 0

    @State private var movingCircles: [MovingCircle] = []
    @State private var boomingCircles: [BoomingCircle] = []

    @State private var tickCount: Int = 0
    @State private var timer: Timer?

    private let gameUpdateInterval: TimeInterval = 1.0 / 60.0

    func appear(_ proxy: GeometryProxy) {
        let width = Int(proxy.size.width)
        let height = Int(proxy.size.height)

        screenWidth = width
        screenHeight = height

        var rng = SystemRandomNumberGenerator()
        var circles: [Circle] = []

        for _ in 0..<CIRCLE_COUNT {
            let x = rng.nextUnsignedInteger(width)
            let y = rng.nextUnsignedInteger(height)
            let colorIndex = rng.nextUnsignedInteger(COLORS.count)
            let color = COLORS[colorIndex]

            circles.append(Circle(x: x, y: y, radius: MINIMUM_CIRCLE_RADIUS, color: color))
        }

        takeRandomDestinations(from: circles)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            startGameLoop()
        }
    }

    func move() {
        for mc in movingCircles {
            mc.move(screenWidth, screenHeight)
        }
    }

    func draw(context: GraphicsContext, size: CGSize) {
        let drawer = CircleDrawer(context)

        for mc in movingCircles {
            drawer.draw(mc.circle.x, mc.circle.y, mc.circle.radius, mc.circle.color)
        }
        for bc in boomingCircles {
            drawer.draw(bc.circle.x, bc.circle.y, bc.circle.radius, bc.circle.color)
        }
    }

    func takeRandomDestinations(from circles: [Circle]) {
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

    func checkCollisions() {
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
            for index in indicesToRemove.sorted(by: >) {
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
        boomingCircles.removeAll { $0.isDone }
    }

    func resetGame() {
        timer?.invalidate()
        timer = nil
        started = false
        score = 0
        movingCircles.removeAll()
        boomingCircles.removeAll()
        tickCount += 1
    }

    @ViewBuilder
    func status() -> some View {
        if !started {
            Text("Press anywhere to start.")
        } else {
            if score < CIRCLE_COUNT {
                Text("Score: \(score)")
            } else {
                Text("Done! 🎉 Tap to play again.")
            }
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if colorScheme == .dark {
                    Color.white
                } else {
                    Color.black
                }

                Canvas { ctx, size in
                    draw(context: ctx, size: size)
                }
                .id(tickCount)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !started {
                                started = true
                                makeInitialBoom(value.location)
                            } else if score >= CIRCLE_COUNT {
                                resetGame()
                                started = true
                                makeInitialBoom(value.location)
                            } else {
                                makeInitialBoom(value.location)
                            }
                        }
                )

                VStack {
                    Spacer()
                    status()
                }
                .padding()
            }
            .onAppear {
                appear(proxy)
            }
        }
    }

    private func startGameLoop() {
        timer = Timer.scheduledTimer(withTimeInterval: gameUpdateInterval, repeats: true) { _ in
            Task { @MainActor in
                move()
                checkCollisions()
                boom()
                tickCount += 1
            }
        }
    }
}

#Preview {
    ContentView()
}
