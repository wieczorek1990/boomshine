import SwiftUI

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

struct ContentView: View {
    @State private var started: Bool = false
    @State private var startDate: Date? = nil
    @State private var score: Int? = nil

    @State private var circles: [Circle] = []
    @State private var movingCircles: [MovingCircle] = []
    @State private var boomingCircles: [BoomingCircle] = []

    @State private var boomCircle: Circle? = nil
    @State private var boomingCircle: BoomingCircle? = nil

    func appear(_ proxy: GeometryProxy) {
        let width = Int(proxy.size.width)
        let height = Int(proxy.size.height)

        var localGenerator = SystemRandomNumberGenerator()

        for _ in 0..<CIRCLE_COUNT {
            let x = localGenerator.nextUnsignedInteger(width)
            let y = localGenerator.nextUnsignedInteger(height)
            let colorIndex = localGenerator.nextUnsignedInteger(COLORS.count)
            let color = COLORS[colorIndex]

            circles.append(
                Circle(
                    x: x,
                    y: y,
                    radius: MINIMUM_CIRCLE_RADIUS,
                    color: color
                )
            )
        }
    }

    func move(_ proxy: GeometryProxy) {
        let width = Int(proxy.size.width)
        let height = Int(proxy.size.height)

        for movingCircle in movingCircles {
            movingCircle.move(width, height)
        }
    }

    func draw(context: GraphicsContext, size: CGSize) {
        let circleDrawer = CircleDrawer(context, size)

        for movingCircle in movingCircles {
            let circle = movingCircle.circle

            circleDrawer.draw(
                circle.x,
                circle.y,
                circle.radius,
                circle.color
            )
        }

        for boomingCircle in boomingCircles {
            let circle = boomingCircle.circle

            circleDrawer.draw(
                circle.x,
                circle.y,
                circle.radius,
                circle.color
            )
        }
    }

    func prepare() {
        takeRandomDestinations()
        prepareForStart()
    }

    func choosePoint(value: DragGesture.Value) {
        let point = value.location

        makeInitialBoom(point)
    }

    func makeInitialBoom(_ point: CGPoint) {
        let x = point.x.toRoundedInt()
        let y = point.y.toRoundedInt()

        boomCircle = Circle(
            x: x,
            y: y,
            radius: MINIMUM_CIRCLE_RADIUS,
            color: USER_COLOR
        )
        boomingCircle = BoomingCircle(circle: boomCircle!)
        boomingCircles.append(boomingCircle!)
    }

    func takeRandomDestinations() {
        for circle in circles {
            let directionX = Int.random(in: 0...1)
            let directionY = Int.random(in: 0...1)
            let movingCircle = MovingCircle(circle, (directionX, directionY))

            movingCircles.append(movingCircle)
        }
    }

    func prepareForStart() {
        score = 0
        startDate = Date.now
    }

    func touch() {
        var indicesToRemove: [Int] = []
        var newBoomingCircles: [BoomingCircle] = []
        var scoreDelta = 0

        for (index, movingCircle) in movingCircles.enumerated().reversed() {
            if movingCircle.touches(boomingCircles) {
                indicesToRemove.append(index)
                movingCircle.stop()
                scoreDelta += 1

                let newBoomingCircle = BoomingCircle(
                    circle: movingCircle.circle
                )
                newBoomingCircles.append(newBoomingCircle)
            }
        }

        if !indicesToRemove.isEmpty || !newBoomingCircles.isEmpty
            || scoreDelta != 0
        {
            for index in indicesToRemove.sorted() {
                movingCircles.remove(at: index)
            }
            boomingCircles.append(contentsOf: newBoomingCircles)

            if let s = score {
                score = s + scoreDelta
            }
        }
    }

    func boom() {
        for boomingCircle in boomingCircles {
            boomingCircle.boom()
        }
    }

    @ViewBuilder
    func status() -> some View {
        if !started {
            Text("Press anywhere to start.")
        } else {
            if let unwrappedScore = score {
                if unwrappedScore < CIRCLE_COUNT {
                    Text("Score: \(unwrappedScore)")
                } else {
                    Text("Done.")
                }
            } else {
                Text("Setting score...")
            }
        }
    }

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                ZStack {
                    Color.clear
                    TimelineView(
                        .periodic(from: startDate ?? .now, by: 1.0 / 60.0)
                    ) { _ in
                        Task { @MainActor in
                            move(proxy)
                            touch()
                            boom()
                        }

                        return ZStack {
                            Canvas { graphicsContext, size in
                                draw(context: graphicsContext, size: size)
                            }
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onEnded { value in
                                        Task { @MainActor in
                                            if !started {
                                                prepare()
                                                started = true
                                            } else {
                                                choosePoint(value: value)
                                            }
                                        }
                                    }
                            )

                            VStack {
                                Spacer()
                                status()
                            }
                            .padding()
                        }
                    }
                }
                .onAppear {
                    appear(proxy)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
