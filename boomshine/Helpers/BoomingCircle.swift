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
