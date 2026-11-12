import UserNotifications

/// Local notifications for the POC. Production: backend sends APNs with the same category IDs.
enum Notifier {
    static let category = "GLUCOSE_ALERT"

    static func requestAuthorization() {
        let c = UNUserNotificationCenter.current()
        c.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        let log = UNNotificationAction(identifier: "LOG_FOOD", title: "Log food", options: [.foreground])
        let walk = UNNotificationAction(identifier: "WALK", title: "Walk 10 min", options: [])
        let snooze = UNNotificationAction(identifier: "SNOOZE", title: "Snooze 1 h", options: [])
        c.setNotificationCategories([UNNotificationCategory(identifier: category, actions: [log, walk, snooze],
                                                            intentIdentifiers: [], options: [])])
    }

    static func post(_ a: GlucoseAlert) {
        let content = UNMutableNotificationContent()
        content.title = a.title
        content.body = a.body
        content.categoryIdentifier = category
        content.sound = .default
        content.interruptionLevel = a.kind == .low ? .timeSensitive : .active
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: a.id.uuidString, content: content, trigger: nil))
    }
}
