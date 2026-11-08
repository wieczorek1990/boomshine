import SwiftUI

enum GameState {
    case splash
    case preGame
    case playing
}

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var gameState: GameState = .splash
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
        gameState = .splash
        score = 0
        movingCircles.removeAll()
        boomingCircles.removeAll()
        tickCount += 1
    }

    func enterGame() {
        gameState = .playing
        startGameLoop()
    }

    @ViewBuilder
    func status() -> some View {
        if gameState == .preGame {
            EmptyView()
        } else {
            if score < CIRCLE_COUNT {
                Text("Score: \(score)")
            } else {
                EmptyView()
            }
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if gameState == .splash {
                    Color.black
                } else if colorScheme == .dark {
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
                        .onEnded { value in
                            if gameState == .splash {
                                gameState = .preGame
                            } else if gameState == .preGame {
                                enterGame()
                            } else if score >= CIRCLE_COUNT {
                                resetGame()
                            } else {
                                makeInitialBoom(value.location)
                            }
                        }
                )

                if gameState == .splash {
                    SplashView()
                } else {
                    VStack {
                        Spacer()
                        status()
                    }
                    .padding()
                }
            }
            .onAppear {
                appear(proxy)
                if gameState == .splash {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        gameState = .preGame
                    }
                }
            }
            .onKeyPress(.escape) {
                if gameState == .playing {
                    resetGame()
                }
                return .handled
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
