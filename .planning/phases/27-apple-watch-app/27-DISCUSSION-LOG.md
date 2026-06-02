# Phase 27: Apple Watch App - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-02
**Phase:** 27-apple-watch-app
**Areas discussed:** Check-in scope, Watch feedback UX, Complication checked-in state, TodayGlanceView data

---

## Check-in scope

| Option | Description | Selected |
|--------|-------------|----------|
| Active goal only (Recommended) | Check in the single highest-priority non-completed goal — same one shown in the complication. goalId included in transferUserInfo payload. | |
| All active goals for today | One wrist tap marks the whole day done across all active goals. Simpler payload, but diverges from iOS per-goal model. | |
| You decide | Leave this to the planner/executor. | ✓ |

**User's choice:** You decide (Claude's discretion)
**Notes:** No strong preference expressed. Recommended approach: active goal only, consistent with iOS per-goal model.

---

## Watch feedback UX

| Option | Description | Selected |
|--------|-------------|----------|
| Immediate CheckInSuccessView (Recommended) | Optimistic — transition immediately on button tap; relay happens in background. CheckInSuccessView is already built. | |
| Pending → then success | Brief loading state, transition to success once WCSession queues the message. | |
| You decide | Leave this to the planner/executor. | ✓ |

**User's choice:** You decide (Claude's discretion)
**Notes:** Optimistic transition recommended given CheckInSuccessView is already built and transferUserInfo is inherently asynchronous.

---

## Complication checked-in state

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — show checked-in state (Recommended) | After iPhone processes check-in, pushes updated WCSession snapshot. Complication shows checkmark or "Done" indicator. | |
| No — progress ring always | Complication always shows ring regardless of check-in status. Simpler, no checked-in state to model. | |
| You decide | Leave this to the planner/executor. | ✓ |

**User's choice:** You decide (Claude's discretion)
**Notes:** Recommended to include `hasCheckedInToday: Bool` in snapshot struct — enables both complication and TodayGlanceView to reflect checked-in state.

---

## TodayGlanceView data

**Question 1: What drives the progress ring?**

| Option | Description | Selected |
|--------|-------------|----------|
| Goal progress ring (Recommended) | Ring shows activeGoalProgress (0.0–1.0). Center text shows %. Consistent with complication. | ✓ |
| Daily completion rate | Ring shows today's overall completion rate across all active goals. | |
| You decide | Leave this to the planner/executor. | |

**User's choice:** Goal progress ring (Recommended)

**Question 2: What shows below the ring?**

| Option | Description | Selected |
|--------|-------------|----------|
| Active goal title + streak day (Recommended) | Header: "Day [globalStreak]". Below ring: active goal title. Mirrors complication content. | ✓ |
| Just the ring + Check In button | Minimalist — large ring, prominent Check In button only. | |

**User's choice:** Active goal title + streak day (Recommended)

---

## Claude's Discretion

- **Check-in scope**: Active goal only recommended (goalId in transferUserInfo payload)
- **Watch check-in feedback**: Optimistic immediate CheckInSuccessView transition recommended
- **Complication checked-in state**: Include `hasCheckedInToday` in snapshot; complication reflects checked-in state recommended
- **WatchSessionManager placement**: Dedicated service class at iOS app startup
- **Watch App Group name**: Planner to verify whether existing `group.com.kyleharrington.VitaminG` can be shared with Watch target or a new `group.com.kyleharrington.VitaminGWatch` is needed

## Deferred Ideas

None — discussion stayed within phase scope.
