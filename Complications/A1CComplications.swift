import SwiftUI
import WidgetKit

struct Entry: TimelineEntry {
    let date: Date
    let snapshot: Snapshot
}

/// Timeline: one entry now, plus "age" entries every 5 min so a missing reading greys out after 15 min.
/// The watch app calls WidgetCenter.reloadAllTimelines() after each fetch; watchOS rations reloads,
/// so real-world freshness is ~5–15 min (see README).
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { Entry(date: Date(), snapshot: DemoData.snapshot()) }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(Entry(date: Date(), snapshot: SharedStore.lastSnapshot ?? DemoData.snapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        Task {
            let s = await SharedStore.loadSnapshot()
            let now = Date()
            let entries = (0..<4).map { Entry(date: now.addingTimeInterval(Double($0) * 300), snapshot: s) }
            completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(300))))
        }
    }
}

struct GlucoseComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "io.a1c.glucose", provider: Provider()) { e in
            GlucoseEntryView(entry: e).containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Glucose")
        .description("Current glucose and trend.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

struct GlucoseEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: Entry
    var body: some View {
        switch family {
        case .accessoryRectangular: GlucoseRectangular(s: entry.snapshot)
        case .accessoryInline: GlucoseInline(s: entry.snapshot)
        case .accessoryCorner:
            Text(entry.snapshot.latest.map { "\(Int($0.mgdl))" } ?? "--")
                .widgetLabel { Text(entry.snapshot.trend.arrow) }
        default: GlucoseCircular(s: entry.snapshot)
        }
    }
}

struct BodyBatteryComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "io.a1c.bodybattery", provider: Provider()) { e in
            ScoreCircular(label: "BB", value: e.snapshot.bodyBattery, color: A1CColor.battery)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Body Battery")
        .supportedFamilies([.accessoryCircular])
    }
}

struct ReadinessComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "io.a1c.readiness", provider: Provider()) { e in
            ScoreCircular(label: "RD", value: e.snapshot.readiness, color: A1CColor.readiness)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Readiness")
        .supportedFamilies([.accessoryCircular])
    }
}

@main
struct A1CComplicationsBundle: WidgetBundle {
    var body: some Widget {
        GlucoseComplication()
        BodyBatteryComplication()
        ReadinessComplication()
    }
}
