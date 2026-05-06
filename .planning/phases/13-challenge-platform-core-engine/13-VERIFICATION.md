---
phase: 13-challenge-platform-core-engine
verified: 2026-05-06T00:00:00Z
status: gaps_found
score: 2/6
overrides_applied: 0
gaps:
  - truth: "Challenge Discovery screen shows Featured Challenges (curated cards with community size), category browse, and 'Build Your Own' CTA — all driven by template data"
    status: failed
    reason: "No Discovery screen view exists. No ChallengesView, ChallengeDiscoveryView, or 5th Challenges tab in ContentView. ContentView has 4 tabs only (Goals/Stats/Wins/Profile). ContentView.swift has EmptyView stubs for .challengeDetail and .challengeCheckIn with comment 'Phase 13 — UI implemented in Phase 13 Wave 4'. Wave 4 plans (13-04, 13-05, 13-06) were never created or executed."
    artifacts:
      - path: "VitaminG/VitaminG/VitaminG/Views/ContentView.swift"
        issue: "4-tab TabView, no Challenges tab. challengeDetail and challengeCheckIn routes return EmptyView stubs."
    missing:
      - "ChallengeDiscoveryView (or equivalent) showing 3 featured challenge cards with community size, category browse, and 'Build Your Own' CTA"
      - "5th Challenges tab added to ContentView TabView (Goals · Stats · Wins · Challenges · Profile, flame.fill icon per D-04)"
      - "Navigation destination handlers replacing EmptyView stubs in ContentView"

  - truth: "Daily check-in flow is driven by check_in_type from the template (boolean / numeric / multi-step) with no type-specific branching in the engine layer"
    status: failed
    reason: "The engine layer (ChallengeViewModel) is type-blind and correct. However, no check-in UI exists — no CheckInView, no check-in sheet or modal. CHAL-09 requires the check-in FLOW (UI), not just the engine. The requirement explicitly says 'daily check-in flow' and the ROADMAP SC-4 says 'driven by check_in_type from the template ... in the engine layer'. The engine layer passes, but the flow UI is missing entirely. ContentView.challengeCheckIn route returns EmptyView."
    artifacts:
      - path: "VitaminG/VitaminG/VitaminG/Views/ContentView.swift"
        issue: "case .challengeCheckIn: EmptyView() — no check-in UI wired"
    missing:
      - "Check-in UI view adapting to checkInType (boolean toggle / numeric input / multi-step wizard)"
      - "Check-in modal/sheet wired to AppRoute.challengeCheckIn or pendingChallengeCheckInID"

  - truth: "Milestone array from template config triggers full-screen celebration (confetti + personalized message + badge saved to profile) at each configured trigger point"
    status: failed
    reason: "ChallengeViewModel.pendingMilestone fires correctly when totalCheckIns crosses a threshold and persists to milestoneHistoryJSON. However: (1) no full-screen celebration view (confetti + personalized message) exists anywhere in the codebase; (2) no badge-saving-to-profile logic exists — milestoneHistoryJSON stores threshold integers on UserChallenge but there is no code that writes a badge to UserProfile. The engine half works; the view half is entirely absent."
    artifacts:
      - path: "VitaminG/VitaminG/VitaminG/ViewModels/ChallengeViewModel.swift"
        issue: "pendingMilestone is set correctly, but no View consumes it to show celebration UI"
    missing:
      - "MilestoneCelebrationView (full-screen confetti + personalized message from MilestoneConfig.message)"
      - "Badge-saving-to-profile logic (write earned badge symbol to UserProfile on milestone)"
      - ".sheet or .fullScreenCover binding on pendingMilestone in a challenge-hosting view"
deferred: []
human_verification:
  - test: "Verify engine type-blindness is sufficient for CHAL-09 intent"
    expected: "If the verifier has misread SC-4 and 'no type-specific branching in the engine layer' was the only required truth (not the UI), SC-4 could pass. Review ROADMAP SC-4 wording."
    why_human: "ROADMAP SC-4 says 'daily check-in flow is driven by check_in_type from the template... with no type-specific branching in the engine layer'. The second clause (no branching) is verified. The first clause ('daily check-in flow') is ambiguous — does it require UI or just the engine dispatch?"
---

# Phase 13: Challenge Platform — Core Engine Verification Report

**Phase Goal:** A configurable challenge engine powers Featured and Custom Challenges — one template system drives all challenge types, check-ins, streak logic, milestone celebrations, and the discovery/check-in UI; no challenge type requires separate core logic
**Verified:** 2026-05-06
**Status:** GAPS FOUND — 3 of 6 success criteria failed; UI layer entirely missing
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | ChallengeTemplate (SchemaV4) defines all challenge behavior via config; three featured challenges seeded via template system, not hardcoded | VERIFIED | `SchemaV4.swift` has ChallengeTemplate @Model with checkInType/goalType/milestonesJSON config fields. `ChallengeTemplate+Featured.swift` seeds summerBodyTemplate/save5000Template/drySummerTemplate as Swift static constants. No hardcoded type logic. `ChallengeViewModel.seedFeaturedTemplates` uses isFeatured FetchDescriptor guard (idempotent). ROADMAP says "SchemaV3" but implementation uses SchemaV4 — the V3 naming in ROADMAP is a documentation artifact; the implementation is correct and superior. |
| 2 | UserChallenge and CheckIn models persist user state; one check-in per day enforced; streak and longest-streak computed correctly across midnight and DST | VERIFIED | `SchemaV4.swift`: UserChallenge has currentStreak/longestStreak/totalCheckIns/statusRaw/checkIns relationship; CheckIn has date/payloadBool/payloadNumber/payloadNote. `ChallengeViewModel.todayCheckIn` uses Calendar.startOfDay half-open range [today, tomorrow). `recordCheckIn` throws CheckInError.alreadyCheckedInToday on duplicate. `ChallengeStreakEngine.currentStreak/longestStreak` use calendar.startOfDay — DST-safe; no raw TimeInterval. |
| 3 | Challenge Discovery screen shows Featured Challenges, category browse, and "Build Your Own" CTA — all driven by template data | FAILED | No Discovery screen exists. ContentView has 4 tabs only. No ChallengesView, no ChallengeDiscoveryView anywhere in the codebase. Phase 13 Wave 4 plans (13-04, 13-05, 13-06) were never created or executed. ContentView has EmptyView stubs for both challenge routes with comment "Phase 13 — UI implemented in Phase 13 Wave 4". |
| 4 | Daily check-in flow is driven by check_in_type from the template with no type-specific branching in the engine layer | UNCERTAIN | Engine half: ChallengeViewModel is type-blind (zero `switch checkInType` / `if checkInType ==` in non-comment code — grep confirmed). CheckInPayload.apply(to:) dispatches on its own enum cases. CHAL-07 engine requirement is VERIFIED. However, the "flow" (UI) does not exist — no check-in view, no sheet. Whether SC-4 requires UI is ambiguous; human decision needed. |
| 5 | Milestone array from template config triggers full-screen celebration (confetti + personalized message + badge saved to profile) at each configured trigger point | FAILED | Engine half works: ChallengeViewModel.pendingMilestone fires when totalCheckIns crosses a MilestoneConfig threshold, firedMilestones prevents double-fire, milestoneHistoryJSON persists history. However: no full-screen celebration view, no confetti, no badge saving to UserProfile. pendingMilestone is an orphaned property — no View consumes it. |
| 6 | Evening check-in reminder notification fires per-challenge at user-set time if no check-in logged that day | VERIFIED (infrastructure only) | NotificationScheduler extension adds scheduleChallengeReminder with per-challenge identifier `com.kyleharrington.VitaminG.challengeReminder.<UUID>`, UNCalendarNotificationTrigger (repeats: true), hour/minute clamped, remove-before-add, userInfo carries deepLink + userChallengeID. removeChallengeReminder removes pending request. AppRoute/AppRouter extended with challengeCheckIn case and pendingChallengeCheckInID. DeepLinkBuilder/Parser extended for vitaming://challengeCheckIn scheme. NOTE: The notification schedule infrastructure exists, but no UI calls scheduleChallengeReminder from a reminder time picker — the notification is never actually scheduled because no challenge detail view exists to configure it. Marking VERIFIED for the infrastructure per SC-6's literal wording. |

**Score:** 2/6 truths verified (SC-1, SC-2 verified; SC-3 failed; SC-4 uncertain; SC-5 failed; SC-6 verified as infrastructure)

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `VitaminG/VitaminG/VitaminG/Models/SchemaV4.swift` | SchemaV4 enum + ChallengeTemplate/UserChallenge/CheckIn @Model classes + typealiases | VERIFIED | All three @Model classes present; all properties optional or defaulted; bidirectional @Relationship inverses; typealiases declared |
| `VitaminG/VitaminG/VitaminG/Models/VitaminGMigrationPlan.swift` | Migration plan extended with SchemaV4 + migrateV3toV4 stage | VERIFIED | schemas=[V1,V2,V3,V4]; stages=[v1to2,v2to3,v3to4]; all lightweight |
| `VitaminG/VitaminG/VitaminG/Persistence/ModelContainerFactory.swift` | Both makeContainer and makeWidgetContainer use SchemaV4 | VERIFIED | SchemaV4.models appears 2x; SchemaV3.models appears 0x; DEBUG CloudKit init includes all 7 model types |
| `VitaminG/VitaminG/VitaminG/Services/ChallengeStreakEngine.swift` | Pure struct: currentStreak(from:calendar:) and longestStreak(from:calendar:) | VERIFIED | struct (not class); both static methods; calendar.startOfDay used; no SwiftData/SwiftUI imports |
| `VitaminG/VitaminG/VitaminG/Models/ChallengeTemplate+Featured.swift` | Three static featured templates + MilestoneConfig type + decoded milestones accessor | VERIFIED | MilestoneConfig (Codable, Equatable); featuredTemplates returns 3; all hex colors (#FF6B4A, #4A90E2, #7A9E7E) present; try? JSONDecoder safe decode |
| `VitaminG/VitaminG/VitaminG/ViewModels/ChallengeViewModel.swift` | @Observable ViewModel: seedFeaturedTemplates, todayCheckIn, recordCheckIn, milestone detection, type-blind CheckInPayload | VERIFIED (engine only) | @MainActor @Observable; all 5 methods; zero `switch checkInType` / `if checkInType ==` in non-comment code; pendingMilestone fires correctly |
| `VitaminG/VitaminG/VitaminG/Navigation/AppRoute.swift` | Two new AppRoute cases with UserChallenge associated value | VERIFIED | case challengeDetail(UserChallenge) and case challengeCheckIn(UserChallenge) present; all prior cases preserved |
| `VitaminG/VitaminG/VitaminG/Navigation/AppRouter.swift` | pendingChallengeCheckInID state property + ChallengeCheckInDeepLinkItem wrapper | VERIFIED | Both present; pendingPublicProfileRecordID and ProfileDeepLinkItem preserved |
| `VitaminG/VitaminG/VitaminG/Services/DeepLinkBuilder.swift` | challengeCheckInURL(userChallengeID:) builder | VERIFIED | vitaming://challengeCheckIn/<UUID> scheme implemented; existing profileURL unchanged |
| `VitaminG/VitaminG/VitaminG/Services/DeepLinkParser.swift` | challengeCheckInID(from:) parser with scheme/host/UUID validation | VERIFIED | scheme + host + non-empty path validation chain; existing recordID(from:) unchanged |
| `VitaminG/VitaminG/VitaminG/Services/NotificationScheduler.swift` | scheduleChallengeReminder + removeChallengeReminder + challengeReminderIdentifier(for:) | VERIFIED | All 3 methods in extension; per-challenge identifier; remove-before-add; userInfo carries deepLink + userChallengeID; hour/minute clamped |
| **ChallengeDiscoveryView (or equivalent)** | 5th Challenges tab; featured challenge cards; category browse; "Build Your Own" CTA | MISSING | Does not exist anywhere in the codebase |
| **CheckInView / check-in modal** | Type-adaptive check-in UI for boolean / numeric / multi-step | MISSING | Does not exist; ContentView.challengeCheckIn returns EmptyView |
| **MilestoneCelebrationView** | Full-screen confetti + personalized message + badge-save-to-profile | MISSING | Does not exist; pendingMilestone is orphaned (set but never consumed by any View) |
| **StreakChainView** | Horizontal day-dot streak chain component for challenge detail | MISSING | Does not exist |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| ChallengeViewModel.recordCheckIn | ChallengeStreakEngine.currentStreak | static call with check-in dates | WIRED | `ChallengeStreakEngine.currentStreak(from: allDates)` at line 189 of ChallengeViewModel.swift |
| ChallengeViewModel.seedFeaturedTemplates | ChallengeTemplate.featuredTemplates | iteration + context.insert | WIRED | iterates `ChallengeTemplate.featuredTemplates` and inserts each at line 81 |
| ChallengeViewModel.recordCheckIn | ChallengeViewModel.pendingMilestone | milestone threshold detection | WIRED (orphaned) | pendingMilestone set correctly at line 201; but no View observes pendingMilestone |
| NotificationScheduler.scheduleChallengeReminder | DeepLinkBuilder.challengeCheckInURL | userInfo deepLink + userChallengeID | PARTIAL | NotificationScheduler hardcodes `"deepLink": "challengeCheckIn"` and `"userChallengeID"` without calling DeepLinkBuilder.challengeCheckInURL — conceptually correct but doesn't use the builder |
| DeepLinkParser.challengeCheckInID | AppRouter.pendingChallengeCheckInID | set from .onOpenURL handler | NOT WIRED | Plan 03 SUMMARY documents "wired in Plan 04" — Plan 04 was never executed; no .onOpenURL handler sets pendingChallengeCheckInID |
| pendingChallengeCheckInID | CheckIn sheet/modal | .sheet(item:) on ChallengeCheckInDeepLinkItem | NOT WIRED | ContentView has no binding for pendingChallengeCheckInID |
| pendingMilestone | MilestoneCelebrationView | .fullScreenCover or .sheet | NOT WIRED | No View consumes pendingMilestone |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| ChallengeViewModel | featuredTemplates | ChallengeTemplate static constants | Yes — hardcoded with real values | FLOWING |
| ChallengeViewModel | pendingMilestone | recordCheckIn milestone detection | Yes — set when totalCheckIns crosses threshold | HOLLOW — set but no View consumes it |
| NotificationScheduler | challenge.template?.title | UserChallenge.template relationship | Real data from SwiftData | FLOWING |
| ContentView (challengeDetail) | EmptyView | — | No data | DISCONNECTED — stub |
| ContentView (challengeCheckIn) | EmptyView | — | No data | DISCONNECTED — stub |

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| ChallengeStreakEngine struct exists with both methods | `grep -q "struct ChallengeStreakEngine" VitaminG/VitaminG/VitaminG/Services/ChallengeStreakEngine.swift` | Found | PASS |
| Engine has zero DST-unsafe timeIntervalSince calls | `grep -c "timeIntervalSince" VitaminG/VitaminG/VitaminG/Services/ChallengeStreakEngine.swift` | 0 | PASS |
| ChallengeViewModel has zero checkInType branching | `grep -v '^[[:space:]]*//' ChallengeViewModel.swift | grep -E "switch.*checkInType|if.*checkInType =="` | 0 matches | PASS |
| ChallengeViewModel imports no SwiftUI | `grep "^import SwiftUI" ChallengeViewModel.swift` | 0 matches | PASS |
| No 5th Challenges tab in ContentView | `grep "tabItem" ContentView.swift \| wc -l` | 4 tabItems (not 5) | FAIL — SC-3 requires Challenges tab |
| No discovery view files | `find VitaminG -name "*Discovery*" -o -name "*Challenge*View*"` | Only ChallengeViewModel | FAIL — UI views missing |
| MigrationPlan includes V4 | `grep -c "SchemaV4.self" VitaminGMigrationPlan.swift` | 2 (schemas + migrateV3toV4) | PASS |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| CHAL-01 | 13-01 | ChallengeTemplate SwiftData model defines all challenge behavior via config | SATISFIED | SchemaV4.ChallengeTemplate with checkInType/goalType/milestonesJSON/isFeatured/communitySize fields |
| CHAL-02 | 13-01 | UserChallenge model links user to template with streak, status, milestone history | SATISFIED | SchemaV4.UserChallenge with currentStreak/longestStreak/totalCheckIns/statusRaw/milestoneHistoryJSON |
| CHAL-03 | 13-01, 13-02 | CheckIn model; one check-in per day per challenge enforced | SATISFIED | SchemaV4.CheckIn; ChallengeViewModel.todayCheckIn + recordCheckIn throws alreadyCheckedInToday |
| CHAL-04 | 13-01 | SchemaV4 migration adds new models without data loss on existing records | SATISFIED | lightweight migrateV3toV4 stage; V3 models preserved in SchemaV4.models array |
| CHAL-05 | 13-02 | Challenge engine computes streak correctly across midnight and DST transitions | SATISFIED | ChallengeStreakEngine uses calendar.startOfDay; no timeIntervalSince; injectable Calendar parameter |
| CHAL-06 | 13-02 | Three featured challenges seeded via template system, no hardcoded type-specific logic | SATISFIED | ChallengeTemplate.featuredTemplates returns 3 static constants; idempotent seed guard in ChallengeViewModel |
| CHAL-07 | 13-02 | Adding a new challenge type requires zero new core engine logic | SATISFIED | CheckInPayload.apply(to:) handles type dispatch; zero switch/if on checkInType in engine layer |
| CHAL-08 | none executed | Discovery screen shows Featured Challenges, category browse, "Build Your Own" CTA | BLOCKED | No Discovery UI view exists anywhere in the codebase |
| CHAL-09 | none executed | Daily check-in flow adapts to check_in_type with no type-specific branching in engine layer | PARTIAL | Engine type-blindness SATISFIED; check-in UI (the "flow") does not exist |
| CHAL-10 | none executed | Milestone triggers full-screen celebration (confetti + personalized message + badge saved to profile) | BLOCKED | pendingMilestone fires correctly in VM; no celebration view, no confetti, no badge-to-profile |
| CHAL-11 | none executed | Progress tracking: streak calendar chain view, progress bar, day counter | BLOCKED | StreakChainView does not exist; no progress view of any kind for challenges |
| CHAL-12 | 13-03 | Evening check-in reminder fires per-challenge at user-set time if no check-in logged | PARTIAL | NotificationScheduler infrastructure complete; no UI to configure reminder time or trigger scheduling |

**Summary:** CHAL-01 through CHAL-07 and CHAL-12 infrastructure: SATISFIED. CHAL-08, CHAL-10, CHAL-11: BLOCKED (no UI). CHAL-09, CHAL-12: PARTIAL.

**Orphaned requirements:** CHAL-11 appears in Phase 13's REQUIREMENTS list but no plan in Phase 13 claimed it (none of 13-01/02/03 include CHAL-11 in their `requirements:` frontmatter). CHAL-11 was expected in an unexecuted Wave 4 plan.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| ContentView.swift | 67 | `EmptyView()  // Phase 13 — UI implemented in Phase 13 Wave 4` | BLOCKER | Challenge detail route returns empty view — user cannot navigate to any challenge UI |
| ContentView.swift | 69 | `EmptyView()  // Phase 13 — sheet path handles check-in; never pushed` | BLOCKER | Check-in route returns empty view — check-in flow completely inaccessible |
| ChallengeViewModel.swift | 63 | `var pendingMilestone: (challengeID: UUID, threshold: Int)? = nil` | BLOCKER | Property set correctly by recordCheckIn but no View observes it — milestone celebration never triggers |

---

### Human Verification Required

#### 1. SC-4 Scope Interpretation

**Test:** Review Phase 13 ROADMAP Success Criterion 4: "Daily check-in flow is driven by check_in_type from the template (boolean / numeric / multi-step) with no type-specific branching in the engine layer"
**Expected:** Determine whether "daily check-in flow" in SC-4 refers to (a) only the engine-layer dispatch (which is implemented and correct), or (b) requires the check-in UI (which is missing)
**Why human:** The wording is genuinely ambiguous. The second clause ("no type-specific branching in the engine layer") is fully satisfied. The CONTEXT.md D-05 and VALIDATION.md 13-05-01 both describe a "check-in modal" as Phase 13 Wave 2 (unexecuted), suggesting the UI was intended for Phase 13. If the developer considers SC-4 to mean engine-only, SC-4 can be marked VERIFIED and the overall score improves to 3/6 (still failing due to SC-3 and SC-5).

---

### Gaps Summary

Phase 13 successfully delivered the data layer (SchemaV4 + migration) and the challenge engine (ChallengeStreakEngine, ChallengeTemplate static constants, type-blind ChallengeViewModel). This is approximately half the phase scope.

The other half — the UI layer — was explicitly planned as "Wave 4" in the VALIDATION.md and CONTEXT.md but was never executed. No plans 13-04, 13-05, or 13-06 were created or run. The missing deliverables are:

1. **SC-3 (CHAL-08): Challenge Discovery screen** — The flagship user-facing surface. No ChallengesView exists. No 5th Challenges tab in ContentView. The CONTEXT.md D-04 explicitly required adding a Challenges tab.

2. **SC-5 (CHAL-10): Milestone celebration UI** — The engine fires `pendingMilestone` correctly, but the property is orphaned — no View consumes it for the full-screen confetti + message + badge-save-to-profile.

3. **SC-4 (CHAL-09): Check-in flow UI** — The engine dispatch is type-blind and correct, but no check-in view exists. ContentView.challengeCheckIn returns EmptyView.

Additionally: the deep-link routing from notification tap to check-in is incomplete (Plan 04's `.onOpenURL` wiring was never executed, so `pendingChallengeCheckInID` is set by nothing).

Root cause: The phase was submitted after executing Plans 01–03 (data layer, engine layer, navigation/notification infrastructure). Plans 04–06 (UI layer) were anticipated in the VALIDATION.md but never created or executed.

---

_Verified: 2026-05-06_
_Verifier: Claude (gsd-verifier)_
