import SwiftUI

struct RecapView: View {
    @EnvironmentObject var state: AppState
    var body: some View {
        let r = state.engine.recap(state.snapshot)
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Text("Spike recap").font(.headline)
                GlucoseGraph(points: state.snapshot.last3h).frame(height: 60)
                if let r {
                    row("Peak", "\(r.peak) mg/dL")
                    row("Rise", "+\(r.rise)")
                    row("Above 140", "\(r.minutesAbove) min")
                }
                row("Likely cause", state.logs.last(where: { $0.kind == .food })?.summary ?? "Nasi padang")
                Text("Full breakdown is in A1C Insights on your phone.").font(.system(size: 11)).foregroundStyle(.secondary)
            }
        }
    }
    func row(_ k: String, _ v: String) -> some View {
        HStack { Text(k).foregroundStyle(.secondary); Spacer(); Text(v).bold() }.font(.footnote)
    }
}
