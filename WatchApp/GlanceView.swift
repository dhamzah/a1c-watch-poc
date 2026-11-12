import SwiftUI

struct GlanceView: View {
    @EnvironmentObject var state: AppState
    var s: Snapshot { state.snapshot }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if s.hasCGM {
                    glucoseHeader
                    GlucoseGraph(points: s.last3h).frame(height: 58)
                }
                scores
                Button { state.showVoice = true } label: {
                    Label("Log food or activity", systemImage: "mic.fill")
                }
                .buttonStyle(A1CPrimaryButton())
                if !s.hasCGM { goals }
                if let tir = s.tirTodayPct {
                    HStack { Eyebrow(text: "Time in range today"); Spacer()
                        Text("\(tir)%").font(A1CFont.mono(12, .semibold)).foregroundStyle(A1CColor.inRange) }
                }
            }
            .padding(.horizontal, 4)
        }
        .background(A1CColor.royalBlack)
    }

    private var glucoseHeader: some View {
        let stale = s.isStale()
        let v = s.latest?.mgdl ?? 0
        let c = stale ? A1CColor.stale : A1CColor.glucose(v)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 5) {
                Circle().fill(c).frame(width: 6, height: 6)
                Eyebrow(text: stale ? "No new reading" : "Glucose · \(s.ageMinutes() ?? 0)m ago")
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(Int(v))").font(A1CFont.display(50, "Light")).foregroundStyle(A1CColor.ultraWhite)
                VStack(alignment: .leading, spacing: 0) {
                    Text(s.trend.arrow).font(.system(size: 20, weight: .semibold)).foregroundStyle(c)
                    Text("mg/dL").font(A1CFont.mono(10)).foregroundStyle(A1CColor.fgMuted)
                }
            }
        }
    }

    private var scores: some View {
        HStack(spacing: 8) {
            ScoreRing(label: "Battery", value: s.bodyBattery, color: A1CColor.battery)
            ScoreRing(label: "Readiness", value: s.readiness, color: A1CColor.readiness)
        }
    }

    private var goals: some View {
        A1CCard {
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: "Today")
                Label("\(s.steps.formatted()) steps", systemImage: "figure.walk")
                Label("\(s.daylightMin) min daylight", systemImage: "sun.max.fill")
            }
            .font(A1CFont.body(14)).foregroundStyle(A1CColor.ultraWhite)
        }
    }
}

struct ScoreRing: View {
    let label: String
    let value: Int
    let color: Color
    var body: some View {
        A1CCard {
            VStack(spacing: 4) {
                ZStack {
                    Circle().stroke(Color.white.opacity(0.08), lineWidth: 5)
                    Circle().trim(from: 0, to: CGFloat(value) / 100)
                        .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round)).rotationEffect(.degrees(-90))
                    Text("\(value)").font(A1CFont.display(18)).foregroundStyle(A1CColor.ultraWhite)
                }
                .frame(width: 44, height: 44)
                Eyebrow(text: label)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
