import SwiftUI

@main
struct VGWatchApp: App {

    init() {
        // Activate WCSession at the earliest possible point so the session is ready
        // before any view renders (RESEARCH.md Pitfall 1 — cold launch from complication tap).
        WatchReceiver.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            VGWatchContentView()
        }
    }
}
