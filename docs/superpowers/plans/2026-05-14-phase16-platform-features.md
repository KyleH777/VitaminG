# Phase 16: Platform Features Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a systemSmall StandBy-ready widget, an interactive lock screen widget that completes goals via AppIntents, and Claude Haiku photo moderation that screens community photos before posting.

**Architecture:** The systemSmall widget reuses existing `GoalSummaryProvider` and `WidgetDataProvider` data — it's a new view only. The interactive lock screen widget uses `AppIntents` (iOS 17+) with a new `CompleteTopGoalIntent` that writes directly to the shared App Group SwiftData store. Photo moderation is a standalone async service that calls the Anthropic Messages API over URLSession — no third-party SDK required.

**Tech Stack:** SwiftUI, WidgetKit, AppIntents (iOS 17+), SwiftData, URLSession, Anthropic Messages API (`claude-haiku-4-5-20251001`)

**Prerequisites:** Phase 15 complete. App Group entitlement (`group.com.kyleharrington.VitaminG`) already on both targets.

---

## File Map

| Action | File | Change |
|--------|------|--------|
| Modify | `VitaminGWidget/GoalSummaryWidget.swift` | Add systemSmall view + family support |
| Create | `VitaminGWidget/Intents/CompleteTopGoalIntent.swift` | AppIntent for one-tap lock screen completion |
| Modify | `VitaminGWidget/StreakWidget.swift` | Add interactive Button(intent:) for lock screen |
| Modify | `VitaminGWidget/VitaminGWidgetBundle.swift` | Register new widget if split out |
| Create | `VitaminG/Services/PhotoModerationService.swift` | Claude Haiku image safety check |
| Modify | `VitaminG/Views/PostComposeSheet.swift` | Integrate moderation before post submit |
| Modify | `VitaminG/VitaminG-Info.plist` | Add ANTHROPIC_API_KEY key |
| Create | `Secrets.xcconfig` | API key (gitignored) |

---

### Task 1: systemSmall StandBy Widget

**Files:**
- Modify: `VitaminGWidget/GoalSummaryWidget.swift`

Note: both existing widgets already have `.containerBackground(.fill.tertiary, for: .widget)` — iOS 17 StandBy picks up any widget that uses this modifier. No StandBy-specific API is needed. This task just adds the `systemSmall` family so there's a compact widget iOS can surface in StandBy rotation.

- [ ] **Step 1: Create SmallGoalWidgetView**

In `GoalSummaryWidget.swift`, add a new view struct after `GoalSummaryWidgetView`:

```swift
// MARK: - SmallGoalWidgetView

struct SmallGoalWidgetView: View {
    let entry: GoalEntry

    private var topGoalTitle: String? {
        entry.displayData.tierRows
            .first(where: { $0.topGoalTitle != nil })?
            .topGoalTitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Streak
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.caption2)
                    .foregroundStyle(Color(uiColor: UIColor { t in
                        t.userInterfaceStyle == .dark
                            ? UIColor(red: 1.0, green: 0.541, blue: 0.361, alpha: 1)
                            : UIColor(red: 0.769, green: 0.404, blue: 0.227, alpha: 1)
                    }))
                Text("\(entry.displayData.globalStreak) day streak")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Consistency Score (large)
            VStack(alignment: .leading, spacing: 0) {
                Text("Consistency")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text("\(entry.displayData.consistencyScore)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(uiColor: UIColor { t in
                            t.userInterfaceStyle == .dark
                                ? UIColor(red: 0.584, green: 0.839, blue: 0.612, alpha: 1)
                                : UIColor(red: 0.478, green: 0.620, blue: 0.494, alpha: 1)
                        }))
                    Text("%")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Top goal name
            if let title = topGoalTitle {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            } else {
                Text("No active goals")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
```

- [ ] **Step 2: Add consistencyScore to WidgetDisplayData**

`SmallGoalWidgetView` references `entry.displayData.consistencyScore`. Open `VitaminGWidget/WidgetTimelineEntry.swift` (or wherever `WidgetDisplayData` is defined) and add the field:

```swift
// In WidgetDisplayData struct, add:
var consistencyScore: Int
```

Update `WidgetDisplayData.placeholder` and `WidgetDisplayData.empty` to include `consistencyScore: 0`.

Then in `WidgetDataProvider.build(goals:events:)`, compute and include the score:

```swift
// In WidgetDataProvider.build, add:
let consistencyScore = ConsistencyEngine.score(events: events)
// Include in the returned WidgetDisplayData:
return WidgetDisplayData(
    tierRows: tierRows,
    globalStreak: globalStreak,
    consistencyScore: consistencyScore
)
```

`ConsistencyEngine` must be accessible from the widget target. Add `ConsistencyEngine.swift` to the `VitaminGWidget` target in Xcode: select the file in the Project Navigator → File Inspector → enable `VitaminGWidget` checkbox under Target Membership.

- [ ] **Step 3: Update GoalSummaryWidget to support systemSmall**

In `GoalSummaryWidget.swift`, update the `body` configuration to serve different views per family:

```swift
struct GoalSummaryWidget: Widget {
    let kind = "GoalSummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GoalSummaryProvider()) { entry in
            GoalSummaryWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Goals")
        .description("See your top goal for each tier at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// Entry view that routes by family
struct GoalSummaryWidgetEntryView: View {
    let entry: GoalEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallGoalWidgetView(entry: entry)
        default:
            GoalSummaryWidgetView(entry: entry)
        }
    }
}
```

Update the existing `StaticConfiguration` closure to use `GoalSummaryWidgetEntryView` instead of `GoalSummaryWidgetView` directly.

- [ ] **Step 4: Build widget target**

```
Xcode → select VitaminGWidget scheme → Cmd+B
```

Resolve any compile errors (typically: `ConsistencyEngine` not in widget target, or `WidgetDisplayData` missing field).

- [ ] **Step 5: Test in Simulator**

Long-press home screen → Add Widget → VitaminG. Confirm the Small size shows the Consistency Score, streak, and top goal name. Confirm the Medium size still shows the tier rows.

- [ ] **Step 6: Commit**

```bash
git add VitaminGWidget/GoalSummaryWidget.swift VitaminGWidget/WidgetTimelineEntry.swift VitaminG/Services/ConsistencyEngine.swift
git commit -m "feat: add systemSmall widget with Consistency Score for StandBy mode"
```

---

### Task 2: CompleteTopGoalIntent — AppIntents

**Files:**
- Create: `VitaminGWidget/Intents/CompleteTopGoalIntent.swift`

`AppIntents` lets a widget button perform a write action without opening the app. The intent fetches the highest-priority incomplete goal from the shared App Group store and logs a `CompletionEvent`.

- [ ] **Step 1: Create the Intents folder and intent file**

Create folder `VitaminGWidget/Intents/` and file `CompleteTopGoalIntent.swift`:

```swift
import AppIntents
import SwiftData
import WidgetKit

// MARK: - CompleteTopGoalIntent

/// Logs a CompletionEvent for the user's top incomplete goal.
/// Triggered from the interactive lock screen widget button (iOS 17+).
///
/// "Top" = first incomplete goal sorted by tier priority (Life → Year → Month → Week)
/// then by creation date ascending.
struct CompleteTopGoalIntent: AppIntent {

    static var title: LocalizedStringResource = "Complete Top Goal"
    static var description = IntentDescription("Marks your highest-priority goal as complete for today.")

    func perform() async throws -> some IntentResult {
        let container = try ModelContainerFactory.makeWidgetContainer()
        let context = ModelContext(container)

        let goals = try context.fetch(FetchDescriptor<Goal>())
        let events = try context.fetch(FetchDescriptor<CompletionEvent>())

        let today = Calendar.current.startOfDay(for: .now)
        let completedGoalIDs: Set<PersistentIdentifier> = Set(
            events.compactMap { e -> PersistentIdentifier? in
                guard let date = e.completedAt,
                      Calendar.current.isDate(date, inSameDayAs: today),
                      let goal = e.goal else { return nil }
                return goal.id
            }
        )

        // Tier priority order: lifeGoal (0) > longTerm (1) > shortTerm (2) > immediate (3)
        let tierOrder: [GoalTier] = [.lifeGoal, .longTerm, .shortTerm, .immediate]
        let topGoal = goals
            .filter { !($0.isCompleted) && !completedGoalIDs.contains($0.id) }
            .sorted { a, b in
                let aIndex = tierOrder.firstIndex(of: a.tier) ?? 99
                let bIndex = tierOrder.firstIndex(of: b.tier) ?? 99
                if aIndex != bIndex { return aIndex < bIndex }
                return (a.createdAt ?? .distantPast) < (b.createdAt ?? .distantPast)
            }
            .first

        guard let goal = topGoal else {
            return .result(value: "All goals complete for today! 🎉")
        }

        let event = CompletionEvent()
        event.completedAt = .now
        event.goal = goal
        event.tierRawValue = goal.tierRawValue
        context.insert(event)
        try context.save()

        WidgetCenter.shared.reloadAllTimelines()

        return .result(value: "✓ \(goal.title ?? "Goal") logged")
    }
}
```

Add `CompleteTopGoalIntent.swift` to the `VitaminGWidget` target membership in Xcode (Project Navigator → File Inspector → VitaminGWidget checkbox).

Also add it to the main app target — AppIntents must be registered in the app binary as well as the widget extension.

- [ ] **Step 2: Check Goal model for needed properties**

Confirm `Goal` has:
- `isCompleted: Bool` — computed property on `Goal` (confirmed in `SchemaV1.swift`)
- `createdAt: Date?`
- `tierRawValue: String?`
- `tier: GoalTier` computed property

If the property name differs, adjust `CompleteTopGoalIntent` accordingly. Do not rename existing properties.

- [ ] **Step 3: Build both targets**

```
Cmd+B (main app target)
Then: select VitaminGWidget scheme → Cmd+B
```

AppIntents requires the intent to compile in both the app and the extension.

- [ ] **Step 4: Commit**

```bash
git add "VitaminGWidget/Intents/CompleteTopGoalIntent.swift"
git commit -m "feat: add CompleteTopGoalIntent AppIntent for interactive lock screen widget"
```

---

### Task 3: Interactive Lock Screen Widget

**Files:**
- Modify: `VitaminGWidget/StreakWidget.swift`

The `StreakWidget` already uses `accessoryRectangular` family (lock screen). Adding a `Button(intent:)` makes it interactive — tapping logs the top goal without unlocking.

- [ ] **Step 1: Import AppIntents in StreakWidget**

In `StreakWidget.swift`, add at the top:

```swift
import AppIntents
```

- [ ] **Step 2: Add interactive complete button to StreakWidgetView**

Update `StreakWidgetView.body`. In State A (streak > 0), add a complete button below the streak display. Replace the existing State A block:

```swift
if entry.displayData.globalStreak > 0 {
    HStack {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .widgetAccentable()
                Text("\(entry.displayData.globalStreak)")
                    .font(.title2.bold().monospacedDigit())
                    .widgetAccentable()
            }
            Text("day streak")
                .font(.caption)
        }
        Spacer()
        // One-tap completion button
        Button(intent: CompleteTopGoalIntent()) {
            Image(systemName: entry.displayData.topGoalCompletedToday ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .widgetAccentable()
        }
        .buttonStyle(.plain)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(entry.displayData.globalStreak) day streak. \(entry.displayData.topGoalCompletedToday ? "Top goal done" : "Tap circle to complete top goal")")
}
```

- [ ] **Step 3: Add topGoalCompletedToday to WidgetDisplayData**

In `WidgetTimelineEntry.swift`, add to `WidgetDisplayData`:

```swift
var topGoalCompletedToday: Bool
```

Update `placeholder` and `empty` with `topGoalCompletedToday: false`.

In `WidgetDataProvider.build(goals:events:)`, compute:

```swift
let today = Calendar.current.startOfDay(for: .now)
let completedGoalIDsToday: Set<PersistentIdentifier> = Set(
    events.compactMap { e -> PersistentIdentifier? in
        guard let date = e.completedAt,
              Calendar.current.isDate(date, inSameDayAs: today),
              let goal = e.goal else { return nil }
        return goal.id
    }
)
let tierOrder: [GoalTier] = [.lifeGoal, .longTerm, .shortTerm, .immediate]
let topGoal = goals
    .filter { !$0.isCompleted }
    .sorted { a, b in
        let ai = tierOrder.firstIndex(of: a.tier) ?? 99
        let bi = tierOrder.firstIndex(of: b.tier) ?? 99
        return ai != bi ? ai < bi : (a.createdAt ?? .distantPast) < (b.createdAt ?? .distantPast)
    }
    .first
let topGoalCompletedToday = topGoal.map { completedGoalIDsToday.contains($0.id) } ?? true

// Include in returned WidgetDisplayData:
return WidgetDisplayData(
    tierRows: tierRows,
    globalStreak: globalStreak,
    consistencyScore: consistencyScore,
    topGoalCompletedToday: topGoalCompletedToday
)
```

- [ ] **Step 4: Build and test**

Build both targets. On a physical device (interactive widgets require a real device — Simulator doesn't support lock screen widget interaction), add the Streak widget to the lock screen. Confirm the circle button appears. Tap it and confirm the streak updates.

- [ ] **Step 5: Commit**

```bash
git add VitaminGWidget/StreakWidget.swift VitaminGWidget/WidgetTimelineEntry.swift
git commit -m "feat: interactive lock screen widget — one-tap goal completion via AppIntents"
```

---

### Task 4: PhotoModerationService — Claude Haiku

**Files:**
- Create: `VitaminG/Services/PhotoModerationService.swift`
- Create: `Secrets.xcconfig` (gitignored)
- Modify: `VitaminG/VitaminG-Info.plist`

- [ ] **Step 1: Add API key to Secrets.xcconfig**

Create `VitaminG/Secrets.xcconfig` (this file must be in `.gitignore`):

```
ANTHROPIC_API_KEY = sk-ant-your-key-here
```

Add to `.gitignore`:
```
Secrets.xcconfig
```

In Xcode, assign `Secrets.xcconfig` to the Debug and Release configurations:
- Project → Info → Configurations → Debug: select `Secrets.xcconfig`
- Project → Info → Configurations → Release: select `Secrets.xcconfig`

- [ ] **Step 2: Add ANTHROPIC_API_KEY to Info.plist**

In `VitaminG/VitaminG-Info.plist`, add a new key:

```xml
<key>ANTHROPIC_API_KEY</key>
<string>$(ANTHROPIC_API_KEY)</string>
```

Xcode will substitute the value from `Secrets.xcconfig` at build time.

- [ ] **Step 3: Create PhotoModerationService**

Create `VitaminG/Services/PhotoModerationService.swift`:

```swift
import Foundation
import UIKit

// MARK: - PhotoModerationService

/// Checks an image for inappropriate content using Claude Haiku (claude-haiku-4-5-20251001).
/// Called before any community photo is submitted to CloudKit.
///
/// Fail-open design: if the API is unreachable or times out, returns true (safe) so a
/// network error never blocks a legitimate post. Real moderation happens server-side via
/// CloudKit rules as a secondary layer.
enum PhotoModerationService {

    private static let model = "claude-haiku-4-5-20251001"
    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private static let timeoutSeconds: Double = 10

    private static var apiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String ?? ""
    }

    // MARK: - isSafe

    /// Returns true if the image is safe to post; false if it contains adult, violent,
    /// or sexually suggestive content. Returns true on network failure (fail-open).
    ///
    /// - Parameter imageData: JPEG or PNG image data. Compressed to ≤1 MB before sending.
    static func isSafe(_ imageData: Data) async -> Bool {
        guard !apiKey.isEmpty else { return true }   // misconfigured — fail open
        guard let compressedData = compress(imageData, maxBytes: 1_000_000),
              let base64 = base64String(from: compressedData, originalData: imageData) else {
            return true
        }
        let mediaType = isJPEG(imageData) ? "image/jpeg" : "image/png"

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 64,
            "system": "You are a content safety classifier. Respond with only valid JSON: {\"safe\": true} or {\"safe\": false}. Flag adult content, nudity, graphic violence, or sexually suggestive imagery as unsafe. If the image appears to be a normal fitness or lifestyle photo, return {\"safe\": true}.",
            "messages": [[
                "role": "user",
                "content": [[
                    "type": "image",
                    "source": [
                        "type": "base64",
                        "media_type": mediaType,
                        "data": base64
                    ]
                ]]
            ]]
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return true }

        var request = URLRequest(url: endpoint, timeoutInterval: timeoutSeconds)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = bodyData

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return parseSafe(from: data)
        } catch {
            return true   // network error — fail open
        }
    }

    // MARK: - Private Helpers

    private static func parseSafe(from data: Data) -> Bool {
        // Response shape: {"content":[{"type":"text","text":"{\"safe\":true}"}],...}
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let textBlock = content.first(where: { $0["type"] as? String == "text" }),
              let text = textBlock["text"] as? String,
              let inner = text.data(using: .utf8),
              let innerJSON = try? JSONSerialization.jsonObject(with: inner) as? [String: Any],
              let safe = innerJSON["safe"] as? Bool else {
            return true   // parse failure — fail open
        }
        return safe
    }

    private static func compress(_ data: Data, maxBytes: Int) -> Data? {
        guard data.count > maxBytes else { return data }
        guard let image = UIImage(data: data) else { return nil }
        var quality: CGFloat = 0.8
        while quality > 0.1 {
            if let compressed = image.jpegData(compressionQuality: quality),
               compressed.count <= maxBytes {
                return compressed
            }
            quality -= 0.1
        }
        return nil
    }

    private static func base64String(from compressed: Data, originalData: Data) -> String? {
        compressed.base64EncodedString()
    }

    private static func isJPEG(_ data: Data) -> Bool {
        data.prefix(2) == Data([0xFF, 0xD8])
    }
}
```

- [ ] **Step 4: Build and confirm API key resolves**

Build (`Cmd+B`). Add a temporary breakpoint or `print(PhotoModerationService.apiKey.prefix(8))` call in a test to confirm the key is non-empty. Remove the debug print before committing.

- [ ] **Step 5: Commit**

```bash
git add VitaminG/Services/PhotoModerationService.swift VitaminG/VitaminG-Info.plist
git commit -m "feat: add PhotoModerationService using Claude Haiku for community photo safety"
```

---

### Task 5: Integrate Moderation into PostComposeSheet

**Files:**
- Modify: `VitaminG/Views/PostComposeSheet.swift`

- [ ] **Step 1: Add moderation state to PostComposeSheet**

In `PostComposeSheet.swift`, add two `@State` properties alongside the existing ones:

```swift
@State private var isCheckingPhoto = false
@State private var photoRejected = false
```

- [ ] **Step 2: Update submit() to run photo moderation**

Replace the existing `submit()` function:

```swift
private func submit() async {
    isSubmitting = true
    defer { isSubmitting = false }

    // Text profanity guard
    if ProfanityFilter.containsProfanity(text) {
        localProfanityFlagged = true
        return
    }

    // Photo moderation (only when a photo is attached)
    if let imageData = selectedImageData {
        isCheckingPhoto = true
        let safe = await PhotoModerationService.isSafe(imageData)
        isCheckingPhoto = false
        if !safe {
            photoRejected = true
            return
        }
    }

    let success = await viewModel.submitPost(
        text: text,
        imageData: selectedImageData,
        category: category,
        authorDisplayName: authorDisplayName,
        authorColorHex: authorColorHex
    )
    if success {
        dismiss()
    } else if viewModel.submitError == CommunityFeedViewModel.profanityRejectionMessage {
        localProfanityFlagged = true
    } else if viewModel.submitError != nil {
        showAlert = true
    }
}
```

- [ ] **Step 3: Show photo rejection inline**

In the view body, add the rejection message below the photo picker section. Find where `selectedImageData` / `PhotosPicker` is displayed and add below it:

```swift
if photoRejected {
    Label(
        "This photo can't be posted. Please choose a different image.",
        systemImage: "exclamationmark.triangle.fill"
    )
    .font(.caption)
    .foregroundStyle(.red)
    .onChange(of: selectedImageData) { _, _ in photoRejected = false }
}
```

The `.onChange` clears the rejection when the user picks a new photo so they can retry.

- [ ] **Step 4: Show loading state during photo check**

On the Post button, update the label to reflect the checking state:

```swift
Button(isCheckingPhoto ? "Checking photo..." : "Post") {
    Task { await submit() }
}
.disabled(!isPostEnabled || isCheckingPhoto)
```

- [ ] **Step 5: Build and test flow**

Build (`Cmd+B`). Open the community feed, compose a post with a safe photo — confirm it posts. Test with a photo you know is appropriate — moderation should return `safe: true`. The rejection UI only appears if Claude flags the image.

- [ ] **Step 6: Commit**

```bash
git add VitaminG/Views/PostComposeSheet.swift
git commit -m "feat: Claude Haiku photo moderation in PostComposeSheet — blocks unsafe images before CloudKit upload"
```

---

### Task 6: Final Build Verification

- [ ] **Step 1: Run the full test suite**

```bash
xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "PASSED|FAILED|error:"
```

Expected: all tests pass.

- [ ] **Step 2: Confirm CR-01 (temp file leak) already resolved**

In `CommunityService.swift`, verify line ~58 contains `defer { try? FileManager.default.removeItem(at: tmpURL) }` immediately after the `try compressed.write(to: tmpURL)` call. This was fixed in Phase 14. No action needed — just confirm.

- [ ] **Step 3: Device test checklist**

On a physical iPhone (iOS 17+):
- [ ] Add the Small widget to home screen — confirm Consistency Score appears
- [ ] Add the Streak widget to the lock screen — confirm the circle button is visible
- [ ] Tap the circle on the lock screen — confirm Face ID prompt → goal logged → widget updates
- [ ] Put phone in StandBy while charging — confirm the small widget appears in rotation
- [ ] Compose a community post with an attached photo — confirm the "Checking photo..." state appears briefly, then post succeeds

- [ ] **Step 4: Tag Phase 16 complete**

```bash
git tag phase-16-complete
```
