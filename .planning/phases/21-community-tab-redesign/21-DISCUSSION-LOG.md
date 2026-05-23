# Phase 21: Community Tab Redesign - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-23
**Phase:** 21-community-tab-redesign
**Areas discussed:** Today's Glimpses source, Applause scope + UX, Challenge feed fate, Photo compose flow

---

## Today's Glimpses Source

| Option | Description | Selected |
|--------|-------------|----------|
| Goal check-ins today | New GoalGlimpse CKRecord written to public DB at check-in | ✓ |
| Recent CommunityPost records | Re-purpose existing CommunityPost with goal title field | |
| Shared public goals | Pull from users' public goals in CloudKit | |

**User's choice:** Goal check-ins today (Recommended)
**Notes:** Snapshots written at goal check-in time. Freshest content, shows actual daily activity.

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal fields | username + goal title + progress % + optional photo | |
| Full profile | Includes actual avatar photo as CKAsset | |
| You decide | Claude picks field set | ✓ |

**User's choice:** You decide
**Notes:** Claude uses minimal field set with AvatarView colorHex pattern.

| Option | Description | Selected |
|--------|-------------|----------|
| Navigate to PublicProfileView stub | Phase 17 built this for report/block | ✓ |
| Modal goal detail sheet | Bottom sheet, no Phase 22 dependency | |
| Disabled in Phase 21 | Placeholder tap | |

**User's choice:** Navigate to existing PublicProfileView stub
**Notes:** No dead-end. Phase 22 expands the profile view.

---

## Applause Scope + UX

| Option | Description | Selected |
|--------|-------------|----------|
| Glowing spotlight only | Applause button only on the featured user card | |
| Spotlight + Today's Glimpses | Applause on both surfaces | ✓ (user-specified) |
| Spotlight + community feed posts | Applause alongside feed reactions | |

**User's choice:** Mix — Glowing This Week spotlight AND Today's Glimpses cards. NOT in the feed.
**Notes:** User specified this combination explicitly: "i want it on both the spotlight, glowing this week and on Today's glimpses cards but not in the feed"

| Option | Description | Selected |
|--------|-------------|----------|
| UserDefaults date-keyed dict | Consistent with Explore tab daily gate pattern | |
| CloudKit public DB record | Server-side truth, survives reinstall | |
| You decide | Claude picks | ✓ |

**User's choice:** You decide
**Notes:** Claude uses UserDefaults (consistent with EXPLORE-02, EXPLORE-06 patterns).

| Option | Description | Selected |
|--------|-------------|----------|
| Floats upward from button | Localized emoji + username rise and fade | ✓ |
| Full-screen overlay burst | Multiple 👏 across full screen | |
| You decide | Claude picks | |

**User's choice:** Floats upward from the tapped button itself

---

## Challenge Feed Fate

| Option | Description | Selected |
|--------|-------------|----------|
| Move to Explore tab | Challenges fit exploration; Community becomes pure social | ✓ |
| Remove, keep on Goals tab | Challenges link to personal goals | |
| Keep Challenges section in Community | Horizontal scroll above Today's Glimpses | |

**User's choice:** Move to Explore tab
**Notes:** ChallengeDiscoveryView and IdeaBoardView are added to ExploreTabView (Phase 20 output).

| Option | Description | Selected |
|--------|-------------|----------|
| Global feed — all community posts | Per COMM-06 spec; follow system is Phase 22 | ✓ |
| Only followed users' posts | More personal but Phase 22 not built yet | |
| You decide | Claude picks | |

**User's choice:** Global feed — all community posts

| Option | Description | Selected |
|--------|-------------|----------|
| Flat replies only | Same level as post; consistent with existing commentPostID | |
| One level of nesting | Indented reply-to-reply | |
| You decide | Claude picks | ✓ |

**User's choice:** You decide
**Notes:** Claude uses flat replies only (consistent with existing infrastructure).

---

## Photo Compose Flow

| Option | Description | Selected |
|--------|-------------|----------|
| Existing sheet + inline photo button | Camera icon in sheet, confirmationDialog for Library/Camera | ✓ |
| Full-screen compose view | Instagram-style photo-first experience | |
| Photo-first flow | PHPickerViewController before text | |

**User's choice:** Existing sheet + inline photo button
**Notes:** Photo thumbnail previews inline before submit. Minimal UI change.

| Option | Description | Selected |
|--------|-------------|----------|
| Optional | Text-only posts still supported | ✓ |
| Required when camera tapped | Must pick photo if camera button touched | |

**User's choice:** Optional

| Option | Description | Selected |
|--------|-------------|----------|
| Top of tab — active community challenge goal | Tapping opens CommunityGoalsLandingView | ✓ |
| Separate screen via row link | Doesn't use top-of-feed real estate | |
| You decide | Claude picks layout | |

**User's choice:** Top of Community tab, shows the active community challenge goal

---

## Claude's Discretion

- GoalGlimpse field set: minimal (username, goalTitle, progressPercent, optional photoAsset, authorColorHex)
- GoalGlimpse upsert: one record per user per day
- Reply CKRecord design: flat CommunityReply type with parentPostID, text, authorDisplayName, authorColorHex, creationDate
- SOC-02 ambient applause stream: GeometryReader overlay in ProfileView.swift
- Glowing eligibility: users with ≥1 GoalGlimpse in last 7 days
- Applause daily limit tracking: UserDefaults date-keyed dictionary (consistent with Explore daily gates)
- Reply depth: flat only (consistent with existing commentPostID infrastructure)

## Deferred Ideas

- Follow-based feed filtering → Phase 22 (PROF-02)
- Applause on community feed posts → deferred; keeping gesture special to Spotlight + Glimpses
- Nested reply threading → potential future phase
