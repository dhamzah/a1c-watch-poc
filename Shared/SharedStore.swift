import Foundation

/// Settings + last snapshot shared between the watch app and the complications
/// through an App Group. Falls back to standard defaults when the group is not available
/// (e.g. unsigned simulator builds).
enum SharedStore {
    static let groupID = "group.io.a1c.watch.poc"
    static var defaults: UserDefaults { UserDefaults(suiteName: groupID) ?? .standard }

    static var source: DataSource {
        get { DataSource(rawValue: defaults.string(forKey: "source") ?? "") ?? .demo }
        set { defaults.set(newValue.rawValue, forKey: "source") }
    }

    /// POC only: a personal sk-sally key. Production replaces this with A1C account sign-in.
    static var sallyKey: String {
        get { defaults.string(forKey: "sallyKey") ?? "" }
        set { defaults.set(newValue, forKey: "sallyKey") }
    }

    static var lastSnapshot: Snapshot? {
        get {
            guard let d = defaults.data(forKey: "snapshot") else { return nil }
            return try? JSONDecoder().decode(Snapshot.self, from: d)
        }
        set { defaults.set(try? JSONEncoder().encode(newValue), forKey: "snapshot") }
    }

    static var logs: [LogEntry] {
        get {
            guard let d = defaults.data(forKey: "logs") else { return [] }
            return (try? JSONDecoder().decode([LogEntry].self, from: d)) ?? []
        }
        set { defaults.set(try? JSONEncoder().encode(newValue), forKey: "logs") }
    }

    static func loadSnapshot() async -> Snapshot {
        switch source {
        case .demo:
            return DemoData.snapshot()
        case .sally:
            do {
                let s = try await SallyClient(key: sallyKey).fetch()
                lastSnapshot = s
                return s
            } catch {
                return lastSnapshot ?? DemoData.snapshot()
            }
        }
    }
}
