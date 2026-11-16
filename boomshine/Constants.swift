import SwiftUI

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
let MINIMUM_CIRCLE_RADIUS: Float = 5.0
let MAXIMUM_CIRCLE_RADIUS: Float = MINIMUM_CIRCLE_RADIUS * 32.0

enum GameSpeed: String {
  case slow = "Slow"
  case regular = "Regular"
  case fast = "Fast"
  case superfast = "Superfast"
}

let STEP_SIZE_SLOW: Int = 1
let STEP_SIZE_REGULAR: Int = 2
let STEP_SIZE_FAST: Int = 4
let STEP_SIZE_SUPERFAST: Int = 8

func stepSize(for speed: GameSpeed) -> Int {
  switch speed {
  case .slow: return STEP_SIZE_SLOW
  case .regular: return STEP_SIZE_REGULAR
  case .fast: return STEP_SIZE_FAST
  case .superfast: return STEP_SIZE_SUPERFAST
  }
}

struct ProgressiveLevel {
  let id: Int
  let bombSize: Double
  let fiendBombSize: Double
  let bombs: Int
  let ships: Int
  let goal: Int
}

let miniSize = 0.125
let smallSize = 0.25
let mediumSize = 0.5
let largeSize = 0.75

let PROGRESSIVE_LEVELS: [ProgressiveLevel] = [
  ProgressiveLevel(
    id: 1, bombSize: smallSize, fiendBombSize: smallSize, bombs: 1, ships: 1, goal: 1),
  ProgressiveLevel(
    id: 2, bombSize: smallSize, fiendBombSize: smallSize, bombs: 3, ships: 2, goal: 2),
  ProgressiveLevel(
    id: 3, bombSize: smallSize, fiendBombSize: smallSize, bombs: 6, ships: 4, goal: 3),
  ProgressiveLevel(
    id: 4, bombSize: smallSize, fiendBombSize: smallSize, bombs: 12, ships: 8, goal: 5),

  ProgressiveLevel(
    id: 5, bombSize: mediumSize, fiendBombSize: smallSize, bombs: 5, ships: 16, goal: 12),
  ProgressiveLevel(
    id: 6, bombSize: mediumSize, fiendBombSize: smallSize, bombs: 5, ships: 32, goal: 16),
  ProgressiveLevel(
    id: 7, bombSize: mediumSize, fiendBombSize: mediumSize, bombs: 10, ships: 48, goal: 24),
  ProgressiveLevel(
    id: 8, bombSize: mediumSize, fiendBombSize: mediumSize, bombs: 10, ships: 64, goal: 36),

  ProgressiveLevel(
    id: 9, bombSize: largeSize, fiendBombSize: smallSize, bombs: 6, ships: 16, goal: 14),
  ProgressiveLevel(
    id: 10, bombSize: largeSize, fiendBombSize: mediumSize, bombs: 6, ships: 16, goal: 14),
  ProgressiveLevel(
    id: 11, bombSize: largeSize, fiendBombSize: mediumSize, bombs: 12, ships: 32, goal: 24),
  ProgressiveLevel(
    id: 12, bombSize: largeSize, fiendBombSize: largeSize, bombs: 12, ships: 64, goal: 55),
]
