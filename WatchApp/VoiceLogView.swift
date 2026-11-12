import SwiftUI

/// Voice logging: the TextField opens watchOS dictation (or Scribble / keyboard).
/// The text is parsed into a structured log and confirmed before saving.
struct VoiceLogView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) var dismiss
    @State private var text = ""

    let quick = ["Nasi + ayam", "Mie goreng", "Kopi susu", "Walk 10 min", "0Spike", "Water"]

    var body: some View {
        ScrollView {
            if let p = state.pendingLog {
                ConfirmCard(entry: p,
                            onSave: { state.save(p); dismiss() },
                            onEdit: { text = p.text; state.pendingLog = nil })
            } else {
                VStack(spacing: 8) {
                    Text("What did you eat or do?").font(.headline).multilineTextAlignment(.center)
                    TextField("Tap to speak", text: $text)
                        .onSubmit { parse() }
                    Text("e.g. \"nasi padang, setengah nasi\" or \"jalan 20 menit\"")
                        .font(.system(size: 11)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(quick, id: \.self) { q in
                            Button(q) { text = q; parse() }.font(.system(size: 12)).lineLimit(1)
                        }
                    }
                }
            }
        }
    }

    private func parse() {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        state.pendingLog = LogParser.parse(t)
    }
}

struct ConfirmCard: View {
    let entry: LogEntry
    let onSave: () -> Void
    let onEdit: () -> Void

    var icon: String {
        switch entry.kind {
        case .food: return "fork.knife"
        case .activity: return "figure.walk"
        case .water: return "drop.fill"
        case .supplement: return "leaf.fill"
        case .symptom: return "stethoscope"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(entry.kind.rawValue.capitalized, systemImage: icon).font(.footnote).foregroundStyle(.secondary)
            Text(entry.summary).font(.headline)
            if let c = entry.carbsG { Text("~\(c) g carbs").font(.footnote).foregroundStyle(A1CColor.high) }
            if let m = entry.minutes { Text("\(m) min").font(.footnote) }
            Text("\"\(entry.text)\"").font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(2)
            Button(action: onSave) { Text("Save").frame(maxWidth: .infinity) }
                .buttonStyle(.borderedProminent).tint(A1CColor.inRange)
            Button("Edit", action: onEdit)
        }
    }
}
