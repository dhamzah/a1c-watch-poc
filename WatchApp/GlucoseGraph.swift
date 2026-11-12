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
                    .foregroundStyle(A1CColor.inRange.opacity(0.15))
            }
            ForEach(points, id: \.date) { p in
                LineMark(x: .value("Time", p.date), y: .value("mg/dL", p.mgdl))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(A1CColor.glucose(points.last?.mgdl ?? 100))
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
            }
            if let last = points.last {
                PointMark(x: .value("Time", last.date), y: .value("mg/dL", last.mgdl))
                    .foregroundStyle(A1CColor.glucose(last.mgdl)).symbolSize(40)
            }
        }
        .chartYScale(domain: 60...200)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(values: [70, 140]) { _ in AxisGridLine(); AxisValueLabel() }
        }
    }
}
