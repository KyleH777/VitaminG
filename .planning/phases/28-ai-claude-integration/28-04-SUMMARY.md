---
phase: 28-ai-claude-integration
plan: "04"
subsystem: explore-ai-view
tags:
  - goalsuggestions
  - exploreview
  - ai-wiring
  - swiftui
  - swiftdata
  - observable
dependency_graph:
  requires:
    - "28-02 (AIProxyService.swift and AIViewModel.swift; 12/12 Wave 0 tests GREEN)"
    - "28-03 (AIMotivationSection pattern established; @Bindable AIViewModel wiring confirmed)"
  provides:
    - "GoalSuggestionsCard.swift — SwiftUI card with sparkles header, 3 suggestion rows, Add Goal capsule button, checkmark transition, redacted loading skeleton"
    - "ExploreView.swift — GOALS FOR YOU section inserted between Today's Gift and Daily Mood; .task fetch trigger wired; @Query completionEvents added"
  affects:
    - "Explore tab UX — second section now shows AI-personalized goal suggestions"
    - "AI-01 requirement satisfied — Claude-generated goal suggestions in Explore tab with single-tap add and daily cache"
tech_stack:
  added:
    - "@Bindable var aiViewModel: AIViewModel pattern (GoalSuggestionsCard)"
    - "@Query private var completionEvents: [CompletionEvent] added to ExploreView"
    - ".task modifier on ExploreView ScrollView for async suggestions fetch"
    - "UIImpactFeedbackGenerator(style: .medium) haptic on goal add"
  patterns:
    - "GoalSuggestionsCard mirrors GoalGifterCard shell exactly (padding 16, cornerRadius 20, LinearGradient background)"
    - "addSuggestion: GoalInput(tier: .immediate, category: .other) via GoalViewModel.addGoal — identical pattern to GoalGifterCard.addGiftedGoal"
    - ".redacted(reason: .placeholder) on suggestion text rows while isLoadingSuggestions == true"
    - "addedSuggestionIndices.contains(index) gate hides Add Goal button after first successful insert (T-28-18)"
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/Views/Explore/GoalSuggestionsCard.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Views/Explore/ExploreView.swift
key_decisions:
  - "PBXFileSystemSynchronizedRootGroup auto-includes Views/Explore/GoalSuggestionsCard.swift — no manual pbxproj edits required (same as Plans 28-02 and 28-03)"
  - ".task modifier placed on the ScrollView in existingScrollContent so it fires once on ExploreView appear (Pitfall 6 compliant)"
  - "@Query private var completionEvents: [CompletionEvent] added to ExploreView to pass real event data to refreshSuggestionsIfNeeded (per plan Task 2 note)"
  - "GoalSuggestionsCard uses .padding(16) (not 18) for 4-point grid compliance per UI-SPEC §Spacing"

requirements-completed:
  - AI-01

metrics:
  duration: "~25 minutes (Tasks 1 and 2 complete; Task 3 is human checkpoint pending)"
  completed_tasks: 2
  total_tasks: 3
  completed_date: "2026-06-08"
---

# Phase 28 Plan 04: GoalSuggestionsCard and ExploreView AI Wiring

**GoalSuggestionsCard.swift wired into ExploreView between Today's Gift and Daily Mood — sparkles header, 3 AI suggestion rows with Add Goal capsule buttons transitioning to sage checkmarks, redacted loading skeleton, daily UserDefaults cache via AIViewModel; AI-01 code complete, awaiting human verification.**

## Performance

- **Duration:** ~25 minutes (Tasks 1 and 2 complete; Task 3 is human checkpoint pending)
- **Started:** 2026-06-08
- **Completed:** 2026-06-08 (code tasks complete; human checkpoint pending)
- **Tasks:** 2 of 3 complete (Task 3 is checkpoint:human-verify)
- **Files modified:** 2

## Accomplishments

- Created `GoalSuggestionsCard.swift` with sparkles header, 3-row suggestion layout, Add Goal capsule buttons, checkmark.circle.fill added state, redacted loading skeleton, GoalInput(tier: .immediate, category: .other) insertion via GoalViewModel.addGoal, UIImpactFeedbackGenerator medium haptic
- Modified `ExploreView.swift` to add @State aiViewModel, @Query completionEvents, insert GOALS FOR YOU section (second position between Today's Gift and Daily Mood), and wire .task fetch trigger
- Build succeeded (xcodebuild BUILD SUCCEEDED); 129/130 tests pass (1 pre-existing PublicProfileViewModelTests failure out of scope)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create GoalSuggestionsCard.swift** - `9bd4484` (feat)
2. **Task 2: Insert GOALS FOR YOU section into ExploreView** - `c0d057c` (feat)
3. **Task 3: Human checkpoint — visual verification** - checkpoint pending

## Completed Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create GoalSuggestionsCard.swift with 3-row layout, Add Goal button, checkmark transition | `9bd4484` | VitaminG/Views/Explore/GoalSuggestionsCard.swift |
| 2 | Insert GOALS FOR YOU section and GoalSuggestionsCard into ExploreView + .task fetch | `c0d057c` | VitaminG/Views/Explore/ExploreView.swift |

## Files Created/Modified

- `VitaminG/VitaminG/VitaminG/Views/Explore/GoalSuggestionsCard.swift` — SwiftUI card with @Bindable AIViewModel, sparkles header (serif 20pt title, system 14pt subtitle), 3 suggestion rows with Add Goal capsule buttons, checkmark.circle.fill added state, .redacted loading skeleton, addSuggestion GoalInput insertion
- `VitaminG/VitaminG/VitaminG/Views/Explore/ExploreView.swift` — @State aiViewModel added, @Query completionEvents added, sectionLabel("GOALS FOR YOU") + GoalSuggestionsCard(aiViewModel:) inserted between GoalGifterCard and MoodPromptCard, .task modifier on ScrollView

---

## Build and Test Results

### Build
- `xcodebuild build -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 17'` — **BUILD SUCCEEDED**
- Pre-existing warnings only (AIProxyService.shared main actor isolation — accepted in 28-02 SUMMARY)

### Tests
- 129/130 tests pass
- 12/12 Wave 0 AI tests GREEN (6 AIProxyServiceTests + 6 AIViewModelTests — unchanged)
- `PublicProfileViewModelTests.test_fetchProfile_networkFailure_transitionsToError` — pre-existing failure (CloudKit error message mismatch, documented in 28-02 and 28-03 SUMMARYs, out of scope)

---

## Source Assertions

All Task 1 and Task 2 acceptance criteria assertions PASSED:

| Assertion | Result |
|-----------|--------|
| `struct GoalSuggestionsCard: View` exists | PASS |
| `@Bindable var aiViewModel: AIViewModel` | PASS |
| `@Environment(\.modelContext) private var modelContext` | PASS |
| `@State private var goalVM = GoalViewModel()` | PASS |
| `Text("Add Goal")` button label | PASS |
| Does NOT contain `Text("Add")` old label | PASS |
| `Image(systemName: "sparkles")` header icon | PASS |
| `Image(systemName: "checkmark.circle.fill")` added state | PASS |
| `tier: .immediate` | PASS |
| `category: .other` | PASS |
| `try? goalVM.addGoal(input: input, context: modelContext)` | PASS |
| `aiViewModel.addedSuggestionIndices.insert(index)` | PASS |
| `UIImpactFeedbackGenerator(style: .medium).impactOccurred()` | PASS |
| `withAnimation(.easeInOut(duration: 0.2))` | PASS |
| `.padding(16)` present, `.padding(18)` absent | PASS |
| `cornerRadius: 20` | PASS |
| `.accessibilityLabel("Add goal:` | PASS |
| `.accessibilityLabel("Added"` | PASS |
| `.redacted(reason: .placeholder)` | PASS |
| ExploreView `@State private var aiViewModel = AIViewModel()` | PASS |
| ExploreView `@Query private var completionEvents: [CompletionEvent]` | PASS |
| ExploreView `sectionLabel("GOALS FOR YOU")` | PASS |
| ExploreView `GoalSuggestionsCard(aiViewModel: aiViewModel)` | PASS |
| ExploreView `.task` with `refreshSuggestionsIfNeeded(goals:` | PASS |
| Section ordering: GoalGifterCard < GOALS FOR YOU < GoalSuggestionsCard < MoodPromptCard | PASS (lines 59 < 62 < 63 < 67) |
| GoalSuggestionsCard NOT in search branch | PASS (card at line 63, search branch ends at line ~46) |

---

## Design Contract Compliance

- `.padding(16)` on GoalSuggestionsCard outer shell (UI-SPEC §Spacing lg = 16pt, 4-point grid)
- `cornerRadius: 20` matching GoalGifterCard outer shell
- `LinearGradient(colors: [accentTerra.opacity(0.12), accentTerra.opacity(0.04)])` matching GoalGifterCard background
- `VGTheme.serif(20)` for card title "Goals suggested for you"
- `.system(size: 14)` for card subtitle "Based on your goals and interests" in textMuted
- `.system(size: 16)` for suggestion body text with `.lineSpacing(4)` and `.fixedSize(horizontal: false, vertical: true)`
- `.system(size: 14, weight: .semibold)` for "Add Goal" button label in white on accentTerra Capsule
- `VGTheme.accentSage` for `checkmark.circle.fill` added state icon
- `.padding(.vertical, 16)` per row (exceeds 44pt HIG minimum touch target)
- `Divider().foregroundStyle(VGTheme.separator)` between rows (not after last row)

---

## Deviations from Plan

### Xcode Target Registration

**Deviation:** The plan listed `VitaminG/VitaminG.xcodeproj/project.pbxproj` as a file to modify for registering `GoalSuggestionsCard.swift`.

**Actual approach:** Identical to Plans 28-02 and 28-03 — the VitaminG target uses `PBXFileSystemSynchronizedRootGroup` (Xcode 16 automatic file synchronization). Files placed in `VitaminG/Views/Explore/` subdirectory are automatically included in the VitaminG target. No manual pbxproj edits were required. Build confirmed the new file compiled correctly.

### iPhone 16 Simulator Not Available

**Deviation:** The plan verification steps specify `platform=iOS Simulator,name=iPhone 16`. This simulator is not installed — only iPhone 17 simulators are available (OS 26.4.1 and 26.5).

**Action:** Used `platform=iOS Simulator,name=iPhone 17` for automated build and test verification. Human verification in Task 3 should use whichever simulator is available.

---

## Human Verification Results

**Task 3 checkpoint: PENDING** — awaiting human verification of Checks A through F on simulator.

| Check | Description | Result |
|-------|-------------|--------|
| A — Position and label | GOALS FOR YOU between Today's Gift and Daily Mood | PENDING |
| B — Claude path | 3 suggestions fetched and cached | PENDING |
| C — Fallback path | 3 static suggestions offline | PENDING |
| D — Add Goal interaction | Checkmark transition, goal in QuickWin tier | PENDING |
| E — Search branch gating | Card absent while searching | PENDING |
| F — Accessibility | VoiceOver announces correctly | PENDING |

---

## Decisions Made

- `PBXFileSystemSynchronizedRootGroup` auto-includes `Views/Explore/GoalSuggestionsCard.swift` — no manual pbxproj edits required (same as Plans 28-02 and 28-03)
- `.task` modifier placed on the ScrollView in `existingScrollContent` so it fires once on ExploreView appear (Pitfall 6 compliant — not from VitaminGApp.init)
- `@Query private var completionEvents: [CompletionEvent]` added to ExploreView to pass real event data to `refreshSuggestionsIfNeeded` so Claude prompt is personalized per AI-01
- `GoalSuggestionsCard` uses `.padding(16)` (not GoalGifterCard's 18pt) for 4-point grid compliance per UI-SPEC §Spacing

---

## Known Stubs

None. GoalSuggestionsCard reads live state from AIViewModel, which calls AIProxyService with real network path, UserDefaults cache, and staticSuggestions fallback. All paths are fully functional.

---

## Threat Surface Compliance

| Threat | Status |
|--------|--------|
| T-28-14: Claude suggestion text persisted as Goal.title | Mitigated — flows through GoalViewModel.addGoal validated CRUD path |
| T-28-15: Card blocked on slow Worker response | Mitigated — .redacted loading state + 10s timeout + staticSuggestions fallback |
| T-28-17: Stored XSS via Claude text in SwiftUI Text | Mitigated — SwiftUI Text() renders plain text only |
| T-28-18: Duplicate-tap goal insertion | Mitigated — addedSuggestionIndices.contains(index) gate hides Add Goal button after first insert |

---

## Issues Encountered

None significant. Two minor deviations handled automatically:
1. iPhone 16 simulator unavailable — used iPhone 17 (functionally identical for UI testing)
2. No manual pbxproj edits needed — Xcode 16 synchronized groups auto-include new Swift files

## Next Phase Readiness

- AI-01 view-layer code is complete and build-verified
- Human checkpoint (Task 3, Checks A–F) must pass before Phase 28 is fully complete
- Once Task 3 checkpoint is approved, Phase 28 (AI Claude Integration) is fully complete
- AI-02 (Home tab motivation) was completed in Plan 28-03
- AI-01 (Explore tab suggestions) code complete in this plan, pending final human verification

---

## Threat Flags

None — no new security-relevant surfaces beyond what the plan's threat model declared.

---

## Self-Check: PASSED

- `VitaminG/VitaminG/VitaminG/Views/Explore/GoalSuggestionsCard.swift` — FOUND (created in Task 1, commit `9bd4484`)
- `VitaminG/VitaminG/VitaminG/Views/Explore/ExploreView.swift` — FOUND (modified in Task 2, commit `c0d057c`)
- Commit `9bd4484` (Task 1 GoalSuggestionsCard) — VERIFIED in git log
- Commit `c0d057c` (Task 2 ExploreView) — VERIFIED in git log
- BUILD SUCCEEDED — VERIFIED via xcodebuild
- 129/130 tests pass — VERIFIED (1 pre-existing failure out of scope)

---
*Phase: 28-ai-claude-integration*
*Completed: 2026-06-08 (code tasks; human verification pending)*
