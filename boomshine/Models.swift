import SwiftUI

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
    var isDone: Bool = false
    var initial: Bool = false

    init(circle: Circle, initial: Bool = false) {
        self.circle = circle
        self.initial = initial
    }

    func boom() {
        if !fall {
            if fallCount >= 1 {
                if circle.radius > EPSILON {
                    circle.radius /= DEFAULT_SIZE_MULTIPLIER
                } else {
                    circle.radius = 0.0
                    untoucheable = true
                    isDone = true
                }
                return
            }

            if circle.radius > MAXIMUM_CIRCLE_RADIUS {
                fall = true
                fallCount += 1
            }
            if initial {
                // Start from zero with additive growth, then switch to multiplicative
                if circle.radius < EPSILON {
                    circle.radius += 0.5
                } else {
                    // Quick burst to medium, then stable growth to max
                    let medium = MAXIMUM_CIRCLE_RADIUS / 2
                    if circle.radius < medium {
                        // Fast growth phase: small → medium (additive boost for smooth visible growth)
                        circle.radius *= DEFAULT_SIZE_MULTIPLIER
                        circle.radius += 2.0
                    } else {
                        // Stable growth phase: medium → max
                        circle.radius *= DEFAULT_SIZE_MULTIPLIER
                    }
                }
            } else {
                circle.radius *= DEFAULT_SIZE_MULTIPLIER
            }
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
            circle.x = maxX
            direction.0 = 1
        } else if circle.x < 0 {
            circle.x = 0
            direction.0 = 0
        }
    }

    func maximumY(_ maxY: Int) {
        if circle.y > maxY {
            circle.y = maxY
            direction.1 = 1
        } else if circle.y < 0 {
            circle.y = 0
            direction.1 = 0
        }
    }

    func stepX(_ stepSize: Int) {
        if direction.0 == 0 {
            circle.x += stepSize
        } else if direction.0 == 1 {
            circle.x -= stepSize
        }
    }

    func stepY(_ stepSize: Int) {
        if direction.1 == 0 {
            circle.y += stepSize
        } else if direction.1 == 1 {
            circle.y -= stepSize
        }
    }

    func move(_ maxX: Int, _ maxY: Int, stepSize: Int) {
        if !running { return }
        maximumX(maxX)
        maximumY(maxY)
        stepX(stepSize)
        stepY(stepSize)
    }

    func touches(_ boomingCircles: [BoomingCircle]) -> Bool {
        for bc in boomingCircles {
            if bc.untoucheable { continue }
            if circle.touches(bc.circle) { return true }
        }
        return false
    }
}
