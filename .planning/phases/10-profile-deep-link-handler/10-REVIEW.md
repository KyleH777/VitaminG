---
phase: 10-profile-deep-link-handler
reviewed: 2026-04-20T00:00:00Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - VitaminG/VitaminG/VitaminG/Services/DeepLinkParser.swift
  - VitaminG/VitaminG/VitaminGTests/DeepLinkParserTests.swift
  - VitaminG/VitaminG/VitaminGTests/PublicProfileViewModelTests.swift
  - VitaminG/VitaminG/VitaminG/Navigation/AppRoute.swift
  - VitaminG/VitaminG/VitaminG/Navigation/AppRouter.swift
  - VitaminG/VitaminG/VitaminG/Services/ProfileSharingService.swift
  - VitaminG/VitaminG/VitaminG/Views/ContentView.swift
  - VitaminG/VitaminG/VitaminG/ViewModels/PublicProfileViewModel.swift
  - VitaminG/VitaminG/VitaminG/Views/PublicProfileView.swift
  - VitaminG/VitaminG/VitaminG/VitaminGApp.swift
findings:
  critical: 0
  warning: 4
  info: 4
  total: 8
status: issues_found
---

# Phase 10: Code Review Report

**Reviewed:** 2026-04-20
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Phase 10 adds deep link handling for `vitaming://profile/<recordID>` URLs, routing them to a `PublicProfileView` sheet. The feature is architecturally sound: `DeepLinkParser` is correctly isolated for testability, the `AppRouter.pendingPublicProfileRecordID` trigger is clean, and the CloudKit field allowlist in `ProfileSharingService` is a good security practice.

Four warnings were found: a race condition in `PublicProfileViewModel` where concurrent fetch tasks can produce non-deterministic state, a logic gap where deep links received during onboarding are silently dropped after onboarding completes, a testability seam (`fetchOverride`) exposed in production builds, and flaky timing-based async tests. No critical issues were found.

---

## Warnings

### WR-01: Concurrent fetch tasks race on `state` in PublicProfileViewModel

**File:** `VitaminG/VitaminG/VitaminG/ViewModels/PublicProfileViewModel.swift:27`
**Issue:** `fetchProfile` fires an unstructured `Task { }` without storing or cancelling it. If `fetchProfile` is called a second time before the first Task completes (e.g., the view receives a new `recordID`, or `onAppear` fires twice during sheet transitions), two Tasks run concurrently and race to write `self.state`. The last writer wins, which may show a stale result or an error from an outdated request for the current profile.

**Fix:** Store the Task and cancel it before starting a new one:
```swift
private var fetchTask: Task<Void, Never>?

func fetchProfile(recordID: String) {
    fetchTask?.cancel()
    state = .loading
    fetchTask = Task {
        do {
            // ... existing fetch logic ...
        } catch is CancellationError {
            // Ignore — superseded by a newer call
        } catch let error as CKError {
            // ... existing CKError handling ...
        } catch {
            // ... existing catch-all ...
        }
    }
}
```

---

### WR-02: Deep link received during onboarding is applied but never presented

**File:** `VitaminG/VitaminG/VitaminG/VitaminGApp.swift:56-61`
**Issue:** `.onOpenURL` is attached to the `Group` that wraps both `ContentView` and `OnboardingView`. If a `vitaming://profile/<recordID>` URL arrives while `hasCompletedOnboarding` is `false`, `DeepLinkParser.recordID(from:)` succeeds and `router.pendingPublicProfileRecordID` is set. However, `ContentView` (which holds the `.sheet(item:)` binding) is not yet in the view tree, so the sheet is never presented. When onboarding finishes and `ContentView` appears, `pendingPublicProfileRecordID` is still non-nil, and the profile sheet for the deep link fires unexpectedly — potentially confusing the user who is in the middle of onboarding setup.

**Fix:** Guard the deep-link handler behind `hasCompletedOnboarding`:
```swift
.onOpenURL { url in
    guard hasCompletedOnboarding else { return }
    if let recordID = DeepLinkParser.recordID(from: url) {
        router.pendingPublicProfileRecordID = recordID
    }
}
```

---

### WR-03: `fetchOverride` testability seam exposed in production builds

**File:** `VitaminG/VitaminG/VitaminG/ViewModels/PublicProfileViewModel.swift:23`
**Issue:** `var fetchOverride: ((String) async throws -> (String?, String?))? = nil` is a public mutable property on the production `@Observable` class with no compile-time guard. Any code in the app — accidentally or maliciously — could inject an alternative fetch closure at runtime. CLAUDE.md security requirement states all inputs must be validated; production classes should not carry test-only mutation points.

**Fix:** Wrap in a `DEBUG` compiler flag:
```swift
#if DEBUG
var fetchOverride: ((String) async throws -> (String?, String?))? = nil
#endif
```
And update all call sites:
```swift
#if DEBUG
if let override = fetchOverride {
    let (d, a) = try await override(recordID)
    result = (displayName: d, avatarColorHex: a)
} else {
    result = try await ProfileSharingService.fetchProfile(recordID: recordID)
}
#else
result = try await ProfileSharingService.fetchProfile(recordID: recordID)
#endif
```

---

### WR-04: Flaky timing-based async assertions in PublicProfileViewModelTests

**File:** `VitaminG/VitaminG/VitaminGTests/PublicProfileViewModelTests.swift:29`
**Issue:** Three tests call `try await Task.sleep(nanoseconds: 50_000_000)` (50ms) after firing `sut.fetchProfile(recordID:)` and then assert on the resulting state. This pattern is inherently racey: on a slow CI host or under memory pressure, 50ms may not be sufficient for the `Task` to complete, producing a false negative. The test for `test_initialState_isLoading` would also pass spuriously since the Task hasn't completed yet.

**Fix:** Make `fetchProfile` return a `Task` that tests can `await`, or expose an `async` test hook. Alternatively, refactor `fetchProfile` to be `async` internally while keeping the fire-and-forget public API via a wrapper, and test the `async` variant directly:
```swift
// In tests — if fetchProfile becomes async:
await sut.fetchProfile(recordID: "abc123")
if case .loaded(let name, let hex) = sut.state { ... }
```
If keeping the current fire-and-forget design, use `XCTestExpectation` with a state-change observation rather than a fixed sleep.

---

## Info

### IN-01: No length cap on `recordID` returned by `DeepLinkParser`

**File:** `VitaminG/VitaminG/VitaminG/Services/DeepLinkParser.swift:14`
**Issue:** `url.pathComponents.dropFirst().first` returns the raw decoded path component with no upper-bound on length. A crafted URL (e.g., `vitaming://profile/<1MB string>`) allocates a large string in app memory before any downstream rejection by `CKRecord.ID`. CLAUDE.md requires "strict character limits and validation" on all string inputs.

**Fix:** Add a length guard consistent with CKRecord.ID constraints (record names are limited to 255 characters):
```swift
guard url.scheme == DeepLinkBuilder.scheme,
      url.host == "profile",
      let recordID = url.pathComponents.dropFirst().first,
      !recordID.isEmpty,
      recordID.count <= 255 else { return nil }
```

---

### IN-02: Dead `case .publicProfile` arm in NavigationStack `navigationDestination`

**File:** `VitaminG/VitaminG/VitaminG/Views/ContentView.swift:62-63`
**Issue:** The `case .publicProfile:` arm in `navigationDestination(for:)` returns `EmptyView()` with a comment that the sheet path handles it. This is correct by design (per D-04/D-05), but silently swallowing a push of `.publicProfile` onto the NavigationStack means any caller that accidentally does `router.navigate(to: .publicProfile(recordID: "x"))` will push an invisible `EmptyView` onto the stack without any diagnostic or runtime warning. This creates a silent failure mode.

**Fix:** Log a warning in debug builds to catch accidental misuse:
```swift
case .publicProfile:
    #if DEBUG
    let _ = { assertionFailure("publicProfile should never be pushed onto NavigationStack — use router.pendingPublicProfileRecordID instead") }()
    #endif
    EmptyView()
```

---

### IN-03: Magic brand orange color value duplicated in `PublicProfileView`

**File:** `VitaminG/VitaminG/VitaminG/Views/PublicProfileView.swift:23,40`
**Issue:** `Color(red: 0.98, green: 0.55, blue: 0.27)` appears twice in `PublicProfileView` with no named constant. Per CLAUDE.md conventions, magic numbers should be named constants to ensure consistency across views.

**Fix:** Define a shared color constant (e.g., in an `AppColors` or `Color+App` extension) and reference it:
```swift
// Color+App.swift
extension Color {
    static let vitaminOrange = Color(red: 0.98, green: 0.55, blue: 0.27)
}

// In PublicProfileView:
.tint(.vitaminOrange)
.foregroundStyle(.vitaminOrange)
```

---

### IN-04: Non-CKError catch-all uses generic network message for all unknown errors

**File:** `VitaminG/VitaminG/VitaminG/ViewModels/PublicProfileViewModel.swift:46-48`
**Issue:** The final `catch` block maps all non-CKError exceptions (e.g., a programming error, a cast failure, a permission denial) to the same "check your internet connection" message. This can mislead users when the actual failure has nothing to do with connectivity.

**Fix:** Use a more neutral fallback message for the generic catch:
```swift
} catch {
    state = .error(message: "Couldn't load profile. Please try again.")
}
```

---

_Reviewed: 2026-04-20_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
