import AppKit
import SwiftUI

enum GameState {
  case splash
  case menu
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
  @State private var selectedBombSize: Double = 1.0
  @State private var selectedFiendBombSize: Double = 1.0
  @State private var selectedSpeed: GameSpeed = .regular
  @State private var progressiveMode: Bool = false
  @State private var infinityMode: Bool = false
  @State private var currentLevel: Int = 0
  @State private var gameWon: Bool = false
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
    let maxR = Float(currentBombSize()) * MAXIMUM_CIRCLE_RADIUS
    boomingCircles.append(BoomingCircle(circle: boomCircle, initial: true, maxRadius: maxR))

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
        let fiendMaxR = Float(currentFiendBombSize()) * MAXIMUM_CIRCLE_RADIUS
        newBoomingCircles.append(BoomingCircle(circle: mc.circle, maxRadius: fiendMaxR))
      }
    }

    if !indicesToRemove.isEmpty || !newBoomingCircles.isEmpty || scoreDelta != 0 {
      for index in indicesToRemove.sorted(by: >) {
        movingCircles.remove(at: index)
      }
      boomingCircles.append(contentsOf: newBoomingCircles)
      score = min(score + scoreDelta, currentGoal())
    }
  }

  func currentGoal() -> Int {
    if progressiveMode {
      return PROGRESSIVE_LEVELS[currentLevel].goal
    }
    if infinityMode {
      return generateInfinityLevel(currentLevel).goal
    }
    return selectedCircles
  }

  func currentBombSize() -> Double {
    if progressiveMode {
      return PROGRESSIVE_LEVELS[currentLevel].bombSize
    }
    if infinityMode {
      return generateInfinityLevel(currentLevel).bombSize
    }
    return selectedBombSize
  }

  func currentFiendBombSize() -> Double {
    if progressiveMode {
      return PROGRESSIVE_LEVELS[currentLevel].fiendBombSize
    }
    if infinityMode {
      return generateInfinityLevel(currentLevel).fiendBombSize
    }
    return selectedFiendBombSize
  }

  func formatNumber(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 4
    formatter.minimumFractionDigits = 0
    return formatter.string(from: value as NSNumber) ?? String(value)
  }

  func boom() {
    for bc in boomingCircles {
      bc.boom()
    }
    boomingCircles.removeAll { $0.isDone }

    let goal = currentGoal()

    // End with failure when no bombs and no booming circles remain, even if moving circles are still on screen
    if gameState == .playing && bombsRemaining == 0 && boomingCircles.isEmpty {
      if score < goal {
        gameWon = false
      } else {
        gameWon = true
      }
      movingCircles.removeAll()
      gameState = .postGame
      return
    }

    guard gameState == .playing && boomingCircles.isEmpty && movingCircles.isEmpty else { return }

    // End the round when goal is met (even if bombs remain)
    if score >= goal {
      // In progressive mode, advance to the next level if the goal was met
      if progressiveMode && currentLevel < PROGRESSIVE_LEVELS.count - 1 {
        gameWon = true
        currentLevel += 1
        let level = PROGRESSIVE_LEVELS[currentLevel]
        selectedBombs = level.bombs
        selectedCircles = level.ships
        score = 0
        bombsRemaining = selectedBombs
        movingCircles.removeAll()
        boomingCircles.removeAll()
        initialized = false
        appear(nil)
        return
      }
      // In infinity mode, always advance to the next level
      if infinityMode {
        gameWon = true
        currentLevel += 1
        let level = generateInfinityLevel(currentLevel)
        selectedBombs = level.bombs
        selectedCircles = level.ships
        score = 0
        bombsRemaining = selectedBombs
        movingCircles.removeAll()
        boomingCircles.removeAll()
        initialized = false
        appear(nil)
        return
      }
      gameWon = true
      gameState = .postGame
    }
  }

  func resetGame() {
    timer?.invalidate()
    timer = nil
    progressiveMode = false
    infinityMode = false
    currentLevel = 0
    selectedBombs = 4
    selectedCircles = 32
    selectedBombSize = 1.0
    selectedFiendBombSize = 1.0
    gameState = .splash
    score = 0
    bombsRemaining = selectedBombs
    movingCircles.removeAll()
    boomingCircles.removeAll()
    tickCount += 1
  }

  func enterSettings() {
    progressiveMode = false
    infinityMode = false
    gameState = .settings
  }

  func enterMenu() {
    movingCircles.removeAll()
    boomingCircles.removeAll()
    initialized = false
    appear(nil)
    startGameLoop()
    gameState = .menu
  }

  func enterProgressive() {
    progressiveMode = true
    infinityMode = false
    currentLevel = 0
    let level = PROGRESSIVE_LEVELS[currentLevel]
    selectedBombs = level.bombs
    selectedCircles = level.ships
    enterPreGame()
  }

  func enterInfinity() {
    progressiveMode = false
    infinityMode = true
    currentLevel = 0
    let level = generateInfinityLevel(currentLevel)
    selectedBombs = level.bombs
    selectedCircles = level.ships
    enterPreGame()
  }

  func enterPreGame() {
    gameState = .preGame
  }

  func enterGame() {
    if progressiveMode {
      let level = PROGRESSIVE_LEVELS[currentLevel]
      selectedBombs = level.bombs
      selectedCircles = level.ships
    } else if infinityMode {
      let level = generateInfinityLevel(currentLevel)
      selectedBombs = level.bombs
      selectedCircles = level.ships
    }
    bombsRemaining = selectedBombs
    startGameLoop()
    gameState = .playing
  }

  @ViewBuilder
  func menu() -> some View {
    let primaryColor = colorScheme == .dark ? Color.white : Color.black
    VStack(spacing: 16) {
      Text("Select.")
        .font(.title2)
        .foregroundColor(primaryColor)
        .padding(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(primaryColor, lineWidth: 2))
        .onTapGesture {
          enterSettings()
        }
      Text("Progressive.")
        .font(.title2)
        .foregroundColor(primaryColor)
        .padding(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(primaryColor, lineWidth: 2))
        .onTapGesture {
          enterProgressive()
        }
      Text("Infinity.")
        .font(.title2)
        .foregroundColor(primaryColor)
        .padding(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(primaryColor, lineWidth: 2))
        .onTapGesture {
          enterInfinity()
        }
    }
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
        Text("Bomb Size")
          .font(.caption)
          .foregroundColor(secondaryColor)
        HStack(spacing: 8) {
          Button("Mini") {
            selectedBombSize = miniSize
          }
          .foregroundColor(selectedBombSize == miniSize ? primaryColor : secondaryColor)
          Button("Small") {
            selectedBombSize = smallSize
          }
          .foregroundColor(selectedBombSize == smallSize ? primaryColor : secondaryColor)
          Button("Medium") {
            selectedBombSize = mediumSize
          }
          .foregroundColor(selectedBombSize == mediumSize ? primaryColor : secondaryColor)
          Button("Large") {
            selectedBombSize = largeSize
          }
          .foregroundColor(selectedBombSize == largeSize ? primaryColor : secondaryColor)
        }
      }
      VStack(spacing: 4) {
        Text("Fiend Bomb Size")
          .font(.caption)
          .foregroundColor(secondaryColor)
        HStack(spacing: 8) {
          Button("Mini") {
            selectedFiendBombSize = miniSize
          }
          .foregroundColor(selectedFiendBombSize == miniSize ? primaryColor : secondaryColor)
          Button("Small") {
            selectedFiendBombSize = smallSize
          }
          .foregroundColor(selectedFiendBombSize == smallSize ? primaryColor : secondaryColor)
          Button("Medium") {
            selectedFiendBombSize = mediumSize
          }
          .foregroundColor(selectedFiendBombSize == mediumSize ? primaryColor : secondaryColor)
          Button("Large") {
            selectedFiendBombSize = largeSize
          }
          .foregroundColor(selectedFiendBombSize == largeSize ? primaryColor : secondaryColor)
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
      Text("Go back.")
        .font(.body)
        .foregroundColor(secondaryColor)
        .padding(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(secondaryColor, lineWidth: 2))
        .onTapGesture {
          enterMenu()
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
            gameWon = false
            initialized = false
            appear(nil)
            enterGame()
          }
        Text("Go back.")
          .font(.body)
          .foregroundColor(secondaryColor)
          .padding(8)
          .overlay(RoundedRectangle(cornerRadius: 8).stroke(secondaryColor, lineWidth: 2))
          .onTapGesture {
            enterMenu()
          }
      }
    } else if gameState == .postGame {
      VStack(spacing: 12) {
        if gameWon {
          Text("You won!")
            .font(.title)
            .foregroundColor(primaryColor)
        } else {
          Text("You failed!")
            .font(.title)
            .foregroundColor(primaryColor)
        }
        HStack(spacing: 16) {
          if progressiveMode {
            Text("Level: \(currentLevel + 1)/\(PROGRESSIVE_LEVELS.count)")
              .font(.body)
              .foregroundColor(primaryColor)
          }
          if infinityMode {
            Text("Level: \(currentLevel + 1)")
              .font(.body)
              .foregroundColor(primaryColor)
          }
          Text("Bomb size: \(formatNumber(currentBombSize()))")
            .font(.body)
            .foregroundColor(primaryColor)
          Text("Bombs count: \(bombsRemaining)")
            .font(.body)
            .foregroundColor(primaryColor)
          Text("Bombs used: \(selectedBombs - bombsRemaining)")
            .font(.body)
            .foregroundColor(primaryColor)
          let goal = currentGoal()
          Text("Ships count: \(selectedCircles)")
            .font(.body)
            .foregroundColor(primaryColor)
          Text("Ships left: \(max(0, goal - score))")
            .font(.body)
            .foregroundColor(primaryColor)
          Text("Goal: \(goal)")
            .font(.body)
            .foregroundColor(primaryColor)
        }
        if gameWon && progressiveMode && currentLevel < PROGRESSIVE_LEVELS.count - 1 {
          Text("Next.")
            .font(.title2)
            .foregroundColor(primaryColor)
            .padding(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(primaryColor, lineWidth: 2))
            .onTapGesture {
              currentLevel += 1
              let level = PROGRESSIVE_LEVELS[currentLevel]
              selectedBombs = level.bombs
              selectedCircles = level.ships
              score = 0
              bombsRemaining = selectedBombs
              movingCircles.removeAll()
              boomingCircles.removeAll()
              initialized = false
              appear(nil)
              enterGame()
            }
        }
        if gameWon && infinityMode {
          Text("Next.")
            .font(.title2)
            .foregroundColor(primaryColor)
            .padding(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(primaryColor, lineWidth: 2))
            .onTapGesture {
              currentLevel += 1
              let level = generateInfinityLevel(currentLevel)
              selectedBombs = level.bombs
              selectedCircles = level.ships
              score = 0
              bombsRemaining = selectedBombs
              movingCircles.removeAll()
              boomingCircles.removeAll()
              initialized = false
              appear(nil)
              enterGame()
            }
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
            gameWon = false
            initialized = false
            appear(nil)
            enterGame()
          }
        Text("Menu.")
          .font(.body)
          .foregroundColor(secondaryColor)
          .padding(8)
          .overlay(RoundedRectangle(cornerRadius: 8).stroke(secondaryColor, lineWidth: 2))
          .onTapGesture {
            enterMenu()
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
              if gameState == .playing {
                makeInitialBoom(value.location)
              } else if gameState == .splash {
                enterMenu()
              }
            }
        )

        if gameState == .splash {
          SplashView()
            .onTapGesture {
              enterMenu()
            }
        } else if gameState == .menu {
          menu()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {}
        } else if gameState == .settings {
          settings()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {}
        } else if gameState == .playing {
          VStack {
            HStack(spacing: 16) {
              if progressiveMode {
                Text("Level: \(PROGRESSIVE_LEVELS[currentLevel].id)/\(PROGRESSIVE_LEVELS.count)")
                  .font(.body)
                  .foregroundColor(colorScheme == .dark ? .white : .black)
              }
              if infinityMode {
                Text("Level: \(currentLevel + 1)")
                  .font(.body)
                  .foregroundColor(colorScheme == .dark ? .white : .black)
              }
              Text("Bomb size: \(formatNumber(currentBombSize()))")
              Text("Bombs count: \(bombsRemaining)")
                .font(.body)
                .foregroundColor(colorScheme == .dark ? .white : .black)
              Text("Bombs used: \(selectedBombs - bombsRemaining)")
                .font(.body)
                .foregroundColor(colorScheme == .dark ? .white : .black)
              let goal = currentGoal()
              Text("Ships count: \(selectedCircles)")
                .font(.body)
                .foregroundColor(colorScheme == .dark ? .white : .black)
              Text("Ships left: \(max(0, goal - score))")
                .font(.body)
                .foregroundColor(colorScheme == .dark ? .white : .black)
              Text("Goal: \(goal)")
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {}
        }
      }
      .onAppear {
        appear(proxy)
        if gameState == .splash {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            enterMenu()
          }
        }
        let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
          if event.keyCode == 53 {  // ESC key
            if gameState == .splash || gameState == .settings || gameState == .menu {
              NSApplication.shared.terminate(nil)
              return nil
            } else if gameState == .playing {
              resetGame()
              return nil
            }
          } else if event.keyCode == 49 {  // Space key
            if gameState == .splash {
              enterMenu()
              return nil
            } else if gameState == .menu {
              enterPreGame()
              return nil
            } else if gameState == .preGame {
              movingCircles.removeAll()
              boomingCircles.removeAll()
              score = 0
              bombsRemaining = selectedBombs
              gameWon = false
              initialized = false
              appear(nil)
              enterGame()
              return nil
            } else if gameState == .postGame {
              enterMenu()
              return nil
            } else if gameState == .playing && progressiveMode {
              // Skip to next level or end game on last level
              if currentLevel < PROGRESSIVE_LEVELS.count - 1 {
                currentLevel += 1
                let level = PROGRESSIVE_LEVELS[currentLevel]
                selectedBombs = level.bombs
                selectedCircles = level.ships
                score = 0
                bombsRemaining = selectedBombs
                movingCircles.removeAll()
                boomingCircles.removeAll()
                initialized = false
                appear(nil)
              } else {
                // On last level, end the game
                gameWon = score >= currentGoal()
                gameState = .postGame
              }
              return nil
            } else if gameState == .playing && infinityMode {
              // In infinity mode, always advance to the next level
              currentLevel += 1
              let level = generateInfinityLevel(currentLevel)
              selectedBombs = level.bombs
              selectedCircles = level.ships
              score = 0
              bombsRemaining = selectedBombs
              movingCircles.removeAll()
              boomingCircles.removeAll()
              initialized = false
              appear(nil)
              return nil
            }
          } else if event.keyCode == 8 && event.modifierFlags.contains(.command) {  // Cmd+C -> Play
            if gameState == .preGame {
              movingCircles.removeAll()
              boomingCircles.removeAll()
              score = 0
              bombsRemaining = selectedBombs
              gameWon = false
              initialized = false
              appear(nil)
              enterGame()
              return nil
            } else if gameState == .postGame {
              movingCircles.removeAll()
              boomingCircles.removeAll()
              score = 0
              bombsRemaining = selectedBombs
              gameWon = false
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
    timer?.invalidate()
    timer = Timer.scheduledTimer(withTimeInterval: gameUpdateInterval, repeats: true) { _ in
      Task { @MainActor in
        move()
        if gameState == .playing {
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
