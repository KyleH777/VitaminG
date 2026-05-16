# Phase 16: Tab Restructuring + AppRoute Updates — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-16
**Phase:** 16-tab-restructuring-approute-updates
**Areas discussed:** Stats entry point, Daily Wins entry point, Tab enum binding depth

---

## Stats Entry Point

| Option | Description | Selected |
|--------|-------------|----------|
| Tap the Quick Stats row | Make the existing Phase 15 Quick Stats row a NavigationLink to StatsView — zero new UI | ✓ |
| Separate 'View Stats →' link | Small text link or button beneath/beside the row | |
| You decide | Leave affordance to the planner | |

**User's choice:** Tap the Quick Stats row (NavigationLink)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Exclusively Home tab | Remove .stats from goalsTab's navigationDestination | ✓ |
| Both tabs | Keep .stats in Goals tab in addition to Home | |

**User's choice:** Exclusively Home tab — .stats removed from Goals tab, wired only in Home tab NavigationStack.

---

## Daily Wins Entry Point

| Option | Description | Selected |
|--------|-------------|----------|
| Streak / check-in area tap | Link/button near the Check-in CTA (Log your workout area) | ✓ |
| Separate 'Daily Wins' card | Dedicated card below the Quick Stats row | |
| You decide | Leave placement to planner | |

**User's choice:** Near the Check-in CTA area (grouped with daily check-in habit zone).

---

| Option | Description | Selected |
|--------|-------------|----------|
| Exclusively Home tab | Remove .wins from goalsTab's navigationDestination | ✓ |
| Both tabs | Keep .wins in Goals tab too | |

**User's choice:** Exclusively Home tab — .wins removed from Goals tab, wired only in Home tab NavigationStack.

---

## Tab Enum Binding Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Full migration | ContentView.selectedTab: Tab, VGTabBar.selection: Binding<Tab>, CommunityTabView.selectedTab: Binding<Tab> | ✓ |
| Partial — Tab enum in ContentView only | ContentView translates Tab → Int before passing to VGTabBar | |

**User's choice:** Full migration — Tab enum propagates all the way into VGTabBar and CommunityTabView.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Lowercase raw values | "home", "goals", "explore", "community", "profile" | ✓ |
| Uppercase raw values | "Home", "Goals", "Explore", "Community", "Profile" | |

**User's choice:** Lowercase string raw values.

---

## Claude's Discretion

- Exact label text and visual treatment for Daily Wins entry near the Check-in CTA (button vs text link vs inline row)
- Whether `Tab` defines a `var index: Int` computed property or relies on enum ordering
- Whether `Tab` lives in its own `Tab.swift` file or is defined inline in ContentView

## Deferred Ideas

- **Phase 17 — PROF-05 UX detail:** Block/Report actions should be accessible via long-press (press-and-hold) context menu on a user's profile picture/avatar and @handle, in addition to the profile view button. App Store Guideline 1.2 compliance. Raised during Phase 16 discussion.
