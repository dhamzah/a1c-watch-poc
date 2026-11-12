import SwiftUI

/// In-app version of an alert (the same text the push notification shows).
struct AlertCard: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) var dismiss
    let alert: GlucoseAlert

    var icon: (String, Color) {
        switch alert.kind {
        case .spike: return ("bolt.heart.fill", A1CColor.veryHigh)
        case .rising: return ("arrow.up.right.circle.fill", A1CColor.high)
        case .falling: return ("arrow.down.right.circle.fill", A1CColor.battery)
        case .low: return ("exclamationmark.circle.fill", A1CColor.low)
        case .spikeRecap: return ("chart.xyaxis.line", A1CColor.inRange)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon.0).foregroundStyle(icon.1).font(.title3)
                    Text(alert.title).font(.headline).lineLimit(2)
                }
                Text(alert.body).font(.footnote)
                GlucoseSparkline(points: state.snapshot.last3h).frame(height: 30)
                if alert.kind == .spike || alert.kind == .rising {
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { state.showVoice = true }
                    } label: { Label("Log food", systemImage: "mic.fill").frame(maxWidth: .infinity) }
                    .buttonStyle(.borderedProminent).tint(A1CColor.inRange)
                    Button {
                        state.save(LogEntry(date: Date(), kind: .activity, text: "walk 10 min", summary: "Walk · 10 min", carbsG: nil, minutes: 10))
                        dismiss()
                    } label: { Label("Walk 10 min", systemImage: "figure.walk").frame(maxWidth: .infinity) }
                }
                if alert.kind == .falling || alert.kind == .low {
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { state.showVoice = true }
                    } label: { Label("Log snack", systemImage: "mic.fill").frame(maxWidth: .infinity) }
                    .buttonStyle(.borderedProminent).tint(A1CColor.inRange)
                }
                Button("Snooze 1 h") { dismiss() }.foregroundStyle(.secondary)
                Text("Not for treatment decisions.").font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
    }
}
