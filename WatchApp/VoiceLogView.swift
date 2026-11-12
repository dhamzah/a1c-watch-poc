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
                VStack(alignment: .leading, spacing: 8) {
                    Eyebrow(text: "Log", color: A1CColor.blue300)
                    Text("What did you eat or do?").font(A1CFont.display(19)).foregroundStyle(A1CColor.ultraWhite)
                    TextField("Tap to speak", text: $text)
                        .onSubmit { parse() }
                    Text("e.g. \"nasi padang, setengah nasi\" or \"jalan 20 menit\"")
                        .font(A1CFont.body(11)).foregroundStyle(A1CColor.fgMuted)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(quick, id: \.self) { q in
                            Button(q) { text = q; parse() }.buttonStyle(A1CSecondaryButton()).lineLimit(1)
                        }
                    }
                }
            }
        }
        .background(A1CColor.royalBlack)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 10)).foregroundStyle(A1CColor.blue300)
                Eyebrow(text: entry.kind.rawValue, color: A1CColor.blue300)
            }
            Text(entry.summary).font(A1CFont.display(18)).foregroundStyle(A1CColor.ultraWhite)
            HStack(spacing: 6) {
                if let c = entry.carbsG { chip("~\(c) g carbs", A1CColor.warning) }
                if let m = entry.minutes { chip("\(m) min", A1CColor.success) }
            }
            Text("\"\(entry.text)\"").font(A1CFont.body(11)).foregroundStyle(A1CColor.fgMuted).lineLimit(2)
            Button("Save", action: onSave).buttonStyle(A1CPrimaryButton())
            Button("Edit", action: onEdit).buttonStyle(A1CSecondaryButton())
        }
    }

    func chip(_ s: String, _ c: Color) -> some View {
        Text(s).font(A1CFont.mono(11, .semibold)).foregroundStyle(c)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(c.opacity(0.14), in: Capsule())
    }
}
