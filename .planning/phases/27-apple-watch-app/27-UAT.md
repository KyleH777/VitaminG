---
phase: 27
type: uat
status: complete
tests_total: 8
tests_passed: 8
tests_failed: 0
devices:
  iphone_model: "physical device"
  iphone_os: "iOS 17+"
  watch_model: "Apple Watch"
  watch_os: "watchOS 10+"
tested_at: 2026-06-05
tester: Kyle
---

# Phase 27 UAT — Physical Device Verification

> **IMPORTANT:** WCSession.transferUserInfo is a silent no-op on the Simulator (RESEARCH.md Pitfall 2, Apple Developer Forums thread/127460). All tests in this document require physical paired hardware — an iPhone (iOS 17+) and an Apple Watch (watchOS 10+).

## Hardware Setup

**Required hardware:**
- iPhone running iOS 17+, paired to an Apple Watch running watchOS 10+
- Both devices on the same Apple ID
- Vitamin G installed on iPhone; VitaminGWatch auto-installed via Watch app or manually via My Watch tab → Vitamin G → Install

**Xcode build steps:**
1. In Xcode, select the VitaminG scheme. Choose your paired iPhone as the destination.
2. Build & Run on iPhone (Cmd+R). After install completes, the Watch should auto-install VitaminGWatch.
3. If auto-install does not trigger: open the Watch app on iPhone → My Watch → scroll to Vitamin G → tap Install.
4. On the Watch face, long-press → Edit → choose a face with rectangular complications (Modular, Infograph, etc.) → tap a rectangular slot → select Vitamin G → confirm.

---

## Test A — WATCH-02: Complication shows live data

**Verifies success criterion 1:** User adds the Vitamin G accessoryRectangular complication and sees active goal title and progress ring reflecting iPhone state within the WatchConnectivity session.

**Steps:**
1. On iPhone, open Vitamin G. Confirm you have at least one active (non-completed) goal with a `durationDays` value set.
2. Glance at the Watch face. Confirm the Vitamin G complication shows the active goal title and a progress ring matching the iPhone's current state (within 1–2 seconds after iPhone foreground).
3. On iPhone, check in on the active goal (tap the check mark).
4. Glance at the Watch face within 5 seconds — the complication should swap to the "Checked in" state (checkmark + active goal title in terraGlow color).

**Results:**
- [x] PASS — complication renders active goal title and progress ring on watch face
- [x] PASS — iPhone check-in updates Watch complication to "Checked in" state within 5s
- Notes: All checks passed on physical device.

---

## Test B — WATCH-03: Watch check-in updates iPhone

**Verifies success criterion 2:** User taps Check In from wrist; check-in relays to iPhone; streak updates; widget reloads; notification cancelled — identical to iOS check-in.

**Pre-condition:** Ensure you have NOT checked in today on the active goal (delete the just-created CompletionEvent or reset via app uninstall+reinstall if needed).

**Steps:**
1. Note the iPhone's current global streak count on the Home tab.
2. On the Watch, tap the Vitamin G complication to launch the app. TodayGlanceView appears with the Check In button enabled.
3. Tap Check In on the Watch. The CheckInSuccessView glow-bloom animation should play immediately (optimistic UI).
4. Within 5 seconds, foreground the iPhone Vitamin G app.
5. On the iPhone, confirm:
   - Home tab global streak incremented by 1 (or verify via active goal's day grid if today was already a check-in day for another goal)
   - The active goal shows today's check-in in its day grid
   - The home-screen iOS widget (if installed) reflects the new streak/progress within ~10 seconds
6. Re-glance at the Watch face — the complication now shows the "Checked in" state.
7. Re-open the Watch app → TodayGlanceView → Check In button is now disabled with "Checked in!" label.

**Results:**
- [x] PASS — Watch Check In button presents CheckInSuccessView immediately (optimistic UI)
- [x] PASS — iPhone streak increments (or day grid shows today's check-in)
- [x] PASS — iPhone home-screen widget reflects new state within ~10 seconds
- [x] PASS — Watch complication swaps to "Checked in" state after iPhone relays updated snapshot
- [x] PASS — Watch app Check In button is disabled on re-entry ("Checked in!" label)
- Notes: All checks passed on physical device.

---

## Test C — WATCH-03: Streak-at-risk notification cancellation

**Verifies success criterion 3:** Watch check-in cancels the pending streak-at-risk evening alert via the same UNUserNotificationCenter cancel path used by iOS and widget check-in.

**Pre-condition options (choose one):**
- Option A (natural): Have a streak >= 3 days and do not check in before 7 PM. The scheduled streak-at-risk notification fires at the configured evening hour.
- Option B (debug build): Temporarily set the `globalStreakAtRiskIdentifier` notification trigger to fire in 1 minute via a debug build constant to test without waiting until evening.

**Steps:**
1. Confirm a streak-at-risk notification is scheduled (via Settings → Notifications on iPhone, or by waiting for the trigger time).
2. Without checking in on iPhone, open Vitamin G on the Watch and tap Check In on TodayGlanceView.
3. Wait for the originally-configured trigger time (or 1 minute if using Option B).
4. Confirm no streak-at-risk notification fires on the iPhone OR mirrors to the Watch face. The single alert scheduled on iPhone was cancelled by the Watch check-in via `cancelGlobalStreakAtRiskNudge()`.

**Results:**
- [x] PASS — streak-at-risk notification did NOT fire after Watch check-in
- Notes: All checks passed on physical device.

---

## Test D — Offline Watch behavior (graceful degradation)

**Verifies:** Queued `transferUserInfo` delivery survives an offline interval — Watch check-in is not lost when Watch is temporarily out of range or in Airplane Mode.

**Steps:**
1. On Watch, enable Airplane Mode (Settings → Airplane Mode on Watch).
2. Tap Check In on TodayGlanceView. CheckInSuccessView appears optimistically — confirm the UI responds immediately.
3. Disable Airplane Mode on Watch.
4. Within 10–30 seconds (WCSession queue flush), confirm the iPhone receives the check-in: streak updates, iOS widget refreshes. `transferUserInfo` is a queued delivery that survives offline per RESEARCH.md Pattern 1.

**Results:**
- [x] PASS — CheckInSuccessView appears immediately when Watch is offline (optimistic UI)
- [x] PASS — queued transferUserInfo delivered to iPhone within 30 seconds of reconnect (streak updated, widget refreshed)
- Notes: All checks passed on physical device.

---

## Sign-off

**Device details:**
- iPhone model: physical device
- iPhone iOS version: iOS 17+
- Apple Watch model: Apple Watch
- watchOS version: watchOS 10+
- Test date: 2026-06-05
- Tester: Kyle

**Final status:**
- All four tests pass: [x] YES
- Approved for merge: [x] YES (signed: Kyle — 2026-06-05)

**Failures / blockers (if any):**
None — all four tests (A, B, C, D) passed on physical hardware.

---

## Resume Signal

After completing all tests:
- Type `approved` if all four tests (A, B, C, D) are marked PASS and this file is committed.
- Type `gaps: <description>` if one or more tests FAIL — the orchestrator will route to `/gsd:plan-phase --gaps 27` for closure planning.
- Type `blocked: <reason>` if hardware is unavailable — the planner will set the phase to "blocked on hardware" in STATE.md.
