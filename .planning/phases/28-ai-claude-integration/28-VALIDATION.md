---
phase: 28
slug: ai-claude-integration
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-06
---

# Phase 28 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (existing in VitaminGTests target) |
| **Config file** | No explicit config — Xcode scheme handles test execution |
| **Quick run command** | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VitaminGTests/AIProxyServiceTests -only-testing:VitaminGTests/AIViewModelTests` |
| **Full suite command** | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~60 seconds (quick), ~3–5 minutes (full) |

---

## Sampling Rate

- **After every task commit:** Run quick command (AIProxyServiceTests + AIViewModelTests only)
- **After every plan wave:** Run full suite
- **Before `/gsd:verify-work`:** Full suite must be green + human real-device verification
- **Max feedback latency:** 60 seconds (quick run)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| AIProxyService protocol + service | 01 | 0 | AI-03, AI-01, AI-02 | T-28-01 | Token validates; Anthropic key never in iOS binary | unit | `xcodebuild test ... -only-testing:VitaminGTests/AIProxyServiceTests` | ❌ Wave 0 | ⬜ pending |
| fetchSuggestions mock success | 01 | 1 | AI-01 | — | Returns 3 items | unit | same | ❌ Wave 0 | ⬜ pending |
| fetchSuggestions fallback | 01 | 1 | AI-01 | — | Returns staticSuggestions on URLError | unit | same | ❌ Wave 0 | ⬜ pending |
| Suggestions cache hit | 01 | 1 | AI-01 | — | Returns from UserDefaults, no network call | unit | same | ❌ Wave 0 | ⬜ pending |
| fetchMotivation fallback | 02 | 1 | AI-02 | — | Returns VGQuoteBank text on network error | unit | same | ❌ Wave 0 | ⬜ pending |
| fetchMotivation cache hit | 02 | 1 | AI-02 | — | Reads UserDefaults without network call | unit | same | ❌ Wave 0 | ⬜ pending |
| motivationLabel logic | 02 | 1 | AI-02 | — | "YOUR DOSE" for .claude, "TODAY'S DOSE" for .fallback | unit | `xcodebuild test ... -only-testing:VitaminGTests/AIViewModelTests` | ❌ Wave 0 | ⬜ pending |
| addSuggestion goal tier | 03 | 2 | AI-01 | — | Goal inserted with tier .immediate | unit | same | ❌ Wave 0 | ⬜ pending |
| addedSuggestionIndices state | 03 | 2 | AI-01 | — | Updated after successful insert | unit | same | ❌ Wave 0 | ⬜ pending |
| Date key format | 01/02 | 1 | AI-01, AI-02 | — | Keys match "vg_motivation_YYYY-MM-DD" / "vg_suggestions_YYYY-MM-DD" | unit | same | ❌ Wave 0 | ⬜ pending |
| Worker deployment | 00 | 0 | AI-03 | T-28-01 | Worker reachable at HTTPS URL, API key server-side only | integration | `curl -X POST <workerURL>/ai ...` (manual) | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `VitaminGTests/AIProxyServiceTests.swift` — stub file with test cases for AI-01, AI-02 cache hit/miss, fallback paths; uses mock conforming to `AIProxyServiceProtocol`
- [ ] `VitaminGTests/AIViewModelTests.swift` — stub file for motivationLabel, addedSuggestionIndices, goal insert tier tests; uses `UserDefaults(suiteName: UUID().uuidString)` for isolation
- [ ] `worker/test-worker.sh` — curl smoke-test script for manual Worker endpoint validation after `wrangler deploy`

*No new test fixtures needed — tests use `UserDefaults(suiteName: UUID().uuidString)` for isolation, matching existing ExploreViewModelTests pattern.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Anthropic API key absent from iOS binary | AI-03 | Key is server-side in Cloudflare env var; iOS binary `strings` scan needed | `strings <path-to-ipa> | grep -i anthropic` — must return zero results |
| Worker reachable at deployed HTTPS URL | AI-03 | Worker URL unknown until `wrangler deploy` runs | curl smoke test using `worker/test-worker.sh` |
| End-to-end Claude response quality | AI-01, AI-02 | Claude output is non-deterministic; quality is subjective | Real-device test: check suggestions are coherent goal titles; check motivation references streak |
| Fallback-to-Claude transition after Worker downtime | AI-01, AI-02 | Requires simulating network failure or Worker unavailability | Disable network on device, verify static fallback shows; re-enable, verify Claude response on next foreground + date miss |
| GoalSuggestionsCard second position in Explore scroll | AI-01 | Visual layout requires real device or simulator | Open Explore tab, confirm card appears after GoalGifterCard and before MoodPromptCard |
| "YOUR DOSE" label when Claude content is live | AI-02 | Requires real Worker response | Ensure fresh date (first launch of the day), verify Home tab shows "YOUR DOSE" label |

---

## Test Protocol for AIProxyService

The `AIProxyService` must conform to a protocol for testability (no deployed Worker needed for unit tests):

```swift
// Protocol defined in Wave 0
protocol AIProxyServiceProtocol {
    func fetchMotivation(goals: [GoalPayload], streak: Int) async -> MotivationResult
    func fetchSuggestions(goals: [GoalPayload]) async -> [String]
}
// Tests inject MockAIProxyService conforming to this protocol
// No network call; returns fixed data for deterministic unit tests
```
