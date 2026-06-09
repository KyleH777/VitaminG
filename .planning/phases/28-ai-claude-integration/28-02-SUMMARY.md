---
phase: 28-ai-claude-integration
plan: "02"
subsystem: ai-proxy
status: complete
tags:
  - aiproxyservice
  - aiviewmodel
  - tdd-green
  - unit-tests
dependency_graph:
  requires:
    - "28-01 (Cloudflare Worker deployed at https://vg-ai-proxy.kileharrington.workers.dev/ai)"
  provides:
    - "AIProxyService.swift — singleton @Observable network service with protocol, date-key cache, fallback"
    - "AIViewModel.swift — @MainActor @Observable ViewModel for AI state in HomeView and ExploreView"
    - "Wave 0 tests GREEN (12/12 AIProxyServiceTests + AIViewModelTests)"
  affects:
    - "Plans 28-03, 28-04 (UI wiring — uses AIProxyService.shared and AIViewModel via @State)"
tech_stack:
  added:
    - "URLSession async/await POST pattern with JSON Codable types (AIProxyService)"
    - "ISO8601DateFormatter YYYY-MM-DD date-keyed UserDefaults caching"
    - "JSONEncoder/JSONDecoder [String] → Data round-trip for suggestions (Pitfall 1 prevention)"
    - "AIProxyServiceProtocol seam for mock injection in unit tests"
  patterns:
    - "Singleton pattern: static let shared = AIProxyService(); private init() {} (mirrors WatchSessionManager)"
    - "@MainActor @Observable final class AIViewModel (mirrors ExploreViewModel)"
    - "WidgetDataProvider.build() as single source of truth for goal payload construction"
    - "Silent fallback: VGQuoteBank.todaysQuote() for motivation, staticSuggestions for suggestions"
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/Services/AIProxyService.swift
    - VitaminG/VitaminG/VitaminG/ViewModels/AIViewModel.swift
  modified: []
decisions:
  - "PBXFileSystemSynchronizedRootGroup auto-includes new Swift files — no manual pbxproj edits required; Xcode 16 synchronized groups handle Services/ and ViewModels/ subdirectories automatically"
  - "AIProxyService.shared warning (main actor-isolated static) is a warning, not error — accepted at current Swift language mode; will be addressed if Swift 6 mode is adopted"
  - "Pre-existing test failure PublicProfileViewModelTests.test_fetchProfile_networkFailure_transitionsToError is out of scope (CloudKit error message mismatch pre-existed these changes)"
metrics:
  duration: "~17 minutes"
  completed_tasks: 2
  total_tasks: 2
  completed_date: "2026-06-08"
---

# Phase 28 Plan 02: AIProxyService and AIViewModel Implementation

**One-liner:** AIProxyService singleton with @Observable, protocol seam, date-key UserDefaults cache (motivation as String, suggestions as JSON Data), VGQuoteBank fallback; AIViewModel @MainActor @Observable with motivationLabel, refresh methods via WidgetDataProvider.build(); 12/12 Wave 0 tests GREEN.

**Status:** COMPLETE — 2/2 tasks done, 12/12 Wave 0 tests GREEN, no regressions in AI-related tests.

---

## Completed Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create AIProxyService.swift with protocol, types, singleton, and fallback paths | `cb584d0` | VitaminG/Services/AIProxyService.swift |
| 2 | Create AIViewModel.swift bridging AIProxyService to Views | `570dd49` | VitaminG/ViewModels/AIViewModel.swift |

---

## Test Results

### AIProxyServiceTests (6/6 GREEN)

| Test | Description | Result |
|------|-------------|--------|
| test_fetchMotivation_cacheHit_returnsWithoutNetwork | Seeds UserDefaults key, asserts .claude result without network | PASSED |
| test_fetchMotivation_networkError_returnsFallback | MockAIProxyService returns .fallback, asserts !isClaude and non-empty text | PASSED |
| test_fetchSuggestions_cacheHit_returnsCachedArray | JSON-encoded ["A","B","C"] to Data, asserts round-trip returns same array | PASSED |
| test_fetchSuggestions_networkError_returnsStaticFallback | Mock returns staticSuggestions, asserts canonical 3-item list | PASSED |
| test_motivationKey_matchesYYYYMMDDFormat | Key matches ^vg_motivation_\\d{4}-\\d{2}-\\d{2}$ regex | PASSED |
| test_suggestionsKey_matchesYYYYMMDDFormat | Key matches ^vg_suggestions_\\d{4}-\\d{2}-\\d{2}$ regex | PASSED |

### AIViewModelTests (6/6 GREEN)

| Test | Description | Result |
|------|-------------|--------|
| test_motivationLabel_claudeResult_returnsYourDose | .claude("hi") → "YOUR DOSE" | PASSED |
| test_motivationLabel_fallbackResult_returnsTodaysDose | .fallback("hi") → "TODAY'S DOSE" | PASSED |
| test_addedSuggestionIndices_initiallyEmpty | Empty Set on init | PASSED |
| test_addedSuggestionIndices_insertReflected | insert(0) → contains(0) && !contains(1) | PASSED |
| test_initialSuggestions_areStaticFallback | suggestions == AIProxyService.staticSuggestions | PASSED |
| test_initialMotivation_isFallback | motivationResult.isClaude == false | PASSED |

**Combined: 12/12 Wave 0 tests GREEN.**

---

## Plan 01 Values Confirmed

- **workerURL:** `https://vg-ai-proxy.kileharrington.workers.dev/ai` — matches 28-01-SUMMARY.md Deployment Details
- **workerToken:** `020A3129-9FDB-4817-8C8F-EA1A27F59A38` — matches SHARED_TOKEN recorded in 28-01-SUMMARY.md (T-28-02 cooperative mitigation)

---

## Security Verification

- `grep -r "sk-ant-" VitaminG/VitaminG/VitaminG/` → 0 results (T-28-01: no Anthropic API key in iOS source)
- `grep -r "api.anthropic.com" VitaminG/VitaminG/VitaminG/` → 0 results (iOS code contacts only the Cloudflare Worker URL)

---

## Protocol Seam for Future Plans

`AIProxyServiceProtocol` defines:
```swift
protocol AIProxyServiceProtocol {
    func fetchMotivation(goals: [GoalPayload], streak: Int) async -> MotivationResult
    func fetchSuggestions(goals: [GoalPayload]) async -> [String]
}
```
Plans 28-03 and 28-04 use `AIProxyService.shared` (singleton) for UI wiring. Test targets can inject `MockAIProxyService` (already defined inline in AIProxyServiceTests.swift) without network.

---

## Deviations from Plan

### Xcode Target Registration

**Deviation:** The plan's acceptance criteria required manually editing `project.pbxproj` to add AIProxyService.swift and AIViewModel.swift to the VitaminG target's PBXSourcesBuildPhase, and AIProxyServiceTests.swift/AIViewModelTests.swift to the VitaminGTests target.

**Actual approach:** The VitaminG and VitaminGTests targets both use `PBXFileSystemSynchronizedRootGroup` (Xcode 16 automatic file synchronization). Files placed in `VitaminG/Services/` and `VitaminG/ViewModels/` subdirectories are automatically included in the VitaminG target. Similarly, VitaminGTests directory files are auto-included in the test target. No manual pbxproj edits were required — the synchronized group handled registration automatically.

**Verification:** `xcodebuild test -scheme VitaminG` confirmed both new source files compiled and both test files ran successfully.

### Pre-existing Test Failure (Out of Scope)

`PublicProfileViewModelTests.test_fetchProfile_networkFailure_transitionsToError` fails due to a CloudKit error message mismatch ("Couldn't load this profile. Check your connection and try again." vs. the expected text). This failure pre-existed Plan 28-02 changes and is unrelated to AIProxyService or AIViewModel. It has been logged to deferred-items per scope boundary rule.

---

## Known Stubs

None. AIProxyService and AIViewModel are fully functional with real network paths, UserDefaults cache, and fallbacks wired. Wave 0 tests validate all core paths without network dependency.

---

## Threat Flags

No new security-relevant surfaces introduced beyond the threat model declared in the plan.

| Flag | File | Description |
|------|------|-------------|
| T-28-01 mitigated | Services/AIProxyService.swift | No Anthropic API key or api.anthropic.com URL in iOS source; only Cloudflare Worker URL |
| T-28-02 mitigated | Services/AIProxyService.swift | workerToken = 020A3129-9FDB-4817-8C8F-EA1A27F59A38 matches SHARED_TOKEN from Plan 01 |
| T-28-04 mitigated | Services/AIProxyService.swift | Cache keys namespaced vg_motivation_/ vg_suggestions_ with YYYY-MM-DD suffix |
| T-28-05 mitigated | Services/AIProxyService.swift | fetchSuggestions writes JSONEncoder().encode([String]) → Data; reads via JSONDecoder |
| T-28-08 mitigated | Services/AIProxyService.swift | URLRequest.timeoutInterval = 10; all catch blocks return valid fallback values |

---

## Self-Check: PASSED

- `VitaminG/VitaminG/VitaminG/Services/AIProxyService.swift` — FOUND
- `VitaminG/VitaminG/VitaminG/ViewModels/AIViewModel.swift` — FOUND
- Commit `cb584d0` (Task 1 AIProxyService) — FOUND in git log
- Commit `570dd49` (Task 2 AIViewModel) — FOUND in git log
- 12/12 Wave 0 tests GREEN — VERIFIED via xcodebuild test
- workerURL matches 28-01-SUMMARY.md — VERIFIED
- workerToken matches SHARED_TOKEN — VERIFIED
- No sk-ant- in iOS source — VERIFIED (grep returns 0)
- No api.anthropic.com in iOS source — VERIFIED (grep returns 0)
