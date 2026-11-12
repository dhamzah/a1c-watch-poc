import Foundation

enum Trend: String, Codable {
    case risingFast, rising, steady, falling, fallingFast

    var arrow: String {
        switch self {
        case .risingFast: return "⇈"
        case .rising: return "↗"
        case .steady: return "→"
        case .falling: return "↘"
        case .fallingFast: return "⇊"
        }
    }

    /// slope in mg/dL per minute
    static func from(slope: Double) -> Trend {
        if slope >= 2 { return .risingFast }
        if slope >= 1 { return .rising }
        if slope <= -2 { return .fallingFast }
        if slope <= -1 { return .falling }
        return .steady
    }
}

struct GlucosePoint: Codable, Hashable {
    let date: Date
    let mgdl: Double
}

struct Snapshot: Codable {
    var asOf: Date
    var hasCGM: Bool
    var points: [GlucosePoint]          // oldest -> newest, 5-min resolution, last ~6 h
    var bodyBattery: Int
    var readiness: Int
    var steps: Int
    var daylightMin: Int
    var tirTodayPct: Int?

    var latest: GlucosePoint? { points.last }

    var trend: Trend {
        guard points.count >= 3 else { return .steady }
        let last = points[points.count - 1]
        let ref = points[points.count - 3]           // ~10 min earlier
        let mins = max(1, last.date.timeIntervalSince(ref.date) / 60)
        return Trend.from(slope: (last.mgdl - ref.mgdl) / mins)
    }

    /// Minutes since the newest reading.
    func ageMinutes(now: Date = Date()) -> Int? {
        guard let l = latest else { return nil }
        return Int(now.timeIntervalSince(l.date) / 60)
    }

    /// A reading older than 15 min is shown greyed out as stale.
    func isStale(now: Date = Date()) -> Bool { (ageMinutes(now: now) ?? 999) > 15 }

    var last3h: [GlucosePoint] {
        guard let l = latest else { return [] }
        return points.filter { l.date.timeIntervalSince($0.date) <= 3 * 3600 }
    }
}

enum DataSource: String, CaseIterable, Identifiable {
    case demo = "Demo day"
    case sally = "Live (Sally key)"
    var id: String { rawValue }
}

struct Thresholds {
    var low: Double = 70
    var high: Double = 140
    var trendSlope: Double = 2          // mg/dL/min
    var spikeRise: Double = 30          // mg/dL above pre-rise baseline within 60 min
    var cooldownMin: Double = 60
}

enum AlertKind: String, Codable {
    case rising, falling, low, spike, spikeRecap
}

struct GlucoseAlert: Codable, Identifiable, Hashable {
    var id = UUID()
    let kind: AlertKind
    let date: Date
    let mgdl: Double
    let delta: Double?
    let title: String
    let body: String
}

enum LogKind: String, Codable { case food, activity, water, supplement, symptom }

struct LogEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    let date: Date
    let kind: LogKind
    let text: String          // what the user said
    let summary: String       // parsed, e.g. "Nasi padang (half rice), rendang"
    let carbsG: Int?
    let minutes: Int?
}
