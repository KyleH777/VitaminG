<!-- GSD:project-start source:PROJECT.md -->
## Project

**Vitamin G**

Vitamin G is an iOS app for daily gratitude and tiered goal tracking. Users set goals across four tiers — from immediate wins to life goals — and receive a daily morning push notification reminding them of what they're working toward. It's "Vitamin G for Gratitude": a daily dose of intentionality.

**Core Value:** Every morning, the user is reminded of their goals — making progress feel inevitable, not accidental.

### Constraints

- **Tech Stack**: Swift, SwiftUI, SwiftData — no third-party dependencies unless necessary
- **Security**: All String inputs must have strict character limits and validation; local SwiftData storage must be treated as untrusted input boundary
- **Platform**: iOS 17+ minimum for SwiftData and modern SwiftUI APIs
- **Distribution**: Must meet App Store Review Guidelines — proper notification permissions, no background abuse
- **Architecture**: MVVM strictly enforced — no business logic in Views
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

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
## Key Framework Notes
### SwiftUI
### SwiftData
- All properties must be optional (`?`) or have default values. Non-optional properties without defaults silently prevent CloudKit sync.
- All relationships must be optional.
- Do not use `@Attribute(.unique)` on any property — CloudKit does not support atomic uniqueness checks across devices.
- Use `@Attribute(.externalStorage)` only for binary blobs (e.g., images). String and primitive fields do not need it.
### Observation Framework (`@Observable`)
### WidgetKit
- `systemSmall` / `systemMedium` — home screen widgets showing today's active goal count or top priority goal
- `accessoryRectangular` / `accessoryCircular` — lock screen widgets (iOS 16+) showing brief goal summary
- Call `WidgetCenter.shared.reloadAllTimelines()` every time the user creates, completes, or deletes a goal.
- Widgets cannot push data themselves — they read a snapshot at render time. The app must signal refresh.
### UserNotifications
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
## Dependency Policy
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
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd:quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd:debug` for investigation and bug fixing
- `/gsd:execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd:profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
