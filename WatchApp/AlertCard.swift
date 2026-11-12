import SwiftUI

/// In-app version of an alert (the same text the push notification shows).
struct AlertCard: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) var dismiss
    let alert: GlucoseAlert

    var style: (icon: String, color: Color, eyebrow: String) {
        switch alert.kind {
        case .spike: return ("bolt.fill", A1CColor.danger, "Spike")
        case .rising: return ("arrow.up.right", A1CColor.warning, "Trend")
        case .falling: return ("arrow.down.right", A1CColor.blue300, "Trend")
        case .low: return ("exclamationmark", A1CColor.danger, "Low")
        case .spikeRecap: return ("chart.xyaxis.line", A1CColor.success, "Recap")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: style.icon).font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 20, height: 20).background(style.color, in: Circle())
                    Eyebrow(text: style.eyebrow, color: style.color)
                }
                Text(alert.title).font(A1CFont.display(20)).foregroundStyle(A1CColor.ultraWhite).lineLimit(2)
                Text(alert.body).font(A1CFont.body(13)).foregroundStyle(A1CColor.fgMuted)
                GlucoseSparkline(points: state.snapshot.last3h).frame(height: 30)
                if alert.kind == .spike || alert.kind == .rising {
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { state.showVoice = true }
                    } label: { Label("Log food", systemImage: "mic.fill") }
                    .buttonStyle(A1CPrimaryButton())
                    Button {
                        state.save(LogEntry(date: Date(), kind: .activity, text: "walk 10 min", summary: "Walk · 10 min", carbsG: nil, minutes: 10))
                        dismiss()
                    } label: { Label("Walk 10 min", systemImage: "figure.walk") }
                    .buttonStyle(A1CSecondaryButton())
                }
                if alert.kind == .falling || alert.kind == .low {
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { state.showVoice = true }
                    } label: { Label("Log snack", systemImage: "mic.fill") }
                    .buttonStyle(A1CPrimaryButton())
                }
                Button("Snooze 1 h") { dismiss() }.buttonStyle(A1CSecondaryButton())
                Text("Not for treatment decisions.").font(A1CFont.mono(9)).foregroundStyle(A1CColor.ink500)
            }
        }
        .background(A1CColor.royalBlack)
    }
}
