import SwiftUI
import WidgetKit

/// Launch arguments used by the screenshot script:
///   -screen glance|rising|spike|voice|confirm|recap|complications|nocgm|settings
enum DemoScreen: String { case glance, rising, spike, voice, confirm, recap, complications, nocgm, settings }

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var snapshot: Snapshot = DemoData.snapshot()
    @Published var activeAlert: GlucoseAlert?
    @Published var alerts: [GlucoseAlert] = []
    @Published var logs: [LogEntry] = SharedStore.logs
    @Published var pendingLog: LogEntry?
    @Published var showVoice = false
    @Published var showRecap = false
    @Published var showSettings = false
    @Published var showComplications = false
    @Published var lastError: String?

    let engine = AlertEngine()
    let demoScreen: DemoScreen? = {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-screen"), i + 1 < args.count else { return nil }
        return DemoScreen(rawValue: args[i + 1])
    }()

    init() { applyDemoScreen() }

    func refresh(fromBackground: Bool = false) async {
        if demoScreen != nil { return }
        let s = await SharedStore.loadSnapshot()
        snapshot = s
        let new = engine.evaluate(s, recent: alerts, logs: logs)
        for a in new {
            alerts.append(a)
            Notifier.post(a)
            if !fromBackground { activeAlert = a }
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    func save(_ entry: LogEntry) {
        logs.append(entry)
        SharedStore.logs = logs
        pendingLog = nil
        // Re-label an open spike with the food that explains it.
        if entry.kind == .food, let a = activeAlert, a.kind == .spike {
            activeAlert = GlucoseAlert(kind: .spike, date: a.date, mgdl: a.mgdl, delta: a.delta,
                                       title: "Spike after \(entry.summary.components(separatedBy: ",").first ?? entry.summary)",
                                       body: "Logged. A 10-min walk now helps it come down.")
        }
    }

    private func applyDemoScreen() {
        guard let d = demoScreen else { return }
        let now = Date()
        switch d {
        case .glance:
            snapshot = DemoData.snapshot(now: now.addingTimeInterval(120))
        case .rising:
            snapshot = DemoData.risingSnapshot(now: now)
            activeAlert = engine.evaluate(snapshot, recent: [], logs: []).first { $0.kind == .rising }
                ?? GlucoseAlert(kind: .rising, date: now, mgdl: snapshot.latest?.mgdl ?? 134, delta: 2.4,
                                title: "Rising fast", body: "134 and climbing about 2.4 per min. Log what you ate, or take a short walk.")
        case .spike:
            snapshot = DemoData.snapshot(now: now)
            activeAlert = GlucoseAlert(kind: .spike, date: now, mgdl: 168, delta: 74,
                                       title: "Spike to 168", body: "168 mg/dL, +74 in the last hour. What did you eat?")
        case .voice:
            snapshot = DemoData.snapshot(now: now)
            showVoice = true
        case .confirm:
            snapshot = DemoData.snapshot(now: now)
            pendingLog = LogParser.parse("nasi padang setengah nasi, rendang, es teh manis", at: now)
            showVoice = true
        case .recap:
            snapshot = DemoData.snapshot(now: now)
            showRecap = true
        case .complications:
            snapshot = DemoData.snapshot(now: now)
            showComplications = true
        case .nocgm:
            snapshot = DemoData.noCGMSnapshot(now: now)
        case .settings:
            showSettings = true
        }
    }
}
