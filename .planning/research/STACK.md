# Stack Research: Vitamin G

**Project:** Vitamin G — iOS goal-tracking / daily gratitude app
**Researched:** 2026-04-03
**Minimum Deployment Target:** iOS 17.0

---

## Recommended Stack

| Framework / Tool | Version / iOS Min | Purpose | Confidence |
|------------------|-------------------|---------|------------|
| Swift | 5.9+ (Xcode 15+) | Primary language | HIGH |
| SwiftUI | iOS 17+ | All UI — declarative, widget-native | HIGH |
| SwiftData | iOS 17+ | Local persistence with CloudKit-ready model layer | HIGH |
| CloudKit (private DB) | iOS 17+ | iCloud sync via SwiftData's `ModelConfiguration` | HIGH |
| WidgetKit | iOS 16+ (lock screen); iOS 17+ (interactive) | Home screen + lock screen widgets | HIGH |
| App Intents | iOS 17+ | Interactive widget buttons (mark goal complete) | HIGH |
| UserNotifications | iOS 10+; best practices apply to iOS 17 | Daily morning local push notifications | HIGH |
| Observation (`@Observable`) | iOS 17+ | MVVM ViewModel layer; replaces `ObservableObject` | HIGH |
| App Groups entitlement | N/A (Xcode capability) | Shared SwiftData container between app and widget | HIGH |
| XCTest | N/A | Unit tests for ViewModels and model validation | HIGH |

---

## Key Framework Notes

### SwiftUI

Use SwiftUI for every screen. It is the only UI framework with native integration with SwiftData (`@Query`), the `@Observable` macro, and WidgetKit. Do not mix UIKit into feature views — UIKit is only acceptable for the `UIApplicationDelegate` lifecycle hook if you need `AppDelegate` callbacks.

NavigationStack (iOS 16+) is the correct navigation primitive. Do not use the deprecated `NavigationView`. Use a route enum with `NavigationStack(path:)` for programmatic navigation.

iOS 17 made all widgets require a container background. Use `.containerBackground(for: .widget)` to handle both home screen and lock screen variants cleanly.

### SwiftData

SwiftData is the correct choice for this project. It is Swift-native, integrates directly with SwiftUI via `@Query`, and has CloudKit sync built into `ModelConfiguration`. The tradeoff is stability: iOS 18.0–18.1 had regressions (memory usage spikes, `@ModelActor` not triggering view refresh). As of iOS 18.2+ and 2025 builds, stability has improved. The project targets iOS 17+, so the code path must be tested on both iOS 17 and the latest iOS 18.x.

**Model annotation rules (required for CloudKit sync):**
- All properties must be optional (`?`) or have default values. Non-optional properties without defaults silently prevent CloudKit sync.
- All relationships must be optional.
- Do not use `@Attribute(.unique)` on any property — CloudKit does not support atomic uniqueness checks across devices.
- Use `@Attribute(.externalStorage)` only for binary blobs (e.g., images). String and primitive fields do not need it.

**ModelContainer setup pattern:**

```swift
// In App entry point
let schema = Schema([Goal.self])
let modelConfig = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false,
    groupContainer: .identifier("group.com.yourteam.vitaming"),  // App Group ID
    cloudKitDatabase: .private("iCloud.com.yourteam.vitaming")   // CloudKit container ID
)
let container = try! ModelContainer(for: schema, configurations: [modelConfig])
```

The same `groupContainer` identifier must be used in the WidgetExtension target to share the store.

**CloudKit schema deployment (critical for production):**
After development, the CloudKit schema must be manually promoted from Development to Production in CloudKit Console (Schema > Deploy Schema Changes). Skipping this step causes complete sync failure for App Store users. Additionally, run `initializeCloudKitSchema` once during development (via a debug flag, not in production builds) to force schema alignment. This is a Core Data API still required even when using SwiftData.

### Observation Framework (`@Observable`)

Use `@Observable` (iOS 17+) for all ViewModels, not `ObservableObject`/`@Published`. The `@Observable` macro provides surgical view updates — only the specific property accessed by a view triggers a re-render, not the entire object. This is a meaningful performance improvement for a list-heavy app.

**MVVM pattern with `@Observable`:**

```swift
@Observable
final class GoalListViewModel {
    var goals: [Goal] = []
    var isLoading = false

    func load(modelContext: ModelContext) { ... }
}
```

Views reference ViewModels via `@State` (owned) or passed as parameters. Do not use `@StateObject`/`@ObservedObject` — those are `ObservableObject` patterns and will not compile with `@Observable`.

### WidgetKit

**Two widget families for Vitamin G:**
- `systemSmall` / `systemMedium` — home screen widgets showing today's active goal count or top priority goal
- `accessoryRectangular` / `accessoryCircular` — lock screen widgets (iOS 16+) showing brief goal summary

**App Groups (required):** The widget extension is a separate process and cannot read the main app's SwiftData store directly. Both targets must share an App Group, and `ModelConfiguration` must reference the same group container identifier. Without this, the widget reads from a different database and shows stale or empty data.

**Widget refresh strategy:**
- Call `WidgetCenter.shared.reloadAllTimelines()` every time the user creates, completes, or deletes a goal.
- Widgets cannot push data themselves — they read a snapshot at render time. The app must signal refresh.

**Interactive widgets (iOS 17+):**
Use `AppIntentConfiguration` with a conforming `AppIntent` to allow users to mark a goal complete directly from the widget without opening the app. This is the correct modern API; the older `IntentConfiguration` / SiriKit Intents approach is deprecated for new widgets.

### UserNotifications

**Pattern:** Local notifications via `UNCalendarNotificationTrigger` with `repeats: true`. No push notification server is needed for this use case — the daily reminder is a repeating local alarm.

**Daily morning notification setup:**

```swift
let content = UNMutableNotificationContent()
content.title = "Good morning"
content.body = "You have X active goals today."
content.sound = .default

var dateComponents = DateComponents()
dateComponents.hour = 8   // user-configured hour
dateComponents.minute = 0

let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
let request = UNNotificationRequest(identifier: "daily-morning", content: content, trigger: trigger)
UNUserNotificationCenter.current().add(request)
```

Use a single request with identifier `"daily-morning"` so re-scheduling replaces the previous one rather than stacking duplicates.

**iOS system limit:** iOS keeps at most 64 scheduled local notifications per app. A single repeating `UNCalendarNotificationTrigger` counts as one slot. This app will never approach the limit, so no special scheduling manager is needed.

**Permission request:** Request authorization with `.alert`, `.badge`, and `.sound` options. Request at a contextually appropriate moment (not on first launch cold), ideally after the user sets their first goal. Handle `.denied` gracefully — the app must still function without notifications; missing notifications is a degraded experience, not an error.

**Background modes:** Local notifications do not require the Background Modes entitlement. Only remote/silent push notifications require it. Do not add the "Remote Notifications" background mode unless adding server-push features in a future phase.

---

## What NOT to Use

| Technology | Avoid Because | Use Instead |
|------------|--------------|-------------|
| Core Data | Verbose, Objective-C-heritage API; SwiftData is its Swift-native replacement and supports the same CloudKit sync path | SwiftData |
| UIKit (for feature views) | No `@Query` integration, no `@Observable` binding, requires manual bridge code | SwiftUI throughout |
| `ObservableObject` / `@Published` | iOS 17+ apps should use `@Observable` macro; ObservableObject causes whole-object invalidation, not property-level | `@Observable` macro |
| `NavigationView` | Deprecated in iOS 16; replaced by NavigationStack | `NavigationStack` |
| `@Attribute(.unique)` on CloudKit-synced properties | CloudKit does not support atomic uniqueness; using it silently breaks sync | Use application-level duplicate detection instead |
| Third-party persistence (Realm, GRDB, etc.) | Adds a dependency, conflicts with SwiftData/CloudKit integration | SwiftData |
| Firebase / non-Apple sync | Requires network backend, additional cost, privacy considerations; CloudKit is free, private, built-in | CloudKit via SwiftData |
| Push notification server | Overkill for a daily local alarm; adds backend infrastructure cost | `UNCalendarNotificationTrigger` (local) |
| SiriKit Intents (old widget configuration) | Deprecated for new widget targets in iOS 17+; requires separate Intents extension | App Intents framework |
| `IntentConfiguration` for widgets | Legacy widget API; superseded by `AppIntentConfiguration` | `AppIntentConfiguration` |
| Combine | Largely superseded by `@Observable` + Swift async/await for this app's needs | Swift async/await + `@Observable` |

---

## Version Requirements

| Feature | Minimum iOS | Notes |
|---------|-------------|-------|
| SwiftData (`@Model`, `@Query`, `ModelContainer`) | iOS 17.0 | Project minimum; do not back-deploy |
| `@Observable` macro | iOS 17.0 | Replaces `ObservableObject`; same minimum |
| CloudKit sync via `ModelConfiguration` | iOS 17.0 | `.cloudKitDatabase` parameter on `ModelConfiguration` |
| WidgetKit home screen widgets | iOS 14.0 | systemSmall/systemMedium/systemLarge families |
| WidgetKit lock screen widgets | iOS 16.0 | accessoryRectangular, accessoryCircular, accessoryInline |
| Interactive widgets via App Intents | iOS 17.0 | `AppIntentConfiguration`, `Button(intent:)` |
| `NavigationStack` | iOS 16.0 | Programmatic navigation with route enum |
| `UNCalendarNotificationTrigger` (local) | iOS 10.0 | No minimum version concern for this project |
| `.containerBackground(for: .widget)` | iOS 17.0 | Required for all widgets on iOS 17+; use from day one |
| App Groups shared container | N/A | Xcode capability; no iOS version constraint |

---

## Dependency Policy

**Zero third-party dependencies** unless a specific, well-scoped gap is identified. The Apple frameworks listed above cover all v1 requirements. This keeps the project auditable, avoids App Store rejection risks from third-party licensing, and aligns with the project's constraint of "no third-party dependencies unless necessary."

If a third-party library is evaluated in a future phase, it must meet these criteria:
1. Actively maintained with a public release in the last 6 months
2. MIT or Apache 2.0 license
3. Available as a Swift Package (no CocoaPods)
4. Solves a problem that cannot be solved with Apple frameworks within reasonable effort

---

## Sources

- [Syncing SwiftData with CloudKit — Hacking with Swift](https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit)
- [How to sync SwiftData with iCloud — SwiftData by Example](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-sync-swiftdata-with-icloud)
- [How to access a SwiftData container from widgets — SwiftData by Example](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-access-a-swiftdata-container-from-widgets)
- [Fixing SwiftData & Core Data Sync: initializeCloudKitSchema — fatbobman](https://fatbobman.com/en/snippet/resolving-incomplete-icloud-data-sync-in-ios-development-using-initializecloudkitschema/)
- [Key Considerations Before Using SwiftData — fatbobman](https://fatbobman.com/en/posts/key-considerations-before-using-swiftdata/)
- [Designing Models for CloudKit Sync — fatbobman](https://fatbobman.com/en/snippet/rules-for-adapting-data-models-to-cloudkit/)
- [SwiftData ModelContainer fails — Apple Developer Forums](https://developer.apple.com/forums/thread/769329)
- [SwiftData iOS 18 memory issues — Apple Developer Forums](https://developer.apple.com/forums/thread/761522)
- [ModelConfiguration.GroupContainer — Apple Developer Documentation](https://developer.apple.com/documentation/swiftdata/modelconfiguration/groupcontainer-swift.struct)
- [Adding interactivity to widgets and Live Activities — Apple Developer Documentation](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities)
- [Lock Screen Widgets in SwiftUI — Swift with Majid](https://swiftwithmajid.com/2022/08/30/lock-screen-widgets-in-swiftui/)
- [Migrating from ObservableObject to Observable — Apple Developer Documentation](https://developer.apple.com/documentation/SwiftUI/Migrating-from-the-observable-object-protocol-to-the-observable-macro)
- [UNUserNotificationCenter — Apple Developer Documentation](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter)
- [UNCalendarNotificationTrigger — Apple Developer Documentation](https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger)
- [Sync SwiftData with iCloud using CloudKit — Medium / Jakir Hossain](https://medium.com/@jakir/sync-swiftdata-with-icloud-using-cloudkit-34764a46ba54)
- [SwiftData with Widgets in SwiftUI — Medium / Rishabh Sharma](https://medium.com/@rishixcode/swiftdata-with-widgets-in-swiftui-0aab327a35d8)
- [How to Build a Configurable SwiftUI Widget with App Intents and SwiftData — Medium / Alexander Adelmaer](https://medium.com/app-makers/how-to-build-a-configurable-swiftui-widget-with-app-intents-and-swiftdata-e4db410cfd12)
