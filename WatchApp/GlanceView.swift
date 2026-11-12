import SwiftUI

struct GlanceView: View {
    @EnvironmentObject var state: AppState
    var s: Snapshot { state.snapshot }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if s.hasCGM { glucoseHeader; GlucoseGraph(points: s.last3h).frame(height: 62) }
                scores
                Button { state.showVoice = true } label: {
                    Label("Log food or activity", systemImage: "mic.fill").font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .tint(A1CColor.inRange)
                .buttonStyle(.borderedProminent)
                if !s.hasCGM { goals }
                if let tir = s.tirTodayPct { Text("Time in range today \(tir)%").font(.footnote).foregroundStyle(.secondary) }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("A1C")
    }

    private var glucoseHeader: some View {
        let stale = s.isStale()
        let v = s.latest?.mgdl ?? 0
        return HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(Int(v))").font(.system(size: 44, weight: .bold, design: .rounded))
            VStack(alignment: .leading, spacing: 0) {
                Text(s.trend.arrow).font(.system(size: 22, weight: .bold))
                Text("mg/dL").font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            Text(stale ? "stale" : "\(s.ageMinutes() ?? 0)m").font(.footnote).foregroundStyle(.secondary)
        }
        .foregroundStyle(stale ? A1CColor.stale : A1CColor.glucose(v))
    }

    private var scores: some View {
        HStack(spacing: 10) {
            ScoreRing(label: "Battery", value: s.bodyBattery, color: A1CColor.battery)
            ScoreRing(label: "Ready", value: s.readiness, color: A1CColor.readiness)
        }
    }

    private var goals: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("\(s.steps.formatted()) steps", systemImage: "figure.walk")
            Label("\(s.daylightMin) min daylight", systemImage: "sun.max.fill")
        }
        .font(.footnote).frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ScoreRing: View {
    let label: String
    let value: Int
    let color: Color
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle().stroke(color.opacity(0.25), lineWidth: 6)
                Circle().trim(from: 0, to: CGFloat(value) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round)).rotationEffect(.degrees(-90))
                Text("\(value)").font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .frame(width: 50, height: 50)
            Text(label).font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
