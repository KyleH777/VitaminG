---
phase: 28-ai-claude-integration
plan: "03"
subsystem: home-ai-view
tags:
  - aimotivationsection
  - homeview
  - ai-wiring
  - swiftui
  - observable
dependency_graph:
  requires:
    - "28-02 (AIProxyService.swift and AIViewModel.swift created; 12/12 Wave 0 tests GREEN)"
  provides:
    - "AIMotivationSection.swift — SwiftUI View with YOUR DOSE/TODAY'S DOSE label, redacted loading state, accessibility labels"
    - "HomeView.swift — quoteSection replaced with AIMotivationSection; .task trigger wired"
  affects:
    - "Home tab UX — motivation card now sources copy from Claude via AIViewModel"
    - "28-04 (GoalSuggestionsCard in ExploreView — same AIViewModel pattern)"
tech_stack:
  added:
    - "@Bindable var aiViewModel: AIViewModel pattern (AIMotivationSection)"
    - ".task modifier on ZStack body for async view lifecycle fetch trigger"
    - ".redacted(reason: .placeholder) for loading skeleton state"
  patterns:
    - "AIMotivationSection: @Bindable view component reads from AIViewModel @Observable state"
    - "HomeView .task modifier triggers refreshMotivationIfNeeded from view lifecycle (Pitfall 6 compliant)"
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/Views/Home/AIMotivationSection.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Views/HomeView.swift
key_decisions:
  - "PBXFileSystemSynchronizedRootGroup auto-includes Views/Home/AIMotivationSection.swift — no manual pbxproj edits required (same as Plan 02)"
  - ".task modifier placed on outermost ZStack container so it fires once on HomeView appear"
  - "Comment-only references to YOUR DOSE / TODAY'S DOSE strings removed from AIMotivationSection.swift to pass literal-string acceptance assertions; label logic lives exclusively in AIViewModel.motivationLabel"
requirements-completed:
  - AI-02
metrics:
  duration: "~30 minutes (including human verification)"
  completed_tasks: 2
  total_tasks: 2
  completed_date: "2026-06-08"
---

# Phase 28 Plan 03: AIMotivationSection and HomeView AI Wiring

**AIMotivationSection.swift wired into HomeView replacing quoteSection — Claude motivation card shows YOUR DOSE label with cached AI copy and TODAY'S DOSE fallback from VGQuoteBank; human verification approved all four checks (Claude path, fallback path, layout, accessibility).**

## Performance

- **Duration:** ~30 minutes (including human verification)
- **Started:** 2026-06-08
- **Completed:** 2026-06-08
- **Tasks:** 2 (1 auto + 1 checkpoint)
- **Files modified:** 2

## Accomplishments

- Created `AIMotivationSection.swift` with dynamic `YOUR DOSE`/`TODAY'S DOSE` label sourced from `AIViewModel.motivationLabel`, redacted loading skeleton, and full accessibility support
- Replaced `quoteSection` in `HomeView.swift` with `AIMotivationSection`; removed `quoteSection` and `todaysQuote` dead code; added `.task` trigger for `refreshMotivationIfNeeded`
- Human verification confirmed: Claude path (Check A), fallback path (Check B), layout regression-free (Check C), and VoiceOver accessibility (Check D)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create AIMotivationSection.swift and wire HomeView replacement + .task fetch trigger** - `2db6131` (feat)
2. **Task 2: Human checkpoint — all four checks approved** - checkpoint only (no commit)

## Completed Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create AIMotivationSection.swift and wire HomeView replacement + .task fetch trigger | `2db6131` | VitaminG/Views/Home/AIMotivationSection.swift, VitaminG/Views/HomeView.swift |
| 2 | Human checkpoint — YOUR DOSE/TODAY'S DOSE label switching, fallback, layout, accessibility | checkpoint approved | N/A |

## Files Created/Modified

- `VitaminG/VitaminG/VitaminG/Views/Home/AIMotivationSection.swift` - SwiftUI view with `@Bindable AIViewModel`, dynamic label, redacted loading state, and accessibility labels
- `VitaminG/VitaminG/VitaminG/Views/HomeView.swift` - `quoteSection` replaced with `AIMotivationSection`, `todaysQuote` removed, `.task` trigger added

---

## Build and Test Results

### Build
- `xcodebuild build -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 17'` — **BUILD SUCCEEDED**
- Pre-existing warnings only (AIProxyService.shared main actor isolation — documented in 28-02 SUMMARY as accepted)

### Tests
- 12/12 Wave 0 AI tests GREEN (6 AIProxyServiceTests + 6 AIViewModelTests — unchanged from Plan 02)
- `PublicProfileViewModelTests.test_fetchProfile_networkFailure_transitionsToError` — still failing (pre-existing, out of scope, documented in 28-02 SUMMARY)

---

## Source Assertions

All acceptance criteria assertions PASSED:

| Assertion | Result |
|-----------|--------|
| `struct AIMotivationSection: View` exists | PASS |
| `@Bindable var aiViewModel: AIViewModel` | PASS |
| `Text(aiViewModel.motivationLabel)` | PASS |
| `Text(aiViewModel.motivationResult.text)` | PASS |
| `spacing: 8` present, `spacing: 6` absent | PASS |
| `.padding(.horizontal, 18)` preserved | PASS |
| `.redacted(reason: .placeholder)` | PASS |
| `.accessibilityLabel("Daily motivation:` | PASS |
| No hardcoded `"TODAY'S DOSE"` literal | PASS |
| No hardcoded `"YOUR DOSE"` literal | PASS |
| HomeView `@State private var aiViewModel = AIViewModel()` | PASS |
| HomeView `AIMotivationSection(aiViewModel: aiViewModel)` | PASS |
| HomeView `.task` with `refreshMotivationIfNeeded(goals:events:)` | PASS |
| HomeView `private var quoteSection` REMOVED | PASS |
| HomeView `private var todaysQuote` REMOVED | PASS |

---

## Design Contract Compliance

- `.padding(.horizontal, 18)` preserved (UI-SPEC implementation note: do not change existing shell padding)
- `spacing: 8` (changed from 6 per UI-SPEC §Spacing 3xl = 8pt grid compliance)
- `.padding(.vertical, 16)` — preserved
- `.padding(.horizontal, 24)` outer horizontal — preserved
- `.padding(.top, 20)` top gap — preserved
- `VGTheme.accentTerra` 2pt left-border stripe — preserved
- `RoundedRectangle(cornerRadius: 14)` — preserved

---

## Deviations from Plan

### Xcode Target Registration

**Deviation:** The plan listed `VitaminG/VitaminG.xcodeproj/project.pbxproj` as a file to modify for registering `AIMotivationSection.swift`.

**Actual approach:** Identical to Plan 02 — the VitaminG target uses `PBXFileSystemSynchronizedRootGroup` (Xcode 16 automatic file synchronization). Files placed in `VitaminG/Views/Home/` subdirectory are automatically included in the VitaminG target. No manual pbxproj edits were required. Build confirmed the new file compiled correctly.

### iPhone 16 Simulator Not Available

**Deviation:** The plan verification step specifies `platform=iOS Simulator,name=iPhone 16`. This simulator is not installed on the current machine — only iPhone 17 simulators are available (OS 26.4.1 and 26.5).

**Action:** Used `platform=iOS Simulator,name=iPhone 17` for automated build and test verification. Human verification in Task 2 should use whichever simulator is available.

## Human Verification Results

**Task 2 checkpoint: APPROVED** — all four checks passed on simulator.

| Check | Description | Result |
|-------|-------------|--------|
| A — Claude path | YOUR DOSE label, Claude-generated text, cache hit on re-entry | PASSED |
| B — Fallback path | TODAY'S DOSE label, VGQuoteBank copy, never empty | PASSED |
| C — Layout | Card matches legacy quoteSection visually | PASSED |
| D — Accessibility | VoiceOver announces motivation text | PASSED |

**AI-02 view-layer integration is complete.** AI-01 view-layer (Explore tab goal suggestions) remains for Plan 04.

## Decisions Made

- `PBXFileSystemSynchronizedRootGroup` auto-includes `Views/Home/AIMotivationSection.swift` — no manual pbxproj edits required (same as Plan 02)
- `.task` modifier placed on outermost ZStack container so it fires once on HomeView appear
- Label string logic lives exclusively in `AIViewModel.motivationLabel`; no hardcoded "YOUR DOSE" or "TODAY'S DOSE" literals in the view

---

## Known Stubs

None. AIMotivationSection reads live state from AIViewModel, which calls AIProxyService with real network path, UserDefaults cache, and VGQuoteBank fallback. All paths are fully functional.

## Issues Encountered

None significant. Two minor deviations handled automatically:
1. iPhone 16 simulator unavailable — used iPhone 17 (functionally identical for UI testing)
2. No manual pbxproj edits needed — Xcode 16 synchronized groups auto-include new Swift files

## Next Phase Readiness

- AI-02 (Home tab motivation) is fully complete and human-verified
- Plan 28-04 (Explore tab goal suggestions, AI-01) is unblocked and can begin immediately
- `AIViewModel` and `AIProxyService` patterns established in this phase are directly reusable for `GoalSuggestionsCard`

---

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| T-28-10 mitigated | Views/Home/AIMotivationSection.swift | Claude text rendered via SwiftUI Text() — no HTML/JS execution surface |
| T-28-12 mitigated | Views/Home/AIMotivationSection.swift | .redacted loading state shows while fetch in flight; on timeout, fallback fills — card never blocks |

---

## Self-Check: PASSED

- `VitaminG/VitaminG/VitaminG/Views/Home/AIMotivationSection.swift` — created in Task 1 (commit `2db6131`)
- `VitaminG/VitaminG/VitaminG/Views/HomeView.swift` — modified in Task 1 (commit `2db6131`)
- Commit `2db6131` verified in git log
- Human checkpoint Task 2 approved with all four checks passed

---
*Phase: 28-ai-claude-integration*
*Completed: 2026-06-08*
