import SwiftUI
import WatchKit
import WidgetKit

@main
struct A1CWatchApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var state = AppState.shared

    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(state)
        }
        .backgroundTask(.appRefresh("glucose")) {
            await AppState.shared.refresh(fromBackground: true)
            await scheduleNextRefresh()
        }
    }
}

/// Ask watchOS for a refresh in ~5 min (the system may stretch this; see README).
func scheduleNextRefresh() async {
    await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
        WKApplication.shared().scheduleBackgroundRefresh(withPreferredDate: Date().addingTimeInterval(5 * 60), userInfo: nil) { _ in
            c.resume()
        }
    }
}

final class AppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        Notifier.requestAuthorization()
        Task { await scheduleNextRefresh() }
    }
}
