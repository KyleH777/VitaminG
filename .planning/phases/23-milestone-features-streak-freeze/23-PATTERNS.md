# Phase 23: Milestone Features + Streak Freeze — Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 8 feature areas across ~12 new/modified files
**Analogs found:** 8 / 8

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `Services/StreakFreezeService.swift` (modify) | service | CRUD + date-gate | `Services/StreakFreezeService.swift` (existing) | exact |
| `Views/HeatmapView.swift` (modify) | component | transform | `Views/HeatmapView.swift` (existing) | exact |
| `Views/MilestoneCelebrationView.swift` (modify) | component | event-driven | `Views/MilestoneCelebrationView.swift` (existing) | exact |
| `Views/GoalCompletionCelebrationView.swift` (new) | component | event-driven | `Views/CheckInCelebrationView.swift` | exact |
| `Views/AchievementUnlockedView.swift` (new) | component | event-driven | `Views/MilestoneCelebrationView.swift` | exact |
| `Services/CommunityService.swift` (extend) | service | request-response | `Services/CommunityService.swift` (existing) | exact |
| `ViewModels/GoalViewModel.swift` (modify) | view-model | CRUD + event-driven | `ViewModels/GoalViewModel.swift` (existing) | exact |
| `Services/NotificationScheduler.swift` (extend) | service | request-response | `Services/NotificationScheduler.swift` (existing) | exact |

---

## Pattern Assignments

### 1. Weekly Reset Gate (StreakFreezeService)

**Analog:** `VitaminG/VitaminG/VitaminG/Services/StreakFreezeService.swift` (lines 1–39)

The existing `StreakFreezeService` already persists freeze state to the shared App Group `UserDefaults` suite. Phase 23 changes the gate from **monthly** to **weekly**.

**Current gate pattern (lines 13–17) — change `.month` to `.weekOfYear`:**
```swift
var canFreeze: Bool {
    guard let lastDate = lastFreezeDate else { return true }
    let cal = Calendar.current
    // CURRENT: monthly gate — Phase 23 changes this to weekly
    return !cal.isDate(lastDate, equalTo: .now, toGranularity: .month)
    // PHASE 23: return !cal.isDate(lastDate, equalTo: .now, toGranularity: .weekOfYear)
}
```

**Freeze write pattern (lines 24–32) — copy verbatim, no changes needed:**
```swift
func freeze(on date: Date = .now) {
    guard canFreeze else { return }
    let cal = Calendar.current
    let day = cal.startOfDay(for: date)
    var intervals = defaults.array(forKey: keyFrozenDates) as? [Double] ?? []
    intervals.append(day.timeIntervalSince1970)
    defaults.set(intervals, forKey: keyFrozenDates)
    defaults.set(day.timeIntervalSince1970, forKey: keyLastFreezeDate)
}
```

**App Group UserDefaults init pattern (lines 9–11) — copy verbatim:**
```swift
init(defaults: UserDefaults = UserDefaults(suiteName: "group.com.kyleharrington.VitaminG") ?? .standard) {
    self.defaults = defaults
}
```

**How Phase 23 extends this:**
- Change `toGranularity: .month` → `toGranularity: .weekOfYear` (one-liner)
- The `frozenDates` array is already consumed by `StreakEngine.currentStreak(frozenDates:)` — no StreakEngine changes needed

---

### 2. Heatmap Freeze Glyph (HeatmapView)

**Analog:** `VitaminG/VitaminG/VitaminG/Views/HeatmapView.swift` (lines 1–49)

**Current cell rendering pattern (lines 31–36):**
```swift
ForEach(days, id: \.self) { day in
    RoundedRectangle(cornerRadius: 2)
        .fill(cellColor(for: data[day] ?? 0))
        .frame(width: 12, height: 12)
}
```

**Phase 23 extends to:** accept a `frozenDates: Set<Date>` parameter and overlay a ❄️ glyph when `frozenDates.contains(day)`.

**Pattern to copy — new ForEach body (replaces lines 31–36):**
```swift
// Caller computes frozenDates as Set(StreakFreezeService().frozenDates.map { cal.startOfDay(for: $0) })
ForEach(days, id: \.self) { day in
    ZStack {
        RoundedRectangle(cornerRadius: 2)
            .fill(frozenDates.contains(day) ? Color.blue.opacity(0.25) : cellColor(for: data[day] ?? 0))
            .frame(width: 12, height: 12)
        if frozenDates.contains(day) {
            Text("❄️")
                .font(.system(size: 8))
                .accessibilityLabel("Streak freeze")
        }
    }
}
```

**cellColor helper (lines 41–48) — copy verbatim:**
```swift
private func cellColor(for count: Int) -> Color {
    switch count {
    case 0:   return Color(.systemFill)
    case 1:   return .green.opacity(0.3)
    case 2:   return .green.opacity(0.6)
    default:  return .green
    }
}
```

---

### 3. Full-Screen Confetti Celebration (GoalCompletionCelebrationView — new file)

**Analog:** `VitaminG/VitaminG/VitaminG/Views/CheckInCelebrationView.swift` (lines 1–126)

This is the exact pattern for the "You did it" goal-completion screen. Copy the entire file and adjust the copy:

**Structure pattern (lines 18–101):**
```swift
struct GoalCompletionCelebrationView: View {
    let goalTitle: String         // shown in "You completed: <title>"
    let onDismiss: () -> Void
    let onShareToCommunity: () -> Void   // NEW: Phase 23 community share action

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var badgeScale: Double = 0.3
    @State private var badgeOpacity: Double = 0.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()
            if !reduceMotion {
                confettiView                 // copy verbatim from CheckInCelebrationView
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            }
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(VGTheme.accentSage)
                    .scaleEffect(badgeScale)
                    .opacity(badgeOpacity)
                Text("You did it.")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(goalTitle)
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                Spacer()
                Button("Share to Community") { onShareToCommunity() }
                    // ... same button style as "Back to Goals" in CheckInCelebrationView
                Button("Done") { onDismiss() }
            }
        }
        .onAppear {
            // same animation block as CheckInCelebrationView lines 91–101
        }
    }

    // confettiView — copy verbatim from CheckInCelebrationView lines 107–125
}
```

**Confetti canvas pattern (lines 107–125) — copy verbatim, identical in all 3 existing celebration views:**
```swift
private var confettiView: some View {
    TimelineView(.animation) { timeline in
        Canvas { context, size in
            let now = timeline.date.timeIntervalSinceReferenceDate
            let count = 60
            for i in 0..<count {
                let seed = Double(i) * 137.5  // golden angle scatter
                let x = (sin(seed + now * 0.8 + Double(i)) * 0.5 + 0.5) * size.width
                let rawY = (now * 80.0 + seed * 3.7).truncatingRemainder(dividingBy: size.height)
                let y = rawY < 0 ? rawY + size.height : rawY
                let hue = (seed / 360.0).truncatingRemainder(dividingBy: 1.0)
                let color = Color(hue: hue, saturation: 0.8, brightness: 0.9)
                let rect = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)
                context.fill(Path(rect), with: .color(color))
            }
        }
    }
}
```

**Auto-dismiss pattern (line 83):**
```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { onDismiss() }
```

**Badge spring animation pattern (lines 96–99):**
```swift
withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
    badgeScale = 1.0
    badgeOpacity = 1.0
}
```

**Accessibility announcement pattern (lines 86–89):**
```swift
UIAccessibility.post(notification: .announcement, argument: "Goal completed: \(goalTitle)")
```

---

### 4. Achievement Unlocked View (AchievementUnlockedView — new file)

**Analog:** `VitaminG/VitaminG/VitaminG/Views/MilestoneCelebrationView.swift` (lines 1–166)

The achievement-unlocked full-screen overlay is structurally identical to `MilestoneCelebrationView`. Copy its pattern and extend with a community share button.

**Badge symbol mapping pattern (lines 29–37):**
```swift
private var badgeSymbol: String {
    switch threshold {
    case 7:  return "flame.fill"
    case 30: return "trophy.fill"
    case 60: return "medal.fill"
    case 90: return "star.fill"
    default: return "star.fill"
    }
}
```

**Badge persistence pattern — idempotent append (lines 148–165):**
```swift
private func saveBadgeToProfile() {
    let symbol = badgeSymbol
    var symbols: [String] = []
    if let json = userChallenge.earnedBadgeSymbolsJSON,
       let data = json.data(using: .utf8),
       let decoded = try? JSONDecoder().decode([String].self, from: data) {
        symbols = decoded
    }
    guard !symbols.contains(symbol) else { return }
    symbols.append(symbol)
    if let data = try? JSONEncoder().encode(symbols),
       let json = String(data: data, encoding: .utf8) {
        userChallenge.earnedBadgeSymbolsJSON = json
    }
}
```

**Dismiss button pattern (lines 90–99):**
```swift
Button("Keep Going") { onDismiss() }
    .font(.body.weight(.semibold)).fontDesign(.rounded)
    .frame(maxWidth: .infinity, minHeight: 44)
    .background(accentColor)
    .foregroundStyle(.white)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding(.horizontal, 24)
    .padding(.bottom, 48)
```

**Phase 23 AchievementUnlockedView additions:**
- Add `milestoneLabel: String` parameter (e.g. "5-Day Streak", "10 Check-ins")
- Add `onShare: () -> Void` closure that triggers community post sheet
- Copy `confettiView` verbatim (same as all other celebration views)
- `onAppear` calls `saveBadgeToProfile()` then animates badge — same as MilestoneCelebrationView lines 102–118

---

### 5. Community Post Write (Achievement Post)

**Analog:** `VitaminG/VitaminG/VitaminG/Services/CommunityService.swift` (lines 41–70)

**CKRecord creation pattern (lines 48–69) — copy this structure for achievement posts:**
```swift
static func createPost(
    text: String,
    imageData: Data?,
    category: String,
    authorDisplayName: String?,
    authorColorHex: String?
) async throws -> CKRecord {
    let container = CKContainer.default()
    let record = CKRecord(recordType: postRecordType)
    record["text"] = InputSanitizer.sanitizeForPublic(text) as CKRecordValue
    record["category"] = category as CKRecordValue
    record["authorDisplayName"] = (InputSanitizer.sanitizeForPublic(authorDisplayName ?? "Anonymous")) as CKRecordValue
    record["authorColorHex"] = (authorColorHex ?? "") as CKRecordValue
    record["thumbsUpCount"] = 0 as CKRecordValue
    record["heartCount"] = 0 as CKRecordValue
    record["reportCount"] = 0 as CKRecordValue
    record["reporterIDsJSON"] = "[]" as CKRecordValue
    return try await container.publicCloudDatabase.save(record)
}
```

**Phase 23 achievement post extension** — add to `CommunityService` extension:
```swift
// In new Phase 23 extension on CommunityService
static func createAchievementPost(
    milestoneLabel: String,    // e.g. "Reached 10 check-ins on Run Every Day"
    goalTitle: String,
    category: String,
    authorDisplayName: String?,
    authorColorHex: String?
) async throws -> CKRecord {
    let record = CKRecord(recordType: postRecordType)
    record["text"] = InputSanitizer.sanitizeForPublic("🏆 \(milestoneLabel): \(goalTitle)") as CKRecordValue
    record["category"] = category as CKRecordValue
    record["authorDisplayName"] = InputSanitizer.sanitizeForPublic(authorDisplayName ?? "Anonymous") as CKRecordValue
    record["authorColorHex"] = (authorColorHex ?? "") as CKRecordValue
    record["thumbsUpCount"] = 0 as CKRecordValue
    record["heartCount"] = 0 as CKRecordValue
    record["reportCount"] = 0 as CKRecordValue
    record["reporterIDsJSON"] = "[]" as CKRecordValue
    // achievement marker so feed can style it differently
    record["isAchievementPost"] = 1 as CKRecordValue
    return try await CKContainer.default().publicCloudDatabase.save(record)
}
```

**Fire-and-forget Task pattern** (from `GoalViewModel.addCheckIn` lines 181–188):
```swift
Task {
    await CommunityService.writeGlimpse(
        username: username,
        goalTitle: goal.title ?? "",
        progressPercent: progressPercent,
        authorColorHex: colorHex
    )
}
// Phase 23: same Task wrapping for createAchievementPost — fire-and-forget, errors silently dropped
```

**InputSanitizer rule** — ALL text written to CloudKit must pass through:
```swift
InputSanitizer.sanitizeForPublic(text) as CKRecordValue
```

---

### 6. GoalViewModel.addCheckIn — Completion Detection Extension

**Analog:** `VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift` (lines 155–230)

**Current function signature (lines 155–156):**
```swift
func addCheckIn(for goal: Goal, context: ModelContext, username: String = "", colorHex: String = "") {
```

**Same-day dedup guard (lines 157–160) — copy verbatim, do not change:**
```swift
let alreadyCheckedInToday = goal.completionEvents?.contains { event in
    Calendar.current.isDateInToday(event.completedAt ?? .distantPast)
} ?? false
guard !alreadyCheckedInToday else { return }
```

**Milestone detection pattern (from `toggleCompletion` lines 122–135) — replicate inside `addCheckIn`:**
```swift
// After inserting CompletionEvent (line 166), add:
let count = (goal.completionEvents?.count ?? 0)
if let threshold = progressVM.milestoneJustCrossed(
    count: count,
    firedSet: firedMilestones,
    goalID: goal.id
) {
    let key = "\(goal.id.uuidString)-\(threshold)"
    firedMilestones.insert(key)
    pendingMilestone = (goalID: goal.id, threshold: threshold)
}
```

**Goal completion detection** — Phase 23 adds after milestone check:
```swift
// Goal completion: check if durationDays is set and count has reached it
if let duration = goal.durationDays,
   duration > 0,
   (goal.completionEvents?.count ?? 0) >= duration,
   goal.isCompleted == false {
    pendingGoalCompletion = goal.id   // new @Observable property — triggers GoalCompletionCelebrationView
}
```

**New @Observable property on GoalViewModel (alongside `pendingMilestone` at line 56):**
```swift
// Mirrors pendingMilestone pattern exactly
var pendingGoalCompletion: UUID? = nil
```

**Widget reload pattern (lines 169–170) — copy verbatim after any mutation:**
```swift
rescheduleNotification(context: context)
reloadWidgetTimelines()
```

---

### 7. One-Time Persistence / "Shown Only Once" Screens

**Analog A — Date-keyed gate:** `VitaminG/VitaminG/VitaminG/ViewModels/ExploreViewModel.swift` (lines 10–64)

Used for daily gates (gifter, mood, applause). Copy the computed-var + markDone() pattern:

```swift
// In ExploreViewModel — the canonical date-gate pattern
private enum Keys {
    static let gifterDate = "vg_explore_gifterDate"  // UserDefaults key naming convention: vg_<feature>_<purpose>
}

var hasGiftedToday: Bool {
    guard let stored = UserDefaults.standard.object(forKey: Keys.gifterDate) as? Date else {
        return false
    }
    return Calendar.current.isDateInToday(stored)
}

func markGiftedToday() {
    UserDefaults.standard.set(Date(), forKey: Keys.gifterDate)
}
```

**For weekly gates** — change `isDateInToday` to a week comparison:
```swift
var canFreezeThisWeek: Bool {
    guard let stored = UserDefaults.standard.object(forKey: "vg_streakFreeze_lastWeekKey") as? String else {
        return true
    }
    // ISO 8601 week string: "2026-W21"
    return stored != currentISOWeekKey
}

private var currentISOWeekKey: String {
    let cal = Calendar(identifier: .iso8601)
    let week = cal.component(.weekOfYear, from: Date())
    let year = cal.component(.yearForWeekOfYear, from: Date())
    return "\(year)-W\(week)"
}
```

**Analog B — Boolean flag for "shown once ever":** `VitaminG/VitaminG/VitaminG/Views/Onboarding/TermsAndConditionsScreen.swift` (grep result line 13)

```swift
@AppStorage("vg_hasAgreedToTerms") private var hasAgreedToTerms: Bool = false
// When shown: hasAgreedToTerms = true — never shown again
```

**Phase 23 one-time keys to add** (following `vg_<feature>_<purpose>` convention):
```
vg_streakFreeze_lastWeekKey      // ISO week string — weekly gate
vg_achievement_shown_<goalID>-<threshold>   // per-goal-milestone shown flag
```

---

### 8. Notification Scheduling (Achievement Notifications)

**Analog:** `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift` (lines 323–356)

The milestone notification pattern (one-time, fires immediately via `UNTimeIntervalNotificationTrigger`) is the exact pattern for achievement notifications.

**One-time notification pattern (lines 323–356):**
```swift
func scheduleMilestoneNotification(
    challengeID: UUID,
    threshold: Int,
    message: String
) async {
    let identifier = Self.milestoneIdentifier(for: challengeID, threshold: threshold)
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [identifier])

    let content = UNMutableNotificationContent()
    content.title = "Milestone reached!"
    content.body = message
    content.sound = .default
    content.userInfo = [
        "deepLink": "challengeDetail",
        "userChallengeID": challengeID.uuidString,
        "source": "milestone",
        "threshold": threshold
    ]

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    do {
        try await center.add(request)
    } catch {
        #if DEBUG
        print("[NotificationScheduler] Failed to add milestone: \(error)")
        #endif
    }
}
```

**Phase 23 goal-achievement notification** — add as new extension method following the same pattern:
```swift
static func goalAchievementIdentifier(for goalID: UUID, threshold: Int) -> String {
    "com.kyleharrington.VitaminG.goalAchievement.\(goalID.uuidString).\(threshold)"
}

func scheduleGoalAchievementNotification(goalID: UUID, goalTitle: String, threshold: Int) async {
    // copy scheduleMilestoneNotification verbatim, change:
    // content.title = "Goal milestone reached!"
    // content.body = "\(goalTitle) — \(threshold) check-ins complete!"
    // content.userInfo["deepLink"] = "goalDetail"
    // content.userInfo["goalID"] = goalID.uuidString
}
```

**Identifier scheme** — match existing pattern from line 263:
```swift
// Existing: "com.kyleharrington.VitaminG.milestone.<challengeUUID>.<threshold>"
// Phase 23:  "com.kyleharrington.VitaminG.goalAchievement.<goalUUID>.<threshold>"
```

---

## Shared Patterns

### InputSanitizer — Required for All CloudKit Writes
**Source:** `Services/CommunityService.swift` lines 52–53, 424–427
**Apply to:** `createAchievementPost` and any new CKRecord writes in Phase 23
```swift
record["text"] = InputSanitizer.sanitizeForPublic(text) as CKRecordValue
record["authorDisplayName"] = InputSanitizer.sanitizeForPublic(authorDisplayName ?? "Anonymous") as CKRecordValue
```

### ReduceMotion Guard — All Animation-Bearing Views
**Source:** `Views/CheckInCelebrationView.swift` lines 27, 38–42, 92–99
**Apply to:** `GoalCompletionCelebrationView`, `AchievementUnlockedView`
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

// In body:
if !reduceMotion {
    confettiView.ignoresSafeArea().accessibilityHidden(true)
}

// In onAppear:
if reduceMotion {
    badgeScale = 1.0; badgeOpacity = 1.0
} else {
    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
        badgeScale = 1.0; badgeOpacity = 1.0
    }
}
```

### fullScreenCover Presentation — All Full-Screen Overlays
**Source:** `Views/GoalDetailView.swift` lines 55–57
**Apply to:** `GoalCompletionCelebrationView`, `AchievementUnlockedView`
```swift
.fullScreenCover(isPresented: $showingCheckInCelebration) {
    CheckInCelebrationView(streakCount: appStreak, onDismiss: { showingCheckInCelebration = false })
}
```

### Pending State Pattern — ViewModel → View Handoff
**Source:** `ViewModels/GoalViewModel.swift` lines 50–60; `Views/GoalListView.swift` lines 18–19, 81–92
**Apply to:** `pendingGoalCompletion` in GoalViewModel, consumed in GoalListView/GoalDetailView
```swift
// ViewModel (GoalViewModel.swift):
var pendingMilestone: (goalID: UUID, threshold: Int)? = nil
private var firedMilestones: Set<String> = []

// View consumer (GoalListView.swift):
@State private var pendingMilestone: (goalID: UUID, threshold: Int)? = nil

.onChange(of: viewModel.pendingMilestone?.goalID) { _, _ in
    if let milestone = viewModel.pendingMilestone {
        pendingMilestone = milestone
        viewModel.pendingMilestone = nil  // consume immediately
    }
}
```

### App Group UserDefaults Suite — StreakFreezeService
**Source:** `Services/StreakFreezeService.swift` line 9
**Apply to:** Any new UserDefaults usage in StreakFreezeService
```swift
UserDefaults(suiteName: "group.com.kyleharrington.VitaminG") ?? .standard
```
Note: All other UserDefaults in the app use `.standard`. Only StreakFreezeService uses the shared suite (for widget access). Do not change this for Phase 23 additions.

### UserDefaults Key Convention
**Source:** `ViewModels/ExploreViewModel.swift` lines 10–19; `Services/BiometricLockService.swift`; `Services/BlockListService.swift`
**Pattern:** `vg_<feature>_<purpose>` — always lowercase, underscore-separated
```
vg_explore_gifterDate
vg_explore_moodDate
vg_community_applauseGiven
vg_biometric_lock_enabled
vg_blockedUserIDs
// Phase 23 additions follow same scheme:
vg_streakFreeze_lastWeekKey
```

### Fire-and-Forget Task Pattern
**Source:** `ViewModels/GoalViewModel.swift` lines 181–188
**Apply to:** All CloudKit writes triggered from GoalViewModel (achievement post, presence)
```swift
Task {
    await CommunityService.writeGlimpse(...)
    // or: try? await CommunityService.createAchievementPost(...)
}
// Do NOT await — fire and forget; errors silently dropped per COMM-01
```

### @MainActor @Observable ViewModel Pattern
**Source:** `ViewModels/GoalViewModel.swift` lines 30–32; `ViewModels/ExploreViewModel.swift` lines 5–7
**Apply to:** Any new ViewModel added in Phase 23
```swift
@MainActor
@Observable
final class MyViewModel {
```

---

## No Analog Found

No files in Phase 23 lack a codebase analog. All patterns have direct matches.

---

## Metadata

**Analog search scope:** `VitaminG/VitaminG/VitaminG/` — Services/, ViewModels/, Views/, Views/Community/, Views/Explore/, Views/Components/
**Files scanned:** 17 source files read; ~30 grepped
**Pattern extraction date:** 2026-05-25
