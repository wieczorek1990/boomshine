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
        let x1 = Float(self.x)
        let y1 = Float(self.y)
        let r1 = self.radius
        let x2 = Float(other.x)
        let y2 = Float(other.y)
        let r2 = other.radius

        let dx = x1 - x2
        let dy = y1 - y2
        let distanceSquared = dx * dx + dy * dy

        let sumR = r1 + r2
        let diffR = abs(r1 - r2)
        let sumRSquared = sumR * sumR
        let diffRSquared = diffR * diffR

        if distanceSquared <= diffRSquared {
            return true
        } else if distanceSquared < sumRSquared {
            return true
        } else if distanceSquared == sumRSquared {
            return true
        } else {
            return false
        }
    }
}
