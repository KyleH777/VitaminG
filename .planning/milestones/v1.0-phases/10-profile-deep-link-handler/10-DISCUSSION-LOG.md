# Phase 10: Profile Deep Link Handler - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-18
**Phase:** 10-profile-deep-link-handler
**Areas discussed:** Destination view, AppRoute change, Tab switch behavior, Error handling

---

## Destination View

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal public profile viewer | Lightweight screen with avatar + name + public goals; fetched from CloudKit public DB | ✓ |
| Own profile tab | Switch to Profile tab (current user's own profile) — simpler but misleading | |
| Share sheet / web fallback | Open web URL or share preview; requires web infrastructure | |

**User's choice:** Minimal public profile viewer

**Follow-up: Content depth**

| Option | Description | Selected |
|--------|-------------|----------|
| Avatar + name + public goals | Full viewer with tier-grouped public goals | ✓ (initial) |
| Avatar + name only | Identity card only; simpler CloudKit fetch | |
| You decide | Claude picks based on available data | ✓ (final) |

**Notes:** After clarifying that `PublicProfile` CloudKit records only store `displayName` and `avatarColorHex` (public goal titles are not in the public database — they live on the owner's device in SwiftData), the user deferred to Claude's discretion. Claude's recommendation: avatar + name only, matching what the data actually supports. Extending the CloudKit schema with goals is out of scope for Phase 10.

---

## AppRoute Change

| Option | Description | Selected |
|--------|-------------|----------|
| New .publicProfile(recordID) case | Separate case for external links; keeps .profile for own-profile navigation | ✓ |
| Add associated value to .profile | .profile(recordID: String?) — nil = own, non-nil = other; more branching | |
| You decide | Claude picks the cleaner navigation model | |

**User's choice:** New `.publicProfile(recordID: String)` case

**Notes:** Preserves backward compatibility — `.profile` continues to work for NOTIF-07 and own-profile navigation without any changes to existing call sites.

---

## Tab Switch Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Sheet over active tab | .sheet on WindowGroup; works from any tab, handles cold launch | ✓ |
| Push onto Goals NavigationStack | AppRouter.navigate(to: .publicProfile(recordID)) into Goals tab | |
| Switch to Profile tab + push | selectedTab state + tab switch + push — most complex | |

**User's choice:** Sheet over active tab

**Follow-up: Sheet state ownership**

| Option | Description | Selected |
|--------|-------------|----------|
| AppRouter owns it | pendingPublicProfileRecordID: String? in AppRouter; consistent with existing pattern | ✓ |
| VitaminGApp owns it | @State in App struct; passed down via environment | |

**User's choice:** AppRouter owns `pendingPublicProfileRecordID: String?`

---

## Error Handling

| Option | Description | Selected |
|--------|-------------|----------|
| Inline error state in sheet | Sheet opens, shows "Profile unavailable" with Dismiss | ✓ (intent) |
| Alert before sheet opens | System alert on fetch failure; user never sees half-open sheet | |
| You decide | Claude picks the right UX | ✓ (final) |

**User's choice:** Deferred to Claude's discretion.

**Notes:** Claude's recommendation: inline error state in the sheet. The sheet opens, shows a loading indicator during CloudKit fetch, then transitions to content or a friendly "This profile is no longer available." message with a Dismiss button. No alert-on-alert. Self-contained sheet handles all states.

---

## Claude's Discretion

- Content depth of `PublicProfileView` (avatar + name only — constrained by available CloudKit data)
- Visual design and layout of `PublicProfileView`
- Loading state treatment (spinner vs. skeleton)
- ViewModel vs. inline `@State` (recommendation: `@Observable` ViewModel for MVVM consistency)
- Specific error message copy per CKError code
- Error state UX (inline in sheet, recommended)

## Deferred Ideas

None.
