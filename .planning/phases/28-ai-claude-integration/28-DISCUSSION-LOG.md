# Phase 28: AI (Claude) Integration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-06
**Phase:** 28-ai-claude-integration
**Areas discussed:** Motivation card design, Worker API contract, Goal suggestion → add flow, Explore card placement

---

## Motivation Card Design

### Q1: What happens to the existing 'TODAY'S DOSE' quoteSection?

| Option | Description | Selected |
|--------|-------------|----------|
| Replace it entirely | quoteSection becomes the Claude motivation card; VGQuoteBank is the fallback | ✓ (Claude's discretion) |
| Add above it as a new card | New card above the existing quote section | |
| You decide | Claude picks the approach | |

**User's choice:** "You decide" — Claude recommended: Replace the existing quoteSection entirely. Same position, same card shell. VGQuoteBank fills the slot as fallback. Avoids stacked motivational content.

---

### Q2: Section label when Claude copy is active?

| Option | Description | Selected |
|--------|-------------|----------|
| Keep 'TODAY'S DOSE' | Consistent — user doesn't know copy source | |
| Change to 'YOUR DOSE' | Personalized framing when Claude is available | ✓ |

**User's choice:** "Change to 'YOUR DOSE'" — label switches to "YOUR DOSE" when Claude copy is showing; falls back to "TODAY'S DOSE" with VGQuoteBank.

---

### Q3: Copy format for Claude-generated motivation?

| Option | Description | Selected |
|--------|-------------|----------|
| Short paragraph (2-3 sentences) | Warm, personal, conversational (≤40 words) | ✓ (Claude's discretion) |
| Single punchy line | Matches VGQuoteBank's terse style | |
| You decide | Claude picks the format | |

**User's choice:** "You decide" — Claude recommended: 2–3 sentences, ≤40 words. The card shell uses `fixedSize(horizontal: false, vertical: true)` and accommodates paragraph copy without layout changes.

---

## Worker API Contract

### Q1: How should iOS communicate with the Cloudflare Worker?

| Option | Description | Selected |
|--------|-------------|----------|
| Single endpoint, structured payload | POST /ai with { type, goals[], streak }. Worker builds Claude prompt. | ✓ |
| Single endpoint, raw prompt | iOS composes the full Claude prompt text | |
| Two separate endpoints | /motivate and /suggest-goals | |

**User's choice:** "Single endpoint, structured payload (Recommended)" — Worker builds prompts server-side from structured data; prompts can be iterated without app updates.

---

### Q2: What should the Worker return?

| Option | Description | Selected |
|--------|-------------|----------|
| Plain text in a JSON wrapper | `{ "text": "..." }` / `{ "suggestions": [...] }` | ✓ (Claude's discretion) |
| Raw Claude API response | Full Anthropic API response passthrough | |
| You decide | Claude picks simplest response envelope | |

**User's choice:** "You decide" — Claude recommended: thin JSON wrapper (`{ "text" }` / `{ "suggestions" }`). Decouples iOS from Claude's API schema.

---

### Q3: Does the Worker need auth/verification from iOS?

| Option | Description | Selected |
|--------|-------------|----------|
| Open (no auth token) | Relies on Cloudflare 100K req/day rate limit only | |
| Simple shared secret | UUID-format header/field deters casual abuse | ✓ (Claude's discretion) |
| You decide | Claude picks based on threat model | |

**User's choice:** "You decide" — Claude recommended: UUID-format shared secret as a field in the POST body. Not cryptographically strong but deters casual abuse if Worker URL is discovered. The Anthropic API key stays in Cloudflare env vars only.

---

## Goal Suggestion → Add Flow

### Q1: Which tier gets assigned when a user taps a suggestion?

| Option | Description | Selected |
|--------|-------------|----------|
| QuickWin by default | Lowest-friction tier; user can edit after adding | ✓ |
| Show tier picker first | More intentional but violates single-tap AI-01 requirement | |
| You decide | Claude picks tier based on suggestion wording | |

**User's choice:** "QuickWin by default (Recommended)" — single tap, QuickWin tier. User can edit after.

---

### Q2: What happens to the card after tapping a suggestion?

| Option | Description | Selected |
|--------|-------------|----------|
| Mark as added (checkmark/dimmed) | Card stays with 3 items; added ones visually distinguished | ✓ |
| Remove added suggestion, show 2 remaining | Card shrinks as suggestions are added | |
| Card stays unchanged | No visual change; toast/haptic only | |

**User's choice:** "Mark the tapped suggestion as added (checkmark / dimmed)" — card stays with all 3 visible; added suggestions get a checkmark or dimmed appearance.

---

### Q3: What appears when the Worker is unreachable?

| Option | Description | Selected |
|--------|-------------|----------|
| Hide the card entirely | No error state; card only appears when suggestions are available | |
| Show static fallback suggestions | 3 pre-written generic suggestions; card always present | ✓ |
| Show card with error state | "Suggestions unavailable" message | |

**User's choice:** "Show static fallback suggestions" — 3 generic pre-written suggestions when proxy is down; card is always present on the Explore tab.

---

## Explore Card Placement

### Q1: Where in the Explore scroll does "Goals suggested for you" appear?

| Option | Description | Selected |
|--------|-------------|----------|
| Top — above 'Today's Gift' | Highest visibility, first thing users see | |
| Second — between 'Today's Gift' and 'Daily Mood' | Today's Gift retains prime position; AI follows immediately | ✓ (Claude's discretion) |
| You decide | Claude picks based on content hierarchy | |

**User's choice:** "You decide" — Claude recommended: second position, between GoalGifterCard and MoodPromptCard. Today's Gift (existing) retains its prime position; AI suggestions follow as the more personalized alternative.

---

### Q2: What section label should the card use?

| Option | Description | Selected |
|--------|-------------|----------|
| GOALS FOR YOU | Short, personal, all-caps, matches existing label style | ✓ |
| SUGGESTED FOR YOU | Familiar recommendation UI pattern, slightly longer | |
| You decide | Claude picks the label that fits existing style | |

**User's choice:** "GOALS FOR YOU (Recommended)"

---

## Claude's Discretion

- **Motivation card approach** — Replace existing quoteSection; VGQuoteBank is fallback for the same slot
- **Motivation copy format** — 2–3 sentences, ≤40 words; warm and personal
- **Worker response format** — Thin JSON wrapper (`{ "text" }` / `{ "suggestions" }`)
- **Worker auth** — UUID-format shared secret as POST body field; compiled as constant in iOS
- **Explore card position** — Second position (between Today's Gift and Daily Mood)
- **Claude model** — `claude-haiku-4-5-20251001`, `max_tokens: 150` (motivation) / `max_tokens: 200` (suggestions)

## Deferred Ideas

None — discussion stayed within phase scope.
