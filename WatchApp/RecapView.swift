import SwiftUI

struct RecapView: View {
    @EnvironmentObject var state: AppState
    var body: some View {
        let r = state.engine.recap(state.snapshot)
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: "Spike recap", color: A1CColor.blue300)
                if let r {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(r.peak)").font(A1CFont.display(36, "Light")).foregroundStyle(A1CColor.ultraWhite)
                        Text("peak mg/dL").font(A1CFont.mono(10)).foregroundStyle(A1CColor.fgMuted)
                    }
                }
                GlucoseGraph(points: state.snapshot.last3h).frame(height: 56)
                A1CCard {
                    VStack(spacing: 6) {
                        if let r {
                            row("Rise", "+\(state.alerts.last(where: { $0.kind == .spike })?.delta.map { Int($0) } ?? r.rise)")
                            row("Above 140", "\(r.minutesAbove) min")
                        }
                        row("Likely cause", state.logs.last(where: { $0.kind == .food })?.summary.components(separatedBy: ",").first ?? "Nasi padang")
                    }
                }
                Text("Full breakdown in A1C Insights on your phone.").font(A1CFont.body(11)).foregroundStyle(A1CColor.ink500)
            }
        }
        .background(A1CColor.royalBlack)
    }
    func row(_ k: String, _ v: String) -> some View {
        HStack {
            Eyebrow(text: k)
            Spacer()
            Text(v).font(A1CFont.body(13, .semibold)).foregroundStyle(A1CColor.ultraWhite).lineLimit(1)
        }
    }
}
