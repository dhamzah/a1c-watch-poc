import Foundation

/// Trend + spike rules (POC runs them on the watch; production moves them to the backend
/// and sends APNs pushes so alerts never depend on the watch app being awake).
struct AlertEngine {
    var t = Thresholds()

    /// Evaluate the newest reading. `recent` = alerts already sent (for cooldown).
    func evaluate(_ s: Snapshot, recent: [GlucoseAlert], logs: [LogEntry]) -> [GlucoseAlert] {
        guard s.hasCGM, let last = s.latest, s.points.count >= 3 else { return [] }
        var out: [GlucoseAlert] = []
        let now = last.date

        func cooledDown(_ k: AlertKind) -> Bool {
            !recent.contains { $0.kind == k && now.timeIntervalSince($0.date) < t.cooldownMin * 60 }
        }

        // Slope over the last two 5-min steps (~10 min), must hold on both steps.
        let p = s.points
        let s1 = (p[p.count - 1].mgdl - p[p.count - 2].mgdl) / 5
        let s2 = (p[p.count - 2].mgdl - p[p.count - 3].mgdl) / 5
        let slope = (s1 + s2) / 2
        let projected20 = last.mgdl + slope * 20

        // Spike: >= spikeRise above the lowest reading in the prior 60 min, or crossing the high target.
        let window = p.filter { now.timeIntervalSince($0.date) <= 3600 }
        let baseline = window.map(\.mgdl).min() ?? last.mgdl
        let rise = last.mgdl - baseline
        let isSpike = rise >= t.spikeRise || (last.mgdl > t.high && (p.dropLast().last?.mgdl ?? 0) <= t.high + 30)

        if isSpike && cooledDown(.spike) {
            let food = logs.last { $0.kind == .food && abs(now.timeIntervalSince($0.date)) <= 3600 }
            let title = food.map { "Spike after \($0.summary.components(separatedBy: ",").first ?? $0.summary)" } ?? "Spike to \(Int(last.mgdl))"
            let body = food != nil
                ? "\(Int(last.mgdl)) mg/dL, +\(Int(rise)) in the last hour. A 10-min walk helps it come down."
                : "\(Int(last.mgdl)) mg/dL, +\(Int(rise)) in the last hour. What did you eat?"
            out.append(GlucoseAlert(kind: .spike, date: now, mgdl: last.mgdl, delta: rise, title: title, body: body))
        } else if (slope >= t.trendSlope && s1 >= t.trendSlope * 0.75) || (slope > 0.5 && projected20 >= t.high && last.mgdl < t.high),
                  cooledDown(.rising) {
            out.append(GlucoseAlert(kind: .rising, date: now, mgdl: last.mgdl, delta: slope,
                                    title: "Rising fast",
                                    body: "\(Int(last.mgdl)) and climbing about \(String(format: "%.1f", slope)) per min. Log what you ate, or take a short walk."))
        }

        if last.mgdl < t.low, cooledDown(.low) {
            out.append(GlucoseAlert(kind: .low, date: now, mgdl: last.mgdl, delta: nil,
                                    title: "Below \(Int(t.low))",
                                    body: "\(Int(last.mgdl)) mg/dL. Informational only, not for treatment decisions."))
        } else if (slope <= -t.trendSlope && s1 <= -t.trendSlope * 0.75) || (slope < -0.5 && projected20 <= t.low && last.mgdl > t.low),
                  cooledDown(.falling) {
            out.append(GlucoseAlert(kind: .falling, date: now, mgdl: last.mgdl, delta: slope,
                                    title: "Dropping fast",
                                    body: "\(Int(last.mgdl)) and falling about \(String(format: "%.1f", abs(slope))) per min."))
        }
        return out
    }

    /// Recap after a spike has resolved (back within 20 mg/dL of baseline).
    func recap(_ s: Snapshot) -> (peak: Int, rise: Int, minutesAbove: Int)? {
        guard s.hasCGM, let last = s.latest else { return nil }
        let win = s.points.filter { last.date.timeIntervalSince($0.date) <= 3 * 3600 }
        guard let peak = win.max(by: { $0.mgdl < $1.mgdl }), let base = win.map(\.mgdl).min() else { return nil }
        let above = win.filter { $0.mgdl > t.high }.count * 5
        return (Int(peak.mgdl), Int(peak.mgdl - base), above)
    }
}
