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
