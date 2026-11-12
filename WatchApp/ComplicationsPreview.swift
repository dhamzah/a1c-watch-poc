import SwiftUI

/// Shows each complication family as it renders on a watch face, for demos and screenshots.
struct ComplicationsPreview: View {
    @EnvironmentObject var state: AppState
    var body: some View {
        let s = state.snapshot
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Watch face", color: A1CColor.blue300)
                HStack(spacing: 8) {
                    GlucoseCircular(s: s).frame(width: 50, height: 50)
                    ScoreCircular(label: "BB", value: s.bodyBattery, color: A1CColor.battery).frame(width: 50, height: 50)
                    ScoreCircular(label: "RD", value: s.readiness, color: A1CColor.readiness).frame(width: 50, height: 50)
                }
                .frame(maxWidth: .infinity)
                A1CCard { GlucoseRectangular(s: s) }
                GlucoseInline(s: s).font(A1CFont.mono(12)).foregroundStyle(A1CColor.ultraWhite)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(A1CColor.royalBlack)
    }
}
