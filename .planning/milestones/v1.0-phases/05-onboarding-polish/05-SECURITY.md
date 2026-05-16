---
phase: 05
slug: onboarding-polish
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-16
---

# Phase 05 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| User input → GoalViewModel | Goal text entered in CreateFirstGoalScreen crosses into SwiftData | User-supplied strings (title ≤100, description ≤500, inspiration ≤300 chars) |
| EmptyTierView onAdd → AddGoalView | User-initiated navigation; no untrusted input | GoalTier enum value (compile-time safe) |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-05-01 | Tampering | @AppStorage("hasCompletedOnboarding") | accept | Low-value local Bool. Tampering only skips/replays onboarding — no security impact. UserDefaults is not a security boundary. | closed |
| T-05-02 | Input Validation | CreateFirstGoalScreen form | mitigate | Reuses GoalViewModel.validate() enforcing title ≤100, description ≤500, inspiration ≤300 chars. No new input surfaces. | closed |
| T-05-03 | Spoofing | EmptyTierView tier parameter | accept | GoalTier is a compile-time enum; cannot be spoofed at runtime. | closed |
| T-05-04 | Information Disclosure | Dark Mode color contrast | accept | Completion green (0.063, 0.725, 0.506) is high-saturation — reads in both modes. Manual WCAG check recommended at phase verification. | closed |
| T-05-05 | Information Disclosure | VoiceOver labels exposing goal titles | accept | Goal titles are the user's own data on their own device — no privacy concern. VoiceOver is an accessibility requirement. | closed |
| T-05-05-01 | Information Disclosure | TierCardView font/color | accept | No data handling changes — font/color presentation only. No new inputs or outputs introduced. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-05-01 | T-05-01 | @AppStorage Bool only controls onboarding replay — no sensitive data, no privilege escalation. Local UserDefaults is not a security boundary. | Kyle (gsd-secure-phase) | 2026-04-16 |
| AR-05-02 | T-05-03 | GoalTier is a compile-time Swift enum. All four cases are defined at build time; no runtime injection path exists. | Kyle (gsd-secure-phase) | 2026-04-16 |
| AR-05-03 | T-05-04 | Completion green is high-saturation and visually distinguishable in both Light and Dark Mode. WCAG AA manual review recommended at App Store submission. | Kyle (gsd-secure-phase) | 2026-04-16 |
| AR-05-04 | T-05-05 | Goal titles are private to the user on their own device. VoiceOver access is required for WCAG/App Store accessibility compliance. Not a privacy risk. | Kyle (gsd-secure-phase) | 2026-04-16 |
| AR-05-05 | T-05-05-01 | TierPickerView change is purely presentational (font sizes and background colors). No data handling, network, or input surface changes. | Kyle (gsd-secure-phase) | 2026-04-16 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-16 | 6 | 6 | 0 | gsd-secure-phase (T-05-02 verified via SUMMARY; T-05-01/03/04/05/05-01 accepted) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-16
