# Phase 6: Distribution - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-27
**Phase:** 06-distribution
**Areas discussed:** PrivacyInfo.xcprivacy (selected); App Store positioning, Screenshot strategy, CloudKit production sequence (Claude's discretion per user preference)

---

## Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| App Store positioning | Pricing, category, description tone, keywords | |
| Screenshot strategy | Device sizes, screens to capture, approach | |
| PrivacyInfo.xcprivacy | Required-reason APIs, App Store privacy label | ✓ |
| CloudKit production sequence | Promotion steps, validation protocol | |

**User note:** "What do you recommend" — indicated preference for Claude recommendations on non-selected areas.

---

## PrivacyInfo.xcprivacy

### Privacy Label — Goal Content

| Option | Description | Selected |
|--------|-------------|----------|
| Data Linked to You | Goals sync via iCloud/CloudKit under Apple ID | |
| Data Not Linked to You | Only accurate for purely local storage | |
| You decide | Claude's discretion | ✓ |

**User's choice:** You decide
**Notes:** Claude defaulted to "Data Linked to You" — correct given CloudKit sync.

### Photos Declaration

| Option | Description | Selected |
|--------|-------------|----------|
| Stub only — declare no photos | photoData field exists but no upload UI | |
| Implemented — declare photos | Photo upload is live | |
| Not sure — check the code | Claude will verify | ✓ |

**User's choice:** Not sure — check the code
**Notes:** Code inspection confirmed no PhotosPicker or UIImagePicker exists anywhere. photoData is a stub in SchemaV2 only. **No photos declared.**

---

## Claude's Discretion

All remaining gray areas were handled by Claude per the user's stated preference ("Recommend everything"):

- **App Store positioning:** Productivity category, Free pricing, 4+ age rating, warm/personal description tone
- **Screenshot strategy:** iPhone-only in App Store Connect, 6.7" required + 6.5" optional, 5 key screens, simulator screenshots with warm gradient overlays
- **CloudKit production sequence:** 8-step ordered sequence; physical device required for TestFlight validation; schema promotion before archive

---

## Deferred Ideas

- App Preview video — defer to post-launch
- iPad-optimized layout — separate phase if ever pursued
- Localization — single English listing sufficient for portfolio launch
- In-app purchases — out of scope; Free is the decision
