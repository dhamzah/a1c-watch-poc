import SwiftUI

enum A1CColor {
    static let inRange = Color(red: 0.20, green: 0.78, blue: 0.55)
    static let high = Color(red: 1.00, green: 0.62, blue: 0.20)
    static let veryHigh = Color(red: 1.00, green: 0.36, blue: 0.33)
    static let low = Color(red: 0.98, green: 0.30, blue: 0.40)
    static let battery = Color(red: 0.35, green: 0.70, blue: 1.00)
    static let readiness = Color(red: 0.70, green: 0.52, blue: 1.00)
    static let stale = Color.gray

    static func glucose(_ v: Double, t: Thresholds = Thresholds()) -> Color {
        if v < t.low { return low }
        if v > 180 { return veryHigh }
        if v > t.high { return high }
        return inRange
    }
}
