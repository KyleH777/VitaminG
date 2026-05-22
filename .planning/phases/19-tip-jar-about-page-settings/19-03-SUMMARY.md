---
phase: 19-tip-jar-about-page-settings
plan: "03"
subsystem: payments
tags: [storekit2, iap, consumable, tipjar, observable, swiftui]

# Dependency graph
requires:
  - phase: 19-01
    provides: VitaminGTips.storekit config file with product IDs; TipStoreTests Wave 0 stub to implement
provides:
  - TipStore @Observable StoreKit 2 ViewModel with fetchProducts + purchase (verified-only delivery)
  - TipJarView three-tier screen with loading/error/loaded states and fullScreenCover
  - TipThankYouView post-purchase celebration with confetti, reduceMotion, and accessibility announcement
  - Implemented TipStoreTests (3 passing unit tests replacing XCTSkip stubs)
affects:
  - 19-04 (AboutView NavigationLink to TipJarView)
  - App Store Connect IAP product creation (user_setup task)

# Tech tracking
tech-stack:
  added: [StoreKit 2 (Product, Transaction, VerificationResult)]
  patterns:
    - "@MainActor @Observable final class ViewModel pattern (TipStore)"
    - "VerificationResult switch: .verified -> deliver, .unverified -> (false,false)"
    - "purchasingProductID: String? disables Buy during in-flight purchase (T-19-03-05)"
    - "fullScreenCover presented only on success == true (T-19-03-01)"
    - "TimelineView(.animation) Canvas confetti from MilestoneCelebrationView analog"

key-files:
  created:
    - VitaminG/VitaminG/VitaminG/Services/TipStore.swift
    - VitaminG/VitaminG/VitaminG/Views/TipJarView.swift
    - VitaminG/VitaminG/VitaminG/Views/TipThankYouView.swift
  modified:
    - VitaminG/VitaminG/VitaminGTests/TipStoreTests.swift

key-decisions:
  - "TipProductID raw values byte-identical to VitaminGTips.storekit — mismatch causes silent empty product list surfaced as visible error (T-19-03-06)"
  - "VerificationResult.unverified returns (false,false) and never triggers showThankYou (T-19-03-01)"
  - "fullScreenCover + .interactiveDismissDisabled(true) applied at presenter (TipJarView), not inside TipThankYouView"
  - "Confetti copied verbatim from MilestoneCelebrationView — single source of truth for celebration animation pattern"

patterns-established:
  - "TipStore purchase guard: always switch VerificationResult, treat .unverified as no-op"
  - "In-flight purchase lock: @State purchasingProductID disables all tier Buy buttons simultaneously"
  - "Celebration overlay: ZStack with Color.black.opacity(0.92) + TimelineView Canvas confetti + reduceMotion guard"

requirements-completed: [MON-02, MON-03, MON-04]

# Metrics
duration: 45min
completed: 2026-05-22
---

# Phase 19 Plan 03: Tip Jar — StoreKit 2 ViewModel, Three-Tier View, and Thank-You Celebration Summary

**StoreKit 2 consumable tip jar with TipStore @Observable ViewModel, three-tier TipJarView (loading/error/loaded states), and TipThankYouView confetti celebration gated on verified-only purchase delivery**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-05-22
- **Completed:** 2026-05-22
- **Tasks:** 3 auto tasks + 1 human-verify checkpoint (approved)
- **Files modified:** 4 (3 created, 1 implemented)

## Accomplishments

- StoreKit 2 `TipStore` fetches and price-sorts three consumable products; `purchase(_:)` gates delivery exclusively on `.verified` transactions — `.unverified` always returns `(false, false)` with no side effects (T-19-03-01 / MON-02 / MON-03)
- `TipJarView` renders three tier cards with `product.displayPrice`, a loading spinner, a visible error state on empty product list (T-19-03-06), and presents `TipThankYouView` via `.fullScreenCover` only on `success == true`
- `TipThankYouView` shows a `TimelineView` Canvas confetti celebration with spring entrance animation, `reduceMotion` guard, accessibility announcement, and zero external URLs — no feature gates (MON-04)
- Three `TipStoreTests` unit tests pass: `TipProductID.allCases.count == 3`, correct prefix on all raw values, fresh `TipStore` initial state

## Task Commits

Each task was committed atomically:

1. **Task 1 (RED): Add failing tests for TipProductID and TipStore** - `d3891a1` (test)
2. **Task 1 (GREEN): Implement TipStore StoreKit 2 ViewModel and TipProductID enum** - `c65f617` (feat)
3. **Task 2: Create TipThankYouView post-purchase celebration overlay** - `d747dba` (feat)
4. **Task 3: Create TipJarView with three tiers and fullScreenCover** - `adcbe1f` (feat)

_TDD: Task 1 followed RED (test stub) -> GREEN (implementation) cycle_

## Files Created/Modified

- `VitaminG/VitaminG/VitaminG/Services/TipStore.swift` — `@MainActor @Observable final class TipStore` with `fetchProducts()` (price-sorted) and `purchase(_:)` (VerificationResult-gated)
- `VitaminG/VitaminG/VitaminG/Views/TipJarView.swift` — Three-tier consumable tip jar with loading/error/loaded states, in-flight purchase lock, and fullScreenCover trigger
- `VitaminG/VitaminG/VitaminG/Views/TipThankYouView.swift` — Post-purchase celebration with Canvas confetti, spring animation, reduceMotion guard, and accessibility announcement
- `VitaminG/VitaminG/VitaminGTests/TipStoreTests.swift` — Implemented 3 unit tests (enum count, prefix, initial state); XCTSkip stubs removed

## Decisions Made

- **VerificationResult.unverified = silent no-op:** Returns `(false, false)` with no `purchaseError` set and no thank-you — a tampered/forged receipt yields no user-visible consequence (T-19-03-01)
- **interactiveDismissDisabled at presenter:** Applied in `TipJarView`'s `.fullScreenCover` closure, not inside `TipThankYouView`, to keep the view self-contained and dismiss-agnostic
- **TipTierCard as private struct:** Extracted tier rendering to `private struct TipTierCard` inside `TipJarView.swift` to keep the file self-contained without a separate file

## Deviations from Plan

None — plan executed exactly as written. All threat mitigations (T-19-03-01 through T-19-03-06) implemented as specified.

## Issues Encountered

None.

## User Setup Required

App Store Connect IAP products must be created before real-device or TestFlight sandbox testing. The `.storekit` local config (Plan 19-01) enables Simulator testing without this step.

- **Product IDs to create (consumable):**
  - `com.kyleharrington.VitaminG.tip.small` — Small Coffee ($0.99)
  - `com.kyleharrington.VitaminG.tip.large` — Large Coffee ($2.99)
  - `com.kyleharrington.VitaminG.tip.supporter` — Supporter ($4.99)
- **Location:** App Store Connect -> Vitamin G -> In-App Purchases

## Known Stubs

None — all three views are fully wired to `TipStore` with live StoreKit prices. No placeholder data.

## Next Phase Readiness

- `TipJarView` is self-contained and ready for a `NavigationLink` entry point from `AboutView` (Plan 19-04)
- `TipStore` is instantiated per-view via `@State`; no shared singleton needed
- Human checkpoint approved: product list loads, sandbox purchase completes, thank-you cover appears, no external links confirmed

---
*Phase: 19-tip-jar-about-page-settings*
*Completed: 2026-05-22*
