import Foundation

/// POC data source: the same A1C backend the iOS app syncs to, read with a personal Sally API key.
/// POST https://sally.a1c.io/v1/skills/health_sync
/// Production should switch to an A1C-account token endpoint (see README).
struct SallyClient {
    let key: String
    var endpoint = URL(string: "https://sally.a1c.io/v1/skills/health_sync")!

    enum Failure: Error { case noKey, auth, server(String), noData }

    func fetch(now: Date = Date()) async throws -> Snapshot {
        guard !key.isEmpty else { throw Failure.noKey }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = .current
        let body: [String: Any] = [
            "date_from": df.string(from: now.addingTimeInterval(-7 * 86400)),
            "date_to": df.string(from: now),
            "include": ["vitals", "tir", "environment", "cgm_minute"],
            "cgm_minute_resolution": "5m",
        ]
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 20

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let h = resp as? HTTPURLResponse, h.statusCode == 401 || h.statusCode == 403 { throw Failure.auth }
        guard let j = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw Failure.server("bad json") }
        guard (j["ok"] as? Bool) == true, let d = j["data"] as? [String: Any] else {
            let msg = ((j["error"] as? [String: Any])?["message"] as? String) ?? "error"
            throw Failure.server(msg)
        }

        func rows(_ k: String) -> [[String: Any]] { (d[k] as? [[String: Any]]) ?? [] }
        func num(_ o: [String: Any], _ keys: [String]) -> Double? {
            for k in keys { if let n = o[k] as? NSNumber { return n.doubleValue } }
            return nil
        }
        // Backend can hold several rows per day; keep the fullest one.
        func bestPerDay(_ a: [[String: Any]], score: ([String: Any]) -> Double) -> [[String: Any]] {
            var m: [String: [String: Any]] = [:]
            for r in a {
                guard let date = r["date"] as? String else { continue }
                if let cur = m[date], score(cur) >= score(r) { continue }
                m[date] = r
            }
            return m.keys.sorted().compactMap { m[$0] }
        }

        let vitals = bestPerDay(rows("vitals")) { (num($0, ["total_steps"]) ?? 0) * 1000 + (num($0, ["readiness"]) ?? 0) }
        guard let v = vitals.last else { throw Failure.noData }
        let env = bestPerDay(rows("environment")) { num($0, ["time_in_daylight"]) ?? 0 }
        let e = env.first { ($0["date"] as? String) == (v["date"] as? String) } ?? env.last
        let today = df.string(from: now)
        let tir = rows("tir").first { ($0["date"] as? String) == today }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let iso2 = ISO8601DateFormatter()
        func parseDate(_ o: [String: Any]) -> Date? {
            for k in ["ts", "timestamp", "time", "datetime", "recorded_at"] {
                if let s = o[k] as? String, let dt = iso.date(from: s) ?? iso2.date(from: s) { return dt }
                if let n = o[k] as? NSNumber { let x = n.doubleValue; return Date(timeIntervalSince1970: x > 1e12 ? x / 1000 : x) }
            }
            return nil
        }
        let points = rows("cgm_minute").compactMap { r -> GlucosePoint? in
            guard let t = parseDate(r), let g = num(r, ["value", "glucose", "mg_dl", "sgv"]) else { return nil }
            return GlucosePoint(date: t, mgdl: g)
        }
        .filter { now.timeIntervalSince($0.date) <= 6 * 3600 }
        .sorted { $0.date < $1.date }

        return Snapshot(
            asOf: now,
            hasCGM: !points.isEmpty,
            points: points,
            bodyBattery: Int(num(v, ["body_energy"]) ?? 0),
            readiness: Int(num(v, ["readiness"]) ?? 0),
            steps: Int(num(v, ["total_steps"]) ?? 0),
            daylightMin: Int(num(e ?? [:], ["time_in_daylight"]) ?? 0),
            tirTodayPct: tir.flatMap { num($0, ["tir_optimal_daily_percentage"]) }.map { Int($0.rounded()) }
        )
    }
}
