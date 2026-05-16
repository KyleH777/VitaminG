# Stack Research: Vitamin G

**Project:** Vitamin G — iOS goal-tracking / daily gratitude app
**Researched (v1.0):** 2026-04-03
**Updated (v2.0):** 2026-05-15
**Minimum Deployment Target:** iOS 17.0

---

## v2.0 Stack Additions

New frameworks and capabilities required for the Social Growth Engine milestone. The existing stack (Swift, SwiftUI, SwiftData, CloudKit, WidgetKit, App Intents, UserNotifications, @Observable, App Groups, XCTest) is unchanged. Every item below is an Apple-first framework — no third-party dependencies required.

### v2.0 Framework Table

| Framework / Capability | iOS Min | Purpose | Entitlement / Capability Required | Confidence |
|------------------------|---------|---------|-----------------------------------|------------|
| StoreKit 2 (`Product`, `Transaction`) | iOS 15.0 | Tip Jar — consumable tiered in-app purchases | "In-App Purchase" capability in Xcode + App Store Connect products | HIGH |
| StoreKit 2 SwiftUI views (`ProductView`, `StoreView`) | iOS 17.0 | Native purchase UI that handles receipts and loading states automatically | Same as above | HIGH |
| CloudKit direct API (`CKDatabase`, `CKRecord`, `CKAsset`) | iOS 8.0 (effectively iOS 17 for this project) | Profile picture binary storage; unique username global check; live-presence timestamp writes | CloudKit entitlement (already active); no new capability needed | HIGH |
| CoreMotion (`CMMotionManager`) | iOS 4.0 | Shake gesture detection for daily gift gifter | NSMotionUsageDescription key in Info.plist (required iOS 17+) | HIGH |
| PhotosUI (`PHPickerViewController`) | iOS 14.0 | Photo library picker for profile picture — no photo library permission prompt required | NSCameraUsageDescription in Info.plist only if camera path is offered | HIGH |
| AVFoundation (`AVCaptureSession`, `AVCapturePhotoOutput`) | iOS 7.0 | In-app camera capture for profile photo | NSCameraUsageDescription key in Info.plist (mandatory) | HIGH |
| QuartzCore (`CAEmitterLayer`, `CAEmitterCell`) | iOS 5.0 | Confetti particle animation for achievement celebrations — no third-party needed | None | HIGH |
| SwiftUI `.preferredColorScheme()` + `@AppStorage` | iOS 17.0 | In-app dark mode override toggle stored per-user | None — pure SwiftUI API | HIGH |

---

### 1. StoreKit 2 — Tip Jar

**Use consumable IAPs, not non-consumable.** Tip jar tips are one-time value exchanges with no persistent state to restore. Non-consumable IAPs carry a "restore purchases" obligation and imply permanent unlocked content — inappropriate for tips. Use consumable products (Type: Consumable in App Store Connect).

**API pattern:**
```swift
// Fetch products
let products = try await Product.products(for: ["tip.small", "tip.medium", "tip.large"])

// Purchase
let result = try await product.purchase()
switch result {
case .success(let verification):
    let transaction = try verification.payloadValue
    await transaction.finish()  // required — otherwise purchase re-queues
case .userCancelled, .pending:
    break
@unknown default:
    break
}
```

**Why not `ProductView` / `StoreView`?** The SwiftUI `ProductView` (iOS 17+) is appropriate if the standard Apple-formatted purchase button is acceptable. For Vitamin G's custom tip jar UI with custom tier names and styling, build a custom view that calls `product.purchase()` directly. Use `ProductView` only if speed is prioritized over design control.

**Setup requirements:**
- Add "In-App Purchase" capability in Xcode (Signing & Capabilities)
- Create products in App Store Connect (Consumable type, 3 tiers)
- Use a `.storekit` configuration file in the scheme for local development testing without App Store Connect
- StoreKit 2 minimum is iOS 15.0 — compatible with the project's iOS 17 minimum with no guards needed

**Integration with existing stack:** StoreKit 2 has no SwiftData or CloudKit interaction. The tip state is managed entirely by StoreKit transaction history, not persisted in SwiftData. Do not store purchase records in SwiftData.

---

### 2. CloudKit Direct API — Profile Picture Storage

**Do not use SwiftData `@Attribute(.externalStorage)` for profile pictures synced to the public CloudKit database.** The SwiftData / CloudKit sync path only targets the private CloudKit database. Profile pictures belong on the public CloudKit database so other users can see them. Use the CloudKit direct API (`CKDatabase`, `CKRecord`, `CKAsset`) for this.

**Pattern for public DB image:**
```swift
// Write: save resized JPEG to temp file, attach as CKAsset
let imageData = image.jpegData(compressionQuality: 0.7)!
let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
try imageData.write(to: tempURL)
let asset = CKAsset(fileURL: tempURL)

let record = CKRecord(recordType: "UserProfile", recordID: CKRecord.ID(recordName: userRecordName))
record["avatarAsset"] = asset
record["username"] = username

let db = CKContainer.default().publicCloudDatabase
try await db.save(record)
```

**Image size discipline:** Resize and compress to a maximum of 200x200 px and JPEG quality 0.7 before creating the `CKAsset`. Raw camera images (3-10 MB) will be rejected by CloudKit's record size limits (1 MB per field) or cause severe upload latency. Use `UIGraphicsImageRenderer` to resize in-memory before writing to the temp file.

**Use `@Attribute(.externalStorage)` only for the private-database SwiftData path.** If a small local cache of the profile image is needed on-device (e.g., for offline display of the user's own avatar), store a `Data?` property with `@Attribute(.externalStorage)` in the SwiftData `UserProfile` model — this is compatible with CloudKit private DB sync. The public-facing avatar is a separate CKRecord write.

---

### 3. Unique Username Enforcement

There is no server-side unique constraint in CloudKit for the public database. The correct approach is application-level enforcement using a CKQuery check before committing.

**Pattern:**
```swift
let predicate = NSPredicate(format: "username == %@", candidateUsername)
let query = CKQuery(recordType: "UserProfile", predicate: predicate)
let db = CKContainer.default().publicCloudDatabase
let (matchResults, _) = try await db.records(matching: query, resultsLimit: 1)

if matchResults.isEmpty {
    // username is available — proceed to save
} else {
    // username is taken — show error
}
```

**Race condition acknowledgment:** Two users could pass the availability check simultaneously and both claim the same username. This is inherent to CloudKit's eventual consistency model without a true atomic compare-and-swap. Mitigate by:
1. Showing real-time availability feedback as the user types (debounced CKQuery)
2. Using the Apple ID-derived `CKRecord.ID` (stable, unique per user) as the canonical identity — username is display-only
3. Accepting that rare collisions are resolved by "first write wins" semantics and surfacing an error on the second write if the record already exists

Do not use `@Attribute(.unique)` — already banned per the existing stack constraints for CloudKit-synced models.

---

### 4. Live User Presence Simulation

CloudKit has no real-time presence protocol. The correct approach for this project (no backend server) is a **heartbeat timestamp heuristic**:

- Add a `lastActiveAt: Date?` field to the `UserProfile` CKRecord in the public database
- Write this timestamp to CloudKit when the user opens the app and on meaningful interactions (goal check-in, community feed view), throttled to at most once per 2 minutes to avoid CloudKit write quota abuse
- Read other users' `lastActiveAt` values when rendering the "Live users" section
- Display users as "live" if `lastActiveAt` is within the last 10 minutes

**This is a simulation, not true presence.** Users who force-quit the app will still appear online for up to 10 minutes. This is acceptable for this feature's purpose and is standard practice for serverless social apps. Label the UI as "Active recently" rather than "Online now" to set correct expectations.

**No additional framework is needed** — this is a CloudKit record write using the existing CloudKit direct API.

---

### 5. CoreMotion — Shake Gesture

**Why CoreMotion over UIKit's `motionEnded(_:with:)`?** The UIKit responder-chain shake detection (`motionEnded`) works but requires a UIViewController as first responder, which conflicts with the pure SwiftUI architecture. `CMMotionManager` integrates cleanly into a SwiftUI `@Observable` ViewModel.

**Pattern:**
```swift
import CoreMotion

@Observable
final class ShakeViewModel {
    private let motionManager = CMMotionManager()

    func startShakeDetection(onShake: @escaping () -> Void) {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { data, _ in
            guard let data else { return }
            let total = abs(data.acceleration.x) + abs(data.acceleration.y) + abs(data.acceleration.z)
            if total > 2.5 {  // threshold tuned for deliberate shake, not incidental movement
                onShake()
            }
        }
    }

    func stopShakeDetection() {
        motionManager.stopAccelerometerUpdates()
    }
}
```

**Info.plist requirement:** Add `NSMotionUsageDescription` with a user-facing explanation string. As of iOS 17, apps that access CoreMotion without this key crash at runtime.

**One `CMMotionManager` per app:** CoreMotion documentation states that apps should not create more than one `CMMotionManager` instance. Instantiate it once in a shared ViewModel or as a singleton accessed by the Explore tab ViewModel.

**Gate the gesture:** Only allow one shake reward per day. Persist the last shake date in `@AppStorage` or a SwiftData record. Check before starting the accelerometer listener.

---

### 6. Camera + Photo Picker — Profile Picture Upload

**Two separate paths, both needed:**

**Path A — Photo library (PHPickerViewController):**
- Use `PHPickerViewController` wrapped in `UIViewControllerRepresentable`
- Requires NO photo library permission prompt on iOS 14+. The system picker runs in a separate process and hands back only selected images
- No `NSPhotoLibraryUsageDescription` needed for read access via `PHPickerViewController`
- `PHPickerConfiguration` with `filter: .images` and `selectionLimit: 1`

**Path B — Camera (AVFoundation or UIImagePickerController):**
- `UIImagePickerController` with `sourceType: .camera` is the simplest path for a single photo capture. Wrap in `UIViewControllerRepresentable`
- `AVCaptureSession` is required only if custom camera UI is needed (live preview, filters). For a profile photo, `UIImagePickerController` is sufficient
- Mandatory: `NSCameraUsageDescription` key in Info.plist with a clear explanation

**Recommended flow:** Present a SwiftUI action sheet on "Edit Profile Photo" with two options: "Choose from Library" (PHPickerViewController) and "Take Photo" (UIImagePickerController). This avoids building a custom `AVCaptureSession` camera view, which has significant complexity and maintenance overhead.

**After selection:** Resize to 200x200 px using `UIGraphicsImageRenderer`, compress to JPEG at 0.7 quality, then upload via `CKAsset` as described in section 2.

**No third-party photo processing library is needed.** `UIGraphicsImageRenderer` handles all resize/crop operations natively.

---

### 7. Dark Mode Toggle

**Use `.preferredColorScheme()` applied at the root `WindowGroup` level.** Store the user's preference in `@AppStorage` as a raw string (`"light"`, `"dark"`, `"system"`).

**Pattern:**
```swift
@AppStorage("colorSchemePreference") private var colorSchemePreference = "system"

var resolvedScheme: ColorScheme? {
    switch colorSchemePreference {
    case "light": return .light
    case "dark":  return .dark
    default:      return nil  // nil = follow system
    }
}

// In WindowGroup body:
ContentView()
    .preferredColorScheme(resolvedScheme)
```

Passing `nil` to `preferredColorScheme` correctly defers to the system setting. This is the documented Apple-recommended approach.

**No new framework, no new capability, no Info.plist entry needed.** This is pure SwiftUI + AppStorage.

**Existing v1.0 note:** The existing stack already lists Dark Mode support as "App Store-quality polish." The v2.0 addition is the explicit in-app toggle surface (Settings page). The underlying mechanism does not change.

---

### 8. Confetti Animation

**Use `CAEmitterLayer` wrapped in `UIViewRepresentable`, not a third-party library.** `CAEmitterLayer` is a Core Animation primitive available since iOS 5. It is GPU-accelerated, produces higher frame rates than a pure SwiftUI `Canvas`/`TimelineView` approach for dense particle counts, and requires zero dependencies.

**Why not pure SwiftUI Canvas?** A `TimelineView` + `Canvas` confetti implementation works but is CPU-driven and drops frames on older A-series chips when rendering 150+ particles. `CAEmitterLayer` offloads particle physics to the GPU via Core Animation and is the right tool for celebration-style bursts.

**Why not ConfettiSwiftUI or Vortex?** Both are third-party Swift packages. This project has a no-third-party-dependencies policy. The `CAEmitterLayer` implementation is ~80 lines of code and produces equivalent visual quality.

**Implementation note:** Create a `UIView` subclass with a `CAEmitterLayer`, trigger it with `beginTime = CACurrentMediaTime()` and set `birthRate = 0` after 1 second to create a burst (not a continuous stream). Wrap in `UIViewRepresentable` and overlay on the celebration screen.

**No Info.plist entry, no entitlement, no capability needed.**

---

### 9. Enhanced Widgets with Interactive App Intents

This is already partially in scope per the existing stack (App Intents, iOS 17+). No new framework is needed. The v2.0 enhancement is adding more `AppIntent` conforming types for new widget interaction surfaces (e.g., check-in for today's goal from the widget).

**Pattern is unchanged from v1.0:**
```swift
struct CheckInGoalIntent: AppIntent {
    static var title: LocalizedStringResource = "Check In Goal"
    @Parameter(title: "Goal ID") var goalID: String

    func perform() async throws -> some IntentResult {
        // Write check-in via ModelContext or CloudKit
        return .result()
    }
}
```

Use `Button(intent: CheckInGoalIntent(goalID: goal.id))` inside the widget view.

---

## What NOT to Add in v2.0

| Technology | Avoid Because | Correct Alternative |
|------------|--------------|---------------------|
| RevenueCat / Qonversion (IAP SDKs) | Third-party dependency; StoreKit 2 covers all tip jar requirements natively | StoreKit 2 direct API |
| Firebase Realtime Database for presence | Adds non-Apple backend dependency, costs money, breaks the CloudKit-only architecture | CloudKit `lastActiveAt` heartbeat pattern |
| Multipeer Connectivity for presence | Peer-to-peer only, not cloud-based; doesn't work across users who aren't in proximity | CloudKit heartbeat |
| `MotionShakeView` / UIKit responder chain shake | Requires UIViewController first responder; incompatible with pure SwiftUI | CMMotionManager in ViewModel |
| UIImagePickerController for photo library | Deprecated; requires photo library permission; replaced by PHPickerViewController | PHPickerViewController |
| `@Attribute(.unique)` for username | Already banned — breaks CloudKit sync silently | CKQuery availability check |
| ConfettiSwiftUI, Vortex, or any particle library | Third-party package; policy violation | CAEmitterLayer UIViewRepresentable |
| Third-party camera SDKs | Over-engineered for a single profile photo; App Store review scrutiny on camera access | UIImagePickerController (camera) |
| Server-side presence backend | Out of scope; adds infra cost and complexity the architecture explicitly avoids | CloudKit heartbeat heuristic |

---

## Required Info.plist Additions for v2.0

| Key | Trigger | Sample String |
|-----|---------|---------------|
| `NSMotionUsageDescription` | CoreMotion shake gesture | "Vitamin G uses motion to detect shakes for the daily goal gifter feature." |
| `NSCameraUsageDescription` | Camera capture for profile photo | "Vitamin G uses the camera so you can take a profile picture." |

`NSPhotoLibraryUsageDescription` is NOT needed for `PHPickerViewController`-only photo library access (iOS 14+). Add it only if you add write access or target iOS 13.

---

## v2.0 Capability Changes

| Capability | Status | Notes |
|------------|--------|-------|
| In-App Purchase | NEW — add in Xcode Signing & Capabilities | Required for StoreKit 2 to connect to App Store |
| CloudKit | Already active | No change; public DB writes for profiles already in v1.0 |
| App Groups | Already active | No change |
| Background Modes (Remote Notifications) | Already active per v1.0 Phase 1 | No change |

---

## Version Requirements — v2.0 Additions

| Feature | Minimum iOS | Notes |
|---------|-------------|-------|
| StoreKit 2 (`Product`, `Transaction`) | iOS 15.0 | Well within iOS 17 project minimum |
| StoreKit 2 SwiftUI views (`ProductView`) | iOS 17.0 | Use only if custom tip UI is not needed |
| PHPickerViewController | iOS 14.0 | Within project minimum; no guards needed |
| CoreMotion `CMMotionManager` (accelerometer) | iOS 4.0 | NSMotionUsageDescription required in iOS 17+ |
| `CAEmitterLayer` confetti | iOS 5.0 | No version concern |
| `.preferredColorScheme()` | iOS 13.0 | Within project minimum |
| CloudKit direct API (`CKAsset`, `CKQuery`) | iOS 8.0 | Already in use in v1.0; no minimum concern |

---

## Existing v1.0 Stack (Unchanged)

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

## Key Framework Notes (v1.0 — Carried Forward)

### SwiftData

All properties must be optional (`?`) or have default values. Non-optional properties without defaults silently prevent CloudKit sync. All relationships must be optional. Do not use `@Attribute(.unique)` on any property. Use `@Attribute(.externalStorage)` only for binary blobs stored in the private DB path.

### CloudKit Schema Deployment

After development, the CloudKit schema must be manually promoted from Development to Production in CloudKit Console. Run `initializeCloudKitSchema` once during development via a debug flag.

### Observation Framework

Use `@Observable` for all ViewModels. Do not use `@StateObject`/`@ObservedObject` — those are `ObservableObject` patterns.

### Widget Refresh

Call `WidgetCenter.shared.reloadAllTimelines()` every time the user creates, completes, or deletes a goal. Widgets cannot push data themselves.

---

## Sources — v2.0

- [StoreKit 2 overview — Apple Developer Documentation](https://developer.apple.com/storekit/)
- [Implementing Consumable In-App Purchases with StoreKit 2 — Create with Swift](https://www.createwithswift.com/implementing-consumable-in-app-purchases-with-storekit-2/)
- [StoreKit 2 for In-App Purchases — BleepingSwift](https://bleepingswift.com/blog/storekit-2-in-app-purchases-subscriptions)
- [CKAsset — Apple Developer Documentation](https://developer.apple.com/documentation/cloudkit/ckasset)
- [Working with Images in CloudKit — Frozen Fire Studios / Medium](https://medium.com/frozen-fire-studios/working-with-images-in-cloudkit-1e3579c67558)
- [Can SwiftData @Model with .externalStorage be used with CloudKit? — Apple Developer Forums](https://developer.apple.com/forums/thread/751617)
- [CMMotionManager — Apple Developer Documentation](https://developer.apple.com/documentation/coremotion/cmmotionmanager)
- [NSMotionUsageDescription required iOS 17+ — Apple Developer Forums](https://developer.apple.com/forums/thread/762886)
- [PHPickerViewController — Apple Developer Documentation](https://developer.apple.com/documentation/PhotosUI/PHPickerViewController)
- [PHPickerViewController requires no photo library permission — Apple Developer Forums](https://developer.apple.com/forums/thread/694353)
- [NSCameraUsageDescription — Apple Developer Documentation](https://developer.apple.com/documentation/BundleResources/Information-Property-List/NSCameraUsageDescription)
- [Requesting authorization to capture and save media — Apple Developer Documentation](https://developer.apple.com/documentation/avfoundation/requesting-authorization-to-capture-and-save-media)
- [CAEmitterLayer — Apple Developer Documentation](https://developer.apple.com/documentation/quartzcore/caemitterlayer)
- [preferredColorScheme(_:) — Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/view/preferredcolorscheme(_:))
- [Reading and setting color scheme in SwiftUI — nil coalescing](https://nilcoalescing.com/blog/ReadingAndSettingColorSchemeInSwiftUI/)
- [Interactive Widgets with SwiftUI — Kodeco](https://www.kodeco.com/43771410-interactive-widgets-with-swiftui)
- [Explore enhancements to App Intents — WWDC23](https://developer.apple.com/videos/play/wwdc2023/10103/)

## Sources — v1.0 (Carried Forward)

- [Syncing SwiftData with CloudKit — Hacking with Swift](https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit)
- [How to sync SwiftData with iCloud — SwiftData by Example](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-sync-swiftdata-with-icloud)
- [How to access a SwiftData container from widgets — SwiftData by Example](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-access-a-swiftdata-container-from-widgets)
- [Fixing SwiftData & Core Data Sync: initializeCloudKitSchema — fatbobman](https://fatbobman.com/en/snippet/resolving-incomplete-icloud-data-sync-in-ios-development-using-initializecloudkitschema/)
- [Key Considerations Before Using SwiftData — fatbobman](https://fatbobman.com/en/posts/key-considerations-before-using-swiftdata/)
- [Designing Models for CloudKit Sync — fatbobman](https://fatbobman.com/en/snippet/rules-for-adapting-data-models-to-cloudkit/)
- [Adding interactivity to widgets and Live Activities — Apple Developer Documentation](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities)
