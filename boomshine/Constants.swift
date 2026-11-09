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
