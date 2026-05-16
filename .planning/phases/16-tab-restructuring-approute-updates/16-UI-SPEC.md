---
phase: 16
slug: tab-restructuring-approute-updates
status: draft
shadcn_initialized: false
preset: none
platform: iOS / SwiftUI
created: 2026-05-16
---

# Phase 16 — UI Design Contract
# Tab Restructuring + AppRoute Updates

> Visual and interaction contract for Phase 16. This phase is a navigation restructure, not a visual redesign. No new colors, no new typography, no new design tokens are introduced. The existing VGTheme design system applies throughout. This contract focuses on copywriting precision, interaction behavior, and accessibility labeling for the elements that change or are newly introduced.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none — native SwiftUI only |
| Preset | not applicable — iOS/SwiftUI project |
| Component library | not applicable — native SwiftUI views |
| Icon library | SF Symbols (system), via `Image(systemName:)` |
| Font (serif) | CormorantGaramond-Regular / Medium / SemiBold / Italic (via `VGTheme.serif()` / `VGTheme.serifItalic()`) |
| Font (sans) | SF Pro (system font via `.system(size:weight:)`) |
| Design token file | `VitaminG/VitaminG/VitaminG/VGTheme.swift` |

Registry safety: not applicable — native SwiftUI. No third-party component registries.

---

## Spacing Scale

This phase uses existing VGTheme spacing conventions. No new spacing values are introduced.

| Token | Value | Usage in this phase |
|-------|-------|---------------------|
| xs | 4pt | Icon-label gap inside tab items (existing VGTabBar: `VStack(spacing: 4)`) |
| sm | 8pt | Spacing between Quick Stats cells (existing: `HStack(spacing: 8)`) |
| md | 16pt | Top padding above Quick Stats row (existing: `.padding(.top, 16)`) |
| lg | 24pt | Horizontal screen margin (existing: `.padding(.horizontal, 24)`) |
| xl | 32pt | Bottom scroll buffer (existing: `Spacer(minLength: 32)`) |

Exceptions:
- Tab bar top padding: 6pt (existing VGTabBar: `.padding(.top, 6)`) — not a multiple of 4; carries forward from v1.0, do not change
- Tab bar bottom padding: 8pt (existing VGTabBar: `.padding(.bottom, 8)`) — carries forward from v1.0, do not change
- Tab top indicator bar: 2pt height (existing VGTabBar active indicator) — decorative element, not spacing

iOS HIG touch target minimum: 44pt. All tappable elements (tab bar items, NavigationLink rows) must meet this minimum. See Interaction section.

---

## Typography

No new type sizes or weights are introduced in this phase. All typography is carried forward from the existing design system and matched to current HomeView patterns.

| Role | Size | Weight | Font | Usage in this phase |
|------|------|--------|------|---------------------|
| Tab label | 10pt | Regular (inactive) / Semibold (active) | SF Pro | Tab bar item labels — unchanged size from v1.0 |
| Tab icon | 22pt | System | SF Symbols | Tab bar icons — unchanged from v1.0 |
| Stat cell value | 18pt | Regular | CormorantGaramond-Regular (via `VGTheme.serif(18)`) | Quick Stats row values — existing statCell |
| Stat cell label | 10pt | Regular | SF Pro | Quick Stats row sublabels — existing statCell |
| Daily Wins link label | 16pt | Semibold | SF Pro | New Daily Wins entry point — matches existing `checkInCTA` label style |

Letter spacing for tab labels: `kerning(0.4)` — existing VGTabBar, do not change.

---

## Color

No new colors are introduced in this phase. All color tokens come from `VGTheme.swift`.

| Role | VGTheme Token | Hex (light) | Hex (dark) | Usage |
|------|---------------|-------------|------------|-------|
| Dominant surface | `VGTheme.heroBackground` | #3D2F1E (clay) | #16110C (inkDeep) | HomeView full-bleed background |
| Card / cell background | `Color.white.opacity(0.06–0.07)` | semi-transparent | semi-transparent | Quick Stats statCell background — existing |
| Tab bar background (light) | `VGTheme.warmWhite` | #FDFAF6 | — | VGTabBar background in light mode |
| Tab bar background (dark) | `Color(red:0.086,green:0.067,blue:0.047).opacity(0.92)` | — | near-black | VGTabBar background in dark mode |
| Accent (active tab) | `VGTheme.accentTerra` | #C4673A | #FF8A5C | Active tab icon, active tab label, active tab top indicator bar |
| Inactive tab | `VGTheme.textMuted` | #9A8A78 | sand 42% opacity | Inactive tab icon and label |
| Daily Wins link background | `VGTheme.accentTerra` gradient | #C4673A → #C4673A | #FF8A5C → #FF8A5C | Daily Wins entry point button fill — matches checkInCTA gradient |
| Daily Wins link text | `.white` | #FFFFFF | #FFFFFF | Daily Wins entry point label text |
| Quick Stats NavigationLink | No additional color applied | — | — | The statCell row becomes a NavigationLink; no visual color change from current appearance |

Accent reserved for: active tab indicator bar, active tab icon, active tab label, primary CTA buttons (checkInCTA, Daily Wins entry point).

---

## Tab Bar — Label and Icon Contract

This is the primary copywriting contract for this phase.

| Tab index | Tab enum raw value | Label | SF Symbol (inactive) | SF Symbol (active) | Source |
|-----------|-------------------|-------|----------------------|---------------------|--------|
| 0 | `"home"` | `Home` | `house` | `house.fill` | Carries forward from v1.0 |
| 1 | `"goals"` | `Goals` | `circle.circle` | `circle.circle.fill` | Carries forward from v1.0 |
| 2 | `"explore"` | `Explore` | `magnifyingglass` | `magnifyingglass` | Swapped from index 3 — D-07 |
| 3 | `"community"` | `Community` | `person.2` | `person.2.fill` | Swapped from index 2 — D-07 |
| 4 | `"profile"` | `Profile` | `person` | `person.fill` | Renamed from "Me" — D-09 |

Label casing: Title case for all tab labels. Single word. No punctuation.

Note on Explore SF Symbol: `magnifyingglass` does not have a `.fill` variant in SF Symbols. Use `magnifyingglass` for both states. This matches the existing v1.0 VGTabBar behavior for this icon.

---

## Copywriting Contract

### Primary navigation copy

| Element | Copy | Source |
|---------|------|--------|
| Home tab label | `Home` | Carries forward — D-07 |
| Goals tab label | `Goals` | Carries forward — D-07 |
| Explore tab label | `Explore` | Tab rename — D-07 |
| Community tab label | `Community` | Carries forward — D-07 |
| Profile tab label | `Profile` | Renamed from "Me" — D-09 |

### New HomeView entry points

| Element | Copy | Placement | Visual treatment |
|---------|------|-----------|-----------------|
| Quick Stats NavigationLink | (no label change) — the existing 3-column `statCell` row (Active Goals · Check-ins · Badges) | Below `checkInCTA`, above `stayCloseSection` — position unchanged | Wrap existing `quickStatsRow` in `NavigationLink(destination: StatsView())`; no visual change to the row itself; add `chevron.right` chevron indicator — see Interaction below |
| Daily Wins entry point | `See your wins →` | Below `checkInCTA` (or below Quick Stats row if CTA is hidden), within the daily habit zone | Full-width button matching `checkInCTA` style: terra gradient fill, white semibold 16pt text, 14pt corner radius, 16pt vertical padding, 24pt horizontal screen margin |

Daily Wins label rationale: "See your wins →" is action-oriented, consistent with existing "Log today's check-in →" CTA style (verb + object + arrow), and scoped to what the view contains (past gratitude entries). Planner may substitute an alternative label if it better fits the surrounding layout context, provided it follows the pattern: verb + object (+ optional "→").

### Placeholder screen copy (Explore and Community tabs — empty state for v2.0 shell)

These tabs exist as empty placeholder views in Phase 16 (TAB-01 success criterion 4). No crashes on tap is the requirement. Copy for these placeholder states:

| Element | Copy |
|---------|------|
| Explore placeholder heading | `Coming soon` |
| Explore placeholder body | `Something exciting is brewing.` |
| Community placeholder heading | `Coming soon` |
| Community placeholder body | `Your community is on its way.` |

Implementation: A centered `VStack` with `VGTheme.textMuted` foreground. No images required. These placeholders are throwaway — they will be completely replaced in Phases 20 and 21.

### Error and empty states for demoted views

No new error states are introduced. StatsView and DailyWinsView already have their own empty/error handling from v1.0. This phase only changes the navigation path to reach them.

### Destructive actions

None in this phase. No confirmation dialogs required.

---

## Interaction Contract

### VGTabBar tab selection

| Property | Specification |
|----------|--------------|
| Selection feedback | `UIImpactFeedbackGenerator(style: .light)` — existing, carry forward |
| Selection animation | `.easeInOut(duration: 0.15)` — existing, carry forward |
| Active indicator | 2pt terra-colored top bar + terra icon + terra label — existing, carry forward |
| Touch target | Full tab cell: `frame(maxWidth: .infinity).padding(.top, 6).padding(.bottom, 8)` with minimum height of 44pt — existing VGTabBar satisfies this |

### Quick Stats row — NavigationLink to StatsView

| Property | Specification |
|----------|--------------|
| Interaction type | `NavigationLink(destination: StatsView())` wrapping the entire `quickStatsRow` |
| Touch target | The full 3-cell `HStack` row. Minimum 44pt height. The current `statCell` already renders with `.padding(.vertical, 10)` plus content, reaching approximately 50–54pt — satisfies HIG minimum |
| Chevron indicator | Add a `chevron.right` SF Symbol at trailing edge, 12pt, `VGTheme.textMuted` foreground. Positioned outside the 3-cell HStack, trailing-aligned. This communicates "this row is navigable" per iOS HIG. |
| Tap response | Pushes `StatsView()` onto the Home tab `NavigationStack` path |
| Animation | Standard iOS `NavigationStack` push transition — no custom animation |
| Visual change to row | None beyond the added chevron. The 3 statCell items are visually unchanged. |

### Daily Wins entry point — NavigationLink to DailyWinsView (WinsView)

| Property | Specification |
|----------|--------------|
| Interaction type | `NavigationLink(destination: DailyWinsView())` — full-width button styled to match `checkInCTA` |
| Touch target | Full-width with `.padding(.vertical, 16)` — yields approximately 52pt height. Satisfies 44pt HIG minimum. |
| Chevron indicator | Not required. The "→" character in the label copy serves the same affordance signal. Consistent with `checkInCTA` pattern ("Log today's check-in →"). |
| Tap response | Pushes `DailyWinsView()` onto the Home tab `NavigationStack` path |
| Animation | Standard iOS `NavigationStack` push transition — no custom animation |
| Conditional display | Always visible on HomeView — not gated on check-in state (unlike `checkInCTA` which hides post-check-in) |

### Explore and Community placeholder views

| Property | Specification |
|----------|--------------|
| Interaction | None — static placeholder text only |
| Tap target | Not applicable |

---

## Accessibility Contract

### Tab bar accessibility

| Tab label | `accessibilityLabel` | `accessibilityHint` |
|-----------|---------------------|---------------------|
| Home | `"Home"` | `"Go to Home"` |
| Goals | `"Goals"` | `"Go to Goals"` |
| Explore | `"Explore"` | `"Go to Explore"` |
| Community | `"Community"` | `"Go to Community"` |
| Profile | `"Profile"` | `"Go to Profile"` |

Note: The existing VGTabBar uses `Button` with a `VStack` label. SwiftUI derives the accessibility label from the visible `Text` content. The rename from "Me" to "Profile" automatically produces the correct label. No explicit `accessibilityLabel` modifier is required for tab items unless the existing VGTabBar already sets one.

### Quick Stats NavigationLink

| Element | `accessibilityLabel` | `accessibilityHint` |
|---------|---------------------|---------------------|
| Quick Stats row (NavigationLink) | `"Stats: [N] active goals, [N] check-ins, [N] badges"` | `"Opens your full statistics"` |

Implementation note: The NavigationLink wrapping the `quickStatsRow` should carry a combined `accessibilityLabel` that summarizes all three values. Derive the string from the same computed values used to render the cells. Mark the individual `statCell` views as `accessibilityHidden(true)` so VoiceOver reads the combined label, not each cell separately.

### Daily Wins entry point

| Element | `accessibilityLabel` | `accessibilityHint` |
|---------|---------------------|---------------------|
| Daily Wins NavigationLink button | `"Daily Wins"` | `"Opens your gratitude and daily wins log"` |

The "→" arrow character in the visible label should be excluded from the accessibility label (SwiftUI renders arrows as decorative by convention; the accessibilityLabel override makes this explicit).

---

## NavigationStack Wiring Summary

This section captures the routing intent for the planner's reference.

| Route | Wired in | Removed from |
|-------|----------|--------------|
| `.stats` → `StatsView()` | Home tab `NavigationStack.navigationDestination` | Goals tab `NavigationStack.navigationDestination` |
| `.wins` → `DailyWinsView()` | Home tab `NavigationStack.navigationDestination` | Goals tab `NavigationStack.navigationDestination` |

The `AppRoute` enum itself is unchanged. Only the `navigationDestination` handler locations change.

---

## Tab Enum Contract

| Enum case | Raw value | Tag value | Notes |
|-----------|-----------|-----------|-------|
| `.home` | `"home"` | 0 | Used in `TabView(selection:)` tag |
| `.goals` | `"goals"` | 1 | |
| `.explore` | `"explore"` | 2 | Swapped from index 3 |
| `.community` | `"community"` | 3 | Swapped from index 2 |
| `.profile` | `"profile"` | 4 | Renamed from `.me` |

`Tab` must conform to `Hashable` (automatic for `String` raw value enums) and `RawRepresentable<String>` for widget intent and deep link routing compatibility.

`CommunityTabView`'s hard-coded `selectedTab = 3` (integer, navigates to old Explore index) must be replaced with `selectedTab = .explore`.

---

## Registry Safety

Not applicable — this is a native SwiftUI project with no third-party component registries, no shadcn, no npm packages, and no web stack.

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending

---

*Phase: 16-tab-restructuring-approute-updates*
*UI-SPEC authored: 2026-05-16*
*Source decisions: 16-CONTEXT.md D-01 through D-09*
