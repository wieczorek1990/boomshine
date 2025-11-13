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
        if !running {
            return
        }

        maximumX(maxX)
        maximumY(maxY)

        stepX()
        stepY()
    }

    func touches(_ boomingCircles: [BoomingCircle]) -> Bool {
        for boomingCircle in boomingCircles {
            if boomingCircle.untoucheable {
                continue
            }
            if circle.touches(boomingCircle.circle) {
                return true
            }
        }
        return false
    }
}
