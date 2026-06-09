---
phase: 28-ai-claude-integration
plan: "03"
subsystem: home-ai-view
status: partial-checkpoint
tags:
  - aimotivationsection
  - homeview
  - ai-wiring
  - checkpoint-pending
dependency_graph:
  requires:
    - "28-02 (AIProxyService.swift and AIViewModel.swift created; 12/12 Wave 0 tests GREEN)"
  provides:
    - "AIMotivationSection.swift — SwiftUI View with YOUR DOSE/TODAY'S DOSE label, redacted loading state, accessibility labels"
    - "HomeView.swift — quoteSection replaced with AIMotivationSection; .task trigger wired"
  affects:
    - "Home tab UX — motivation card now sources copy from Claude via AIViewModel"
    - "Plans 28-04 (GoalSuggestionsCard in ExploreView — same AIViewModel pattern)"
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
decisions:
  - "PBXFileSystemSynchronizedRootGroup auto-includes Views/Home/AIMotivationSection.swift — no manual pbxproj edits required (same as Plan 02)"
  - ".task modifier placed on outermost ZStack container so it fires once on HomeView appear"
  - "Comment-only references to YOUR DOSE / TODAY'S DOSE strings removed from AIMotivationSection.swift to pass literal-string acceptance assertions; label logic lives exclusively in AIViewModel.motivationLabel"
metrics:
  duration: "~12 minutes"
  completed_tasks: 1
  total_tasks: 2
  completed_date: "2026-06-08"
---

# Phase 28 Plan 03: AIMotivationSection and HomeView AI Wiring

**One-liner:** AIMotivationSection.swift created with @Bindable AIViewModel, YOUR DOSE/TODAY'S DOSE dynamic label (via motivationLabel computed property), redacted loading placeholder, and accessibility labels; HomeView.swift wired — quoteSection and todaysQuote dead code removed, .task trigger added, spacing changed 6→8 per UI-SPEC, .padding(.horizontal, 18) preserved.

**Status:** PARTIAL — Task 1 complete and committed; awaiting Task 2 human checkpoint verification.

---

## Completed Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create AIMotivationSection.swift and wire HomeView replacement + .task fetch trigger | `2db6131` | VitaminG/Views/Home/AIMotivationSection.swift, VitaminG/Views/HomeView.swift |

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

---

## Pending: Task 2 Human Checkpoint

The human checkpoint (Task 2) has not yet been verified. When the user confirms "approved", update this SUMMARY with:
- Confirmation that HomeView.swift now uses AIMotivationSection (DONE — Task 1)
- Confirmation that the four human verification checks (A, B, C, D) all passed
- Confirmation that .padding(.horizontal, 18) was preserved and spacing changed from 6 to 8 (DONE — Task 1)
- Note that AI-02 view-layer integration is complete; AI-01 view-layer remains for Plan 04

---

## Known Stubs

None. AIMotivationSection reads live state from AIViewModel, which calls AIProxyService with real network path, UserDefaults cache, and VGQuoteBank fallback. All paths are fully functional.

---

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| T-28-10 mitigated | Views/Home/AIMotivationSection.swift | Claude text rendered via SwiftUI Text() — no HTML/JS execution surface |
| T-28-12 mitigated | Views/Home/AIMotivationSection.swift | .redacted loading state shows while fetch in flight; on timeout, fallback fills — card never blocks |
