import SwiftUI
import WidgetKit

/// Views shared by the real complications and the in-app preview screen.
struct GlucoseCircular: View {
    let s: Snapshot
    var body: some View {
        let stale = s.isStale()
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: -2) {
                Text(s.latest.map { "\(Int($0.mgdl))" } ?? "--")
                    .font(A1CFont.display(18))
                    .minimumScaleFactor(0.6)
                Text(stale ? "old" : s.trend.arrow)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(stale ? A1CColor.stale : A1CColor.glucose(s.latest?.mgdl ?? 100))
        }
        .widgetAccentable()
    }
}

struct GlucoseRectangular: View {
    let s: Snapshot
    var body: some View {
        let stale = s.isStale()
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(s.latest.map { "\(Int($0.mgdl))" } ?? "--").font(A1CFont.display(24))
                    Text(s.trend.arrow).font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(stale ? A1CColor.stale : A1CColor.glucose(s.latest?.mgdl ?? 100))
                Text(stale ? "No new reading" : "mg/dL · \(s.ageMinutes() ?? 0)m ago")
                    .font(A1CFont.mono(10)).foregroundStyle(A1CColor.fgMuted)
            }
            GlucoseSparkline(points: s.last3h).frame(maxWidth: .infinity, maxHeight: 34)
        }
    }
}

struct ScoreCircular: View {
    let label: String
    let value: Int
    let color: Color
    var body: some View {
        Gauge(value: Double(value), in: 0...100) {
            Text(label)
        } currentValueLabel: {
            Text("\(value)").font(A1CFont.display(16))
        }
        .gaugeStyle(.accessoryCircular)
        .tint(color)
    }
}

struct GlucoseInline: View {
    let s: Snapshot
    var body: some View {
        Text("\(s.latest.map { "\(Int($0.mgdl))" } ?? "--") \(s.trend.arrow) · BB \(s.bodyBattery)")
    }
}

/// Lightweight sparkline (no Charts dependency so it works in complications cheaply).
struct GlucoseSparkline: View {
    let points: [GlucosePoint]
    var t = Thresholds()
    var body: some View {
        GeometryReader { g in
            let vals = points.map(\.mgdl)
            let lo = min(vals.min() ?? 70, t.low - 10)
            let hi = max(vals.max() ?? 180, t.high + 20)
            let y: (Double) -> CGFloat = { v in g.size.height * CGFloat(1 - (v - lo) / (hi - lo)) }
            ZStack {
                Rectangle().fill(A1CColor.moroccanBlue.opacity(0.18))
                    .frame(height: max(1, y(t.low) - y(t.high)))
                    .position(x: g.size.width / 2, y: (y(t.low) + y(t.high)) / 2)
                Path { p in
                    for (i, v) in vals.enumerated() {
                        let pt = CGPoint(x: g.size.width * CGFloat(i) / CGFloat(max(1, vals.count - 1)), y: y(v))
                        i == 0 ? p.move(to: pt) : p.addLine(to: pt)
                    }
                }
                .stroke(A1CColor.glucose(vals.last ?? 100), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
    }
}
