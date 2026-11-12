import Foundation

/// A realistic CGM day for demos and screenshots: fasting ~92, lunch spike to ~168, walk, recovery.
enum DemoData {
    /// Glucose curve (mg/dL) at 5-min steps for the last 6 h, ending "now".
    /// The tail shows a post-lunch rise so the trend and spike alerts fire.
    static let curve: [Double] = [
        94, 93, 92, 92, 91, 92, 93, 92, 91, 90, 91, 92,      // 6h..5h ago, steady
        93, 95, 98, 104, 112, 121, 128, 133, 135, 132, 126, 119, // breakfast bump
        112, 106, 101, 98, 96, 95, 94, 94, 93, 94, 95, 96,   // back to baseline
        97, 99, 104, 112, 122, 134, 147, 158, 166, 168, 167, 165 // lunch: rising fast -> spike
    ]

    static func snapshot(now: Date = Date(), curve: [Double] = curve) -> Snapshot {
        let end = Date(timeIntervalSince1970: (now.timeIntervalSince1970 / 300).rounded(.down) * 300)
        let pts = curve.enumerated().map { i, v in
            GlucosePoint(date: end.addingTimeInterval(Double(i - curve.count + 1) * 300), mgdl: v)
        }
        return Snapshot(asOf: now, hasCGM: true, points: pts,
                        bodyBattery: 64, readiness: 78, steps: 5_420, daylightMin: 34, tirTodayPct: 86)
    }

    /// Variant used for the "rising" screenshot (before the spike threshold is hit).
    static func risingSnapshot(now: Date = Date()) -> Snapshot {
        snapshot(now: now, curve: Array(curve.dropLast(5)))
    }

    static func noCGMSnapshot(now: Date = Date()) -> Snapshot {
        Snapshot(asOf: now, hasCGM: false, points: [], bodyBattery: 71, readiness: 82,
                 steps: 6_210, daylightMin: 41, tirTodayPct: nil)
    }
}
