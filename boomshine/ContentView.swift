import AppKit
import SwiftUI

enum GameState {
  case splash
  case settings
  case preGame
  case playing
  case postGame
}

struct ContentView: View {
  @Environment(\.colorScheme) private var colorScheme
  @State private var gameState: GameState = .splash
  @State private var escapeMonitor: Any?
  @State private var score: Int = 0
  @State private var bombsRemaining: Int = 4
  @State private var selectedBombs: Int = 4
  @State private var selectedCircles: Int = 32
  @State private var selectedSpeed: GameSpeed = .regular
  @State private var screenWidth: Int = 0
  @State private var screenHeight: Int = 0

  @State private var movingCircles: [MovingCircle] = []
  @State private var boomingCircles: [BoomingCircle] = []

  @State private var tickCount: Int = 0
  @State private var timer: Timer?
  @State private var initialized: Bool = false

  private let gameUpdateInterval: TimeInterval = 1.0 / 60.0

  func appear(_ proxy: GeometryProxy?) {
    let width = proxy.map { Int($0.size.width) } ?? screenWidth
    let height = proxy.map { Int($0.size.height) } ?? screenHeight

    screenWidth = width
    screenHeight = height

    if !initialized && width > 0 && height > 0 {
      initialized = true

      var rng = SystemRandomNumberGenerator()
      var circles: [Circle] = []

      for _ in 0..<selectedCircles {
        let x = rng.nextUnsignedInteger(width)
        let y = rng.nextUnsignedInteger(height)
        let colorIndex = rng.nextUnsignedInteger(COLORS.count)
        let color = COLORS[colorIndex]

        circles.append(Circle(x: x, y: y, radius: MINIMUM_CIRCLE_RADIUS, color: color))
      }

      takeRandomDestinations(from: circles)
    }
  }

  func move() {
    let step = stepSize(for: selectedSpeed)
    for mc in movingCircles {
      mc.move(screenWidth, screenHeight, stepSize: step)
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
    guard bombsRemaining > 0 else { return }
    bombsRemaining -= 1

    let x = point.x.toRoundedInt()
    let y = point.y.toRoundedInt()

    let boomCircle = Circle(x: x, y: y, radius: 0.0, color: USER_COLOR)
    boomingCircles.append(BoomingCircle(circle: boomCircle, initial: true))

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
      score = min(score + scoreDelta, selectedCircles)
    }
  }

  func boom() {
    for bc in boomingCircles {
      bc.boom()
    }
    boomingCircles.removeAll { $0.isDone }

    // When all bombs are spent and no booming circles remain, add ships to equalize and transition to postGame
    if gameState == .playing && bombsRemaining == 0 && boomingCircles.isEmpty {
      // Add new ships to replenish the count
      let shipsLeft = selectedCircles - score
      if shipsLeft > 0 {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<shipsLeft {
          let x = rng.nextUnsignedInteger(screenWidth)
          let y = rng.nextUnsignedInteger(screenHeight)
          let colorIndex = rng.nextUnsignedInteger(COLORS.count)
          let color = COLORS[colorIndex]
          let circle = Circle(x: x, y: y, radius: MINIMUM_CIRCLE_RADIUS, color: color)
          let dx = Int.random(in: 0...1)
          let dy = Int.random(in: 0...1)
          movingCircles.append(MovingCircle(circle, (dx, dy)))
        }
      }
      gameState = .postGame
    }
  }

  func resetGame() {
    timer?.invalidate()
    timer = nil
    gameState = .splash
    score = 0
    bombsRemaining = selectedBombs
    movingCircles.removeAll()
    boomingCircles.removeAll()
    tickCount += 1
  }

  func enterSettings() {
    gameState = .settings
    startGameLoop()
  }

  func enterPreGame() {
    gameState = .preGame
  }

  func enterGame() {
    bombsRemaining = selectedBombs
    gameState = .playing
  }

  @ViewBuilder
  func settings() -> some View {
    let primaryColor = colorScheme == .dark ? Color.white : Color.black
    let secondaryColor = colorScheme == .dark ? Color.gray : Color.gray
    VStack(spacing: 12) {
      VStack(spacing: 4) {
        Text("Bombs")
          .font(.caption)
          .foregroundColor(secondaryColor)
        HStack(spacing: 8) {
          Button("4◀") {
            if selectedBombs > 4 { selectedBombs -= 4 } else { selectedBombs = 1 }
          }
          Button("-") {
            if selectedBombs > 1 { selectedBombs -= 1 }
          }
          Text("\(selectedBombs)")
            .font(.title3)
            .foregroundColor(primaryColor)
            .frame(width: 30)
          Button("+") {
            if selectedBombs < 16 { selectedBombs += 1 }
          }
          Button("▶4") {
            if selectedBombs < 12 { selectedBombs += 4 } else { selectedBombs = 16 }
          }
        }
      }
      VStack(spacing: 4) {
        Text("Ships")
          .font(.caption)
          .foregroundColor(secondaryColor)
        HStack(spacing: 8) {
          Button("8◀") {
            if selectedCircles > 8 { selectedCircles -= 8 } else { selectedCircles = 1 }
          }
          Button("-") {
            if selectedCircles > 1 { selectedCircles -= 1 }
          }
          Text("\(selectedCircles)")
            .font(.title3)
            .foregroundColor(primaryColor)
            .frame(width: 30)
          Button("+") {
            if selectedCircles < 64 { selectedCircles += 1 }
          }
          Button("▶8") {
            if selectedCircles < 56 { selectedCircles += 8 } else { selectedCircles = 64 }
          }
        }
      }
      VStack(spacing: 4) {
        Text("Speed")
          .font(.caption)
          .foregroundColor(secondaryColor)
        HStack(spacing: 8) {
          Button("Slow") {
            selectedSpeed = .slow
          }
          .foregroundColor(selectedSpeed == .slow ? primaryColor : secondaryColor)
          Button("Regular") {
            selectedSpeed = .regular
          }
          .foregroundColor(selectedSpeed == .regular ? primaryColor : secondaryColor)
          Button("Fast") {
            selectedSpeed = .fast
          }
          .foregroundColor(selectedSpeed == .fast ? primaryColor : secondaryColor)
          Button("Superfast") {
            selectedSpeed = .superfast
          }
          .foregroundColor(selectedSpeed == .superfast ? primaryColor : secondaryColor)
        }
      }
      Text("Select.")
        .font(.title2)
        .foregroundColor(primaryColor)
        .padding(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(primaryColor, lineWidth: 2))
        .onTapGesture {
          enterPreGame()
        }
    }
  }

  @ViewBuilder
  func status() -> some View {
    let primaryColor = colorScheme == .dark ? Color.white : Color.black
    let secondaryColor = colorScheme == .dark ? Color.gray : Color.gray
    if gameState == .preGame {
      VStack(spacing: 12) {
        Text("Play.")
          .font(.title2)
          .foregroundColor(primaryColor)
          .padding(8)
          .overlay(RoundedRectangle(cornerRadius: 8).stroke(primaryColor, lineWidth: 2))
          .onTapGesture {
            movingCircles.removeAll()
            boomingCircles.removeAll()
            score = 0
            bombsRemaining = selectedBombs
            initialized = false
            appear(nil)
            enterGame()
          }
      }
    } else if gameState == .postGame {
      VStack(spacing: 12) {
        HStack(spacing: 16) {
          Text("Bombs: \(bombsRemaining)")
            .font(.body)
            .foregroundColor(primaryColor)
          Text("Used: \(selectedBombs - bombsRemaining)")
            .font(.body)
            .foregroundColor(primaryColor)
          Text("Ships: \(score)")
            .font(.body)
            .foregroundColor(primaryColor)
          Text("Left: \(selectedCircles - score)")
            .font(.body)
            .foregroundColor(primaryColor)
        }
        Text("Play Again.")
          .font(.title2)
          .foregroundColor(primaryColor)
          .padding(8)
          .overlay(RoundedRectangle(cornerRadius: 8).stroke(primaryColor, lineWidth: 2))
          .onTapGesture {
            movingCircles.removeAll()
            boomingCircles.removeAll()
            score = 0
            bombsRemaining = selectedBombs
            initialized = false
            appear(nil)
            enterGame()
          }
        Text("Settings.")
          .font(.body)
          .foregroundColor(secondaryColor)
          .padding(8)
          .overlay(RoundedRectangle(cornerRadius: 8).stroke(secondaryColor, lineWidth: 2))
          .onTapGesture {
            enterSettings()
          }
      }
    } else {
      EmptyView()
    }
  }

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        if gameState == .splash {
          Color.black
        } else if colorScheme == .dark {
          Color.black
        } else {
          Color.white
        }

        Canvas { ctx, size in
          if gameState != .splash {
            draw(context: ctx, size: size)
          }
        }
        .id(tickCount)
        .gesture(
          DragGesture(minimumDistance: 0)
            .onEnded { value in
              if gameState == .splash {
                enterSettings()
              } else if gameState == .settings {
                enterPreGame()
              } else if gameState == .preGame {
                movingCircles.removeAll()
                boomingCircles.removeAll()
                score = 0
                bombsRemaining = selectedBombs
                initialized = false
                appear(nil)
                enterGame()
              } else if gameState == .postGame {
                enterSettings()
              } else if score >= selectedCircles {
                gameState = .postGame
              } else {
                makeInitialBoom(value.location)
              }
            }
        )

        if gameState == .splash {
          SplashView()
        } else if gameState == .settings {
          settings()
        } else if gameState == .playing {
          VStack {
            HStack(spacing: 16) {
              Text("Bombs: \(bombsRemaining)")
                .font(.body)
                .foregroundColor(colorScheme == .dark ? .white : .black)
              Text("Used: \(selectedBombs - bombsRemaining)")
                .font(.body)
                .foregroundColor(colorScheme == .dark ? .white : .black)
              Text("Ships: \(score)")
                .font(.body)
                .foregroundColor(colorScheme == .dark ? .white : .black)
              Text("Left: \(selectedCircles - score)")
                .font(.body)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            .padding()
            Spacer()
            status()
          }
          .padding(.top)
        } else if gameState == .preGame || gameState == .postGame {
          status()
        }
      }
      .onAppear {
        appear(proxy)
        if gameState == .splash {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            enterSettings()
          }
        }
        let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
          if event.keyCode == 53 {  // ESC key
            if gameState == .splash || gameState == .settings {
              NSApplication.shared.terminate(nil)
              return nil
            } else if gameState == .playing {
              resetGame()
              return nil
            }
          } else if event.keyCode == 49 {  // Space key
            if gameState == .splash {
              enterSettings()
              return nil
            } else if gameState == .settings {
              enterPreGame()
              return nil
            } else if gameState == .preGame {
              movingCircles.removeAll()
              boomingCircles.removeAll()
              score = 0
              bombsRemaining = selectedBombs
              initialized = false
              appear(nil)
              enterGame()
              return nil
            } else if gameState == .postGame {
              enterSettings()
              return nil
            }
          } else if event.keyCode == 8 && event.modifierFlags.contains(.command) {  // Cmd+C -> Play
            if gameState == .preGame {
              movingCircles.removeAll()
              boomingCircles.removeAll()
              score = 0
              bombsRemaining = selectedBombs
              initialized = false
              appear(nil)
              enterGame()
              return nil
            } else if gameState == .postGame {
              movingCircles.removeAll()
              boomingCircles.removeAll()
              score = 0
              bombsRemaining = selectedBombs
              initialized = false
              appear(nil)
              enterGame()
              return nil
            }
          }
          return event
        }
        escapeMonitor = monitor
      }
      .onChange(of: proxy.size) { _, newSize in
        screenWidth = Int(newSize.width)
        screenHeight = Int(newSize.height)
        appear(proxy)
      }
      .onDisappear {
        if let monitor = escapeMonitor {
          NSEvent.removeMonitor(monitor)
        }
      }
    }
  }

  private func startGameLoop() {
    timer = Timer.scheduledTimer(withTimeInterval: gameUpdateInterval, repeats: true) { _ in
      Task { @MainActor in
        move()
        if gameState != .preGame && gameState != .settings {
          checkCollisions()
        }
        boom()
        tickCount += 1
      }
    }
  }
}

#Preview {
  ContentView()
}
