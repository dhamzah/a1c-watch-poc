import SwiftUI
import Charts

struct GlucoseGraph: View {
    let points: [GlucosePoint]
    var t = Thresholds()

    var body: some View {
        Chart {
            if let first = points.first, let last = points.last {
                RectangleMark(xStart: .value("Start", first.date), xEnd: .value("End", last.date),
                              yStart: .value("Low", t.low), yEnd: .value("High", t.high))
                    .foregroundStyle(A1CColor.moroccanBlue.opacity(0.14))
            }
            ForEach(points, id: \.date) { p in
                LineMark(x: .value("Time", p.date), y: .value("mg/dL", p.mgdl))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(A1CColor.ultraWhite)
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
            if let last = points.last {
                PointMark(x: .value("Time", last.date), y: .value("mg/dL", last.mgdl))
                    .foregroundStyle(A1CColor.glucose(last.mgdl)).symbolSize(50)
            }
        }
        .chartYScale(domain: 60...200)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(values: [70, 140]) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3])).foregroundStyle(A1CColor.border)
                AxisValueLabel().font(A1CFont.mono(9)).foregroundStyle(A1CColor.fgMuted)
            }
        }
    }
}
