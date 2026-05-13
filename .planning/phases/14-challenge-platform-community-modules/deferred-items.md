# Phase 14 Deferred Items

## Pre-existing Build Failures (out of scope for Plan 01)

### VGTheme Missing Type

**Discovered during:** Task 3 (build verification)
**Error:** `cannot find 'VGTheme' in scope` in multiple view files
**Files affected:**
- VitaminG/Views/ChallengeCheckInView.swift
- VitaminG/Views/ChallengeDiscoveryView.swift
- VitaminG/Views/ChallengeDetailView.swift
- VitaminG/Views/Components/StreakChainView.swift

**Status:** Pre-existing failure in base commit `be25e6a`. VGTheme enum/struct was referenced in Phase 13 views but never defined. Confirmed present on main branch before any Phase 14 changes.

**Action needed:** Define `VGTheme` with the required color properties (clay, sandLight, etc.) before Phase 14 UI plans can compile the full app. Schema/migration/test tasks (Plan 01) are unaffected since they don't depend on VGTheme.
