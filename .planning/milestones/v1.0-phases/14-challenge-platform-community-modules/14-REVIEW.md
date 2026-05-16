---
phase: 14-challenge-platform-community-modules
reviewed: 2026-05-13T19:24:12Z
depth: standard
files_reviewed: 23
files_reviewed_list:
  - VitaminG/VitaminG/VitaminG/Models/SchemaV4.swift
  - VitaminG/VitaminG/VitaminG/Models/SchemaV5.swift
  - VitaminG/VitaminG/VitaminG/Models/VitaminGMigrationPlan.swift
  - VitaminG/VitaminG/VitaminG/Navigation/AppRoute.swift
  - VitaminG/VitaminG/VitaminG/Persistence/ModelContainerFactory.swift
  - VitaminG/VitaminG/VitaminG/Services/CommunityService.swift
  - VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift
  - VitaminG/VitaminG/VitaminG/Services/ProfanityFilter.swift
  - VitaminG/VitaminG/VitaminG/ViewModels/CommunityFeedViewModel.swift
  - VitaminG/VitaminG/VitaminG/Views/ChallengeDetailView.swift
  - VitaminG/VitaminG/VitaminG/Views/ChallengeDiscoveryView.swift
  - VitaminG/VitaminG/VitaminG/Views/CommunityFeedView.swift
  - VitaminG/VitaminG/VitaminG/Views/Components/CommunityPostCard.swift
  - VitaminG/VitaminG/VitaminG/Views/Components/ReactionPill.swift
  - VitaminG/VitaminG/VitaminG/Views/ContentView.swift
  - VitaminG/VitaminG/VitaminG/Views/CustomChallengeBuilderView.swift
  - VitaminG/VitaminG/VitaminG/Views/Modules/TransformationPhotosModuleView.swift
  - VitaminG/VitaminG/VitaminG/Views/PostComposeSheet.swift
  - VitaminG/VitaminG/VitaminGTests/CommunityFeedViewModelTests.swift
  - VitaminG/VitaminG/VitaminGTests/NotificationSchedulerPhase14Tests.swift
  - VitaminG/VitaminG/VitaminGTests/ProfanityFilterTests.swift
  - VitaminG/VitaminG/VitaminGTests/SchemaV5Tests.swift
  - VitaminG/VitaminG/VitaminGTests/VitaminGTests.swift
findings:
  critical: 4
  warning: 5
  info: 3
  total: 12
status: fixes_applied
fixed_at: 2026-05-13T20:15:00Z
---

# Phase 14: Code Review Report

**Reviewed:** 2026-05-13T19:24:12Z
**Depth:** standard
**Files Reviewed:** 23
**Status:** issues_found

## Summary

Phase 14 adds a CloudKit public-database community feed, five module views, a custom challenge builder, and an extended notification suite. The schema migration, SwiftData model definitions, profanity filter, and navigation wiring are structurally sound. However, four blockers were identified: a temporary file leak on every image post (accumulates in the user's tmp directory indefinitely), a silent post-removal on report failure (network error silently hides the post locally), a reaction-switching bug that leaves stale server counts when a user switches from one reaction type to another, and a `CKError.serverRecordChanged` conflict not handled in `reportPost` (race condition corrupts reporter list and count). Five warnings cover a wrong alert message for ViewModel-caught profanity, `posts = []` on any refresh error destroying cached content, an unchecked `durationDays == 0` that yields `NaN` in `ProgressView`, `try? modelContext.save()` silently dropping persistence errors in two views, and the iOS 64-notification cap becoming a latent risk as users accumulate active challenges in Phase 14.

---

## Critical Issues

### CR-01: Temporary file for CKAsset is never cleaned up — accumulates on every image post

**File:** `VitaminG/VitaminG/VitaminG/Services/CommunityService.swift:55-61`

**Issue:** `createPost` writes JPEG data to a unique temp file and creates a `CKAsset(fileURL: tmpURL)`, but `tmpURL` is never removed after `db.save(record)` returns (or throws). Every image post permanently adds a file to the user's temporary directory. iOS will eventually purge the tmp directory under memory pressure, but on devices with abundant storage this accumulates across sessions. More critically, if `db.save(record)` throws, the file is also abandoned because the error propagates before cleanup code could run.

**Fix:**
```swift
if let imageData = imageData,
   let compressed = compressToJPEG(imageData, maxBytes: 500_000) {
    let tmpURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString + ".jpg")
    try compressed.write(to: tmpURL)
    record["photoAsset"] = CKAsset(fileURL: tmpURL)
    // Cleanup after save regardless of success/failure
    defer { try? FileManager.default.removeItem(at: tmpURL) }
    return try await container.publicCloudDatabase.save(record)
}
return try await container.publicCloudDatabase.save(record)
```

---

### CR-02: `handleReport` removes post from local feed even when the network call fails (returns -1)

**File:** `VitaminG/VitaminG/VitaminG/Views/CommunityFeedView.swift:153-162`

**Issue:** `handleReport` always calls `viewModel.posts.removeAll { ... }` regardless of the return value from `reportPost`. `CommunityFeedViewModel.reportPost` returns `-1` on any error (network failure, CloudKit unavailable, etc.). A transient network error therefore silently and permanently hides the post from the user's feed for the rest of the session — the post is only re-shown if the user force-restarts the app and `loadPosts` succeeds again. There is no success/failure gate.

**Fix:**
```swift
private func handleReport(post: CKRecord) async {
    let count = await viewModel.reportPost(recordID: post.recordID, reporterID: reporterID)
    guard count >= 0 else {
        // Network failure — do not hide the post; optionally show an error
        return
    }
    withAnimation(.easeOut(duration: 0.25)) {
        viewModel.posts.removeAll { $0.recordID == post.recordID }
    }
    #if DEBUG
    print("[CommunityFeedView] reportPost recordID=\(post.recordID.recordName) newCount=\(count)")
    #endif
}
```

---

### CR-03: Reaction switching does not decrement the previously-active reaction on the server

**File:** `VitaminG/VitaminG/VitaminG/Views/CommunityFeedView.swift:135-150`

**Issue:** `handleReact` implements mutual exclusion in the local `localReactionByPostID` dictionary (correct for the optimistic UI), but only fires a single `toggleReaction` call targeting the new reaction type. When a user switches from one reaction to another — e.g., taps thumbsUp, then taps heart — the old thumbsUp is cleared locally but `toggleReaction(type:.thumbsUp, add:false)` is never called. The server `thumbsUpCount` is permanently over-counted by 1. Over time, reaction counts on popular posts drift upward relative to actual unique reactions.

**Fix:**
```swift
private func handleReact(post: CKRecord, type: ReactionType) {
    let prior = localReactionByPostID[post.recordID]
    if prior == type {
        localReactionByPostID[post.recordID] = nil
    } else {
        localReactionByPostID[post.recordID] = type
    }
    Task {
        // If switching reaction types, decrement the prior one first
        if let prior, prior != type {
            _ = await viewModel.toggleReaction(
                recordID: post.recordID,
                reactionType: prior,
                add: false
            )
        }
        _ = await viewModel.toggleReaction(
            recordID: post.recordID,
            reactionType: type,
            add: localReactionByPostID[post.recordID] == type
        )
    }
}
```

---

### CR-04: `reportPost` has no conflict-retry for `CKError.serverRecordChanged` — concurrent reports corrupt the reporter list and count

**File:** `VitaminG/VitaminG/VitaminG/Services/CommunityService.swift:92-113`

**Issue:** `reportPost` follows a read-modify-write pattern on `reporterIDsJSON` and `reportCount` fields. `toggleReaction` (lines 79-87) correctly retries once on `CKError.serverRecordChanged`. `reportPost` has no equivalent retry. When two users simultaneously report the same post, one save will fail with a server-record-changed error and that reporter's ID is never written. The result is: (1) the reporter can re-report the same post, (2) the `reportCount` may be under-counted, preventing auto-hiding at the three-report threshold.

**Fix:** Mirror the retry pattern from `toggleReaction`:
```swift
static func reportPost(recordID: CKRecord.ID, reporterID: String) async throws -> Int {
    let container = CKContainer(identifier: containerID)
    let db = container.publicCloudDatabase

    func applyReport(to record: CKRecord) -> (CKRecord, Int)? {
        let existingJSON = (record["reporterIDsJSON"] as? String) ?? "[]"
        var reporters = (try? JSONDecoder().decode([String].self,
            from: Data(existingJSON.utf8))) ?? []
        guard !reporters.contains(reporterID) else { return nil }
        reporters.append(reporterID)
        if let data = try? JSONEncoder().encode(reporters),
           let json = String(data: data, encoding: .utf8) {
            record["reporterIDsJSON"] = json as CKRecordValue
        }
        let count = reporters.count
        record["reportCount"] = count as CKRecordValue
        return (record, count)
    }

    do {
        let record = try await db.record(for: recordID)
        guard let (updated, count) = applyReport(to: record) else {
            return (record["reportCount"] as? Int) ?? 0
        }
        _ = try await db.save(updated)
        return count
    } catch let error as CKError where error.code == .serverRecordChanged {
        let record = try await db.record(for: recordID)
        guard let (updated, count) = applyReport(to: record) else {
            return (record["reportCount"] as? Int) ?? 0
        }
        _ = try await db.save(updated)
        return count
    }
}
```

---

## Warnings

### WR-01: ViewModel-caught profanity rejection displays wrong alert in `PostComposeSheet`

**File:** `VitaminG/VitaminG/VitaminG/Views/PostComposeSheet.swift:130-155`

**Issue:** `submit()` first runs a local `ProfanityFilter.containsProfanity` guard (sets `localProfanityFlagged`, no alert). If that guard passes but `viewModel.submitPost` catches profanity via its own redundant check, it sets `submitError = profanityRejectionMessage` and returns `false`. The view then evaluates `viewModel.submitError != nil` as `true` and shows the hardcoded `.alert("Couldn't post. Please try again.")`. The user sees a generic network-failure message for what is actually a content rejection. The profanity-specific copy is unused.

**Fix:** Inspect `viewModel.submitError` to choose the alert message:
```swift
if success {
    dismiss()
} else if viewModel.submitError == CommunityFeedViewModel.profanityRejectionMessage {
    localProfanityFlagged = true  // show inline UI, not the network-error alert
} else if viewModel.submitError != nil {
    showAlert = true
}
```

---

### WR-02: `loadPosts` unconditionally clears `posts` on any error, destroying cached content on refresh failure

**File:** `VitaminG/VitaminG/VitaminG/ViewModels/CommunityFeedViewModel.swift:36-39`

**Issue:** The `catch` block sets `posts = []` regardless of whether the `posts` array was previously populated. If a user refreshes the community feed while offline or during a transient CloudKit outage, the entire list disappears and the view shows the empty state until the next successful load. This is particularly jarring because the data was already displayed moments before.

**Fix:** Only clear `posts` on the initial load (when the array was already empty); preserve existing content on refresh errors:
```swift
} catch {
    if posts.isEmpty {
        posts = []   // first-load failure: stay in empty state
    }
    // On refresh failure, preserve existing posts — do not set posts = []
}
```

---

### WR-03: `progressValue` yields `NaN` if `durationDays` is `0` — `ProgressView` behaviour is undefined

**File:** `VitaminG/VitaminG/VitaminG/Views/ChallengeDetailView.swift:243-246`

**Issue:** `progressValue` computes `Double(userChallenge.totalCheckIns) / Double(total)` where `total = userChallenge.template?.durationDays ?? 90`. `durationDays` is an `Optional<Int>` with no schema-enforced minimum. If a template is inserted with `durationDays = 0` (possible via a future migration, direct model manipulation, or a CloudKit-synced record from another device), `Double(0) / Double(0)` yields `NaN`. Passing `NaN` to `ProgressView(value:)` has undefined SwiftUI rendering behaviour and may crash in some OS versions.

**Fix:**
```swift
private var progressValue: Double {
    let total = userChallenge.template?.durationDays ?? 90
    guard total > 0 else { return 0.0 }
    return min(1.0, Double(userChallenge.totalCheckIns) / Double(total))
}
```

---

### WR-04: `try? modelContext.save()` silently discards persistence errors in two views

**File:** `VitaminG/VitaminG/VitaminG/Views/Modules/TransformationPhotosModuleView.swift:173`
**File:** `VitaminG/VitaminG/VitaminG/Views/CustomChallengeBuilderView.swift:346`

**Issue:** Both views call `try? modelContext.save()` which swallows any SwiftData persistence error without user feedback. If the save fails (disk full, store corruption, iCloud account issue), the user believes the photo was saved or the challenge was created when it was not. CLAUDE.md requires input validation and untrusted-boundary handling; silently dropping a save constitutes data loss from the user's perspective.

**Fix:** Surface the error with at minimum a `#if DEBUG` print and, for production, consider an error state variable that shows an alert:
```swift
do {
    try modelContext.save()
} catch {
    #if DEBUG
    print("[TransformationPhotosModuleView] modelContext.save() failed: \(error)")
    #endif
    // TODO: surface saveError to user in production
}
```

---

### WR-05: iOS 64-notification cap is latent risk with Phase 14 per-challenge notification additions

**File:** `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift:238-366`

**Issue:** Phase 14 adds two repeating notifications per active challenge (`streakAtRisk` + the Phase 13 `challengeReminder`). With the two fixed notifications (`dailyReminder`, `winReminder`), the pending count is `2 + 2N` for N active challenges. A user with 31 simultaneous active challenges hits the iOS limit of 64. This is unlikely in the current UX but becomes reachable as the app matures, and the system silently drops excess requests rather than returning an error. There is no cap-awareness logic.

**Fix:** Document the risk and add a guard in `scheduleStreakAtRiskReminder` (or a shared scheduling coordinator) that queries the current pending count before scheduling:
```swift
// Before scheduling: check remaining capacity
let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
guard pending.count < 60 else {  // leave 4-slot buffer
    #if DEBUG
    print("[NotificationScheduler] Skipping streakAtRisk — approaching 64-cap (\(pending.count) pending)")
    #endif
    return
}
```

---

## Info

### IN-01: Category filter chips in `ChallengeDiscoveryView` are non-interactive — misleading UI

**File:** `VitaminG/VitaminG/VitaminG/Views/ChallengeDiscoveryView.swift:79-92`

**Issue:** The "Browse by Category" section renders `Text` views styled as tappable pills with no `Button`, `onTapGesture`, or `selectedCategory` state. Users will attempt to tap these chips expecting to filter the featured list and receive no feedback. The browse row is pure decoration with the label "Browse by Category" implying interactivity.

**Fix:** Either make the pills functional by tracking a `@State private var selectedCategory: String?` and filtering `templates`, or rename the section to "Categories" and remove the pill styling to avoid affordance confusion.

---

### IN-02: `compressToJPEG` may return data larger than `maxBytes` when quality floor is reached

**File:** `VitaminG/VitaminG/VitaminG/Services/CommunityService.swift:116-129`

**Issue:** The compression loop exits when `quality <= 0.1` even if `compressed.count > maxBytes`. The caller in `createPost` uses the returned data unconditionally as a `CKAsset`. CKAsset has a maximum record payload of 250 MB (individual asset limit), so this is unlikely to cause a hard failure, but for very large images a file larger than the intended 500 KB cap will be uploaded, consuming more bandwidth and CloudKit storage than expected.

**Fix:** Return `nil` if the final compressed result still exceeds `maxBytes`, so the caller can skip the photo attachment:
```swift
return compressed.count <= maxBytes ? compressed : nil
```

---

### IN-03: `CustomChallengeBuilderView` target goal allows negative numeric values

**File:** `VitaminG/VitaminG/VitaminG/Views/CustomChallengeBuilderView.swift:69-77`

**Issue:** `isStep2Valid` for `goalType == "target"` accepts any `Double`-parseable string including negative numbers (`"-5"`, `"-0.1"`). A negative goal target is semantically nonsensical and would display strangely in progress tracking (e.g., `totalCheckIns / -5` in `progressValue`). The `TextField` uses `.decimalPad` which allows a minus key on some locales.

**Fix:** Add a positivity check to `isStep2Valid`:
```swift
case "target":
    guard let val = Double(targetValueText.trimmingCharacters(in: .whitespaces)) else {
        return false
    }
    return val > 0
```

---

_Reviewed: 2026-05-13T19:24:12Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
