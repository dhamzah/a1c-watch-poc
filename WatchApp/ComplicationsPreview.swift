import SwiftUI

/// Shows each complication family as it renders on a watch face, for demos and screenshots.
struct ComplicationsPreview: View {
    @EnvironmentObject var state: AppState
    var body: some View {
        let s = state.snapshot
        ScrollView {
            VStack(spacing: 10) {
                Text("Complications").font(.headline)
                HStack(spacing: 10) {
                    GlucoseCircular(s: s).frame(width: 50, height: 50)
                    ScoreCircular(label: "BB", value: s.bodyBattery, color: A1CColor.battery).frame(width: 50, height: 50)
                    ScoreCircular(label: "RD", value: s.readiness, color: A1CColor.readiness).frame(width: 50, height: 50)
                }
                GlucoseRectangular(s: s)
                    .padding(6).background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                GlucoseInline(s: s).font(.footnote)
            }
        }
    }
}
