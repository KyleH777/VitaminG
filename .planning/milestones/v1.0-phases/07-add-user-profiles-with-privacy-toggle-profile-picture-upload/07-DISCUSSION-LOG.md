# Phase 7: Add user profiles with privacy toggle, profile picture upload, and AI-generated character avatar - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-13
**Phase:** 07-add-user-profiles-with-privacy-toggle-profile-picture-upload
**Areas discussed:** AI Avatar, Privacy Toggle, Profile Entry Point, Profile Picture Storage, Per-goal Privacy

---

## AI Avatar

| Option | Description | Selected |
|--------|-------------|----------|
| Actual AI-generated avatar | Use an AI API (DALL-E, Claude, Stability AI) to generate a character | |
| Color placeholder with initials | Randomly assigned color + user initials | ✓ |

**User's choice:** Color placeholder with randomly-assigned color and initials. No AI API in Phase 7.
**Notes:** User mentioned this as a spontaneous clarification: "Maybe just have a placeholder avatar made and they randomly get a color." Simpler, faster, no external API dependency. Extensible for real AI generation later.

---

## Privacy Toggle Purpose

| Option | Description | Selected |
|--------|-------------|----------|
| Discreet mode | Hides goal titles in UI and widgets | |
| Profile visibility only | Controls whether name/avatar show on lock screen widget | |
| Lock screen / widget privacy | Hides all content from widgets | |
| Social profile privacy | Controls whether profile is visible to others; per-goal public/private toggles | ✓ |

**User's choice:** Social — privacy toggle means the profile can be viewed by others (public) or only by the user (private). Per-goal toggles let users mark specific goals as public.
**Notes:** User clarified that the app has a social dimension: "since its somewhat social, you can choose to not have your profile able to be seen by others or you, some goals you set are only visible to you and not others." This contradicts PROJECT.md's "no social features in v1" — Phase 7 intentionally expands beyond that.

---

## Social Discovery Mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Share link / QR code | User generates a link; anyone with it can view public profile | ✓ |
| Username / search | Unique usernames, searchable via CloudKit public database | |
| Follow / friends system | Social graph backend required | |
| Keep it personal | No social sharing; privacy toggle means something else | |

**User's choice:** Share link is the right call.
**Notes:** Claude recommended this as the smart path — no custom backend required, CloudKit public database handles it, keeps complexity manageable for a bolt-on phase. User confirmed: "Yes — share link is the right call."

---

## Profile Entry Point

| Option | Description | Selected |
|--------|-------------|----------|
| New Profile tab (4th tab) | 4th tab in TabView alongside Goals, Stats, Settings | ✓ |
| From Settings | Profile section at top of existing SettingsView | |
| Avatar in GoalList header | Small avatar in navigation bar, taps to open sheet | |

**User's choice:** New 4th tab.
**Notes:** Makes profile a first-class destination. Clean separation from settings.

---

## Profile Tab Layout

| Option | Description | Selected |
|--------|-------------|----------|
| Avatar + name + public goals + share | Full layout with public goals preview | ✓ |
| Avatar + name + share card only | Minimal — no inline goals preview | |
| Claude's discretion | Principle only; Claude decides layout | |

**User's choice:** Avatar + name + privacy toggle + public goals preview + share button.
**Notes:** User asked "what do you think" — Claude recommended this layout and user confirmed. Exact visual treatment left to Claude via UI-SPEC.

---

## Profile Picture Storage

| Option | Description | Selected |
|--------|-------------|----------|
| Photo library + CloudKit sync | Full photo upload, synced across devices | |
| Photo library + camera, local only | Photo upload but no sync | |
| Color avatar only (deferred photos) | Skip photo upload; color + initials only | ✓ |

**User's choice:** Skip real photos — color avatar only in Phase 7.
**Notes:** User wanted to defer for privacy/security reasons: "I want privacy and the user to feel secure." Phase 7 uses color + initials. A `photoData: Data?` slot is reserved in the UserProfile model for a future phase.

---

## Per-goal Privacy UI

| Option | Description | Selected |
|--------|-------------|----------|
| On goal detail view (edit form) | Toggle in GoalDetailView and EditGoalView | ✓ |
| From Profile tab only | Toggle on Profile tab, not in goal detail | |
| Claude's discretion | Claude decides the interaction | |

**User's choice:** Toggle in the GoalDetailView and EditGoalView form.
**Notes:** Goals are private by default. Toggle is surfaced where users already manage goal fields.

---
