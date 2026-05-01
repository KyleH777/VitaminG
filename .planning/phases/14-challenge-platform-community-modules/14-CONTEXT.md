# Phase 14: Challenge Platform — Community & Modules — Context

**Status:** Not yet gathered — run `/gsd-discuss-phase 14` after Phase 13 completes.

**Phase goal:** Community feed (CloudKit public DB, reactions, profanity filter), all 5 optional modules (Spending Freeze, Craving Tools, Transformation Photos, Nutrition Log, Buddy Accountability), Custom Challenge builder, full notification suite.

**Requirements:** CHAL-13 through CHAL-25

**Depends on:** Phase 13 (challenge engine must exist)

**Key open questions before planning:**
- Profanity filter approach: on-device word list, CoreML NaturalLanguage, or Apple's CreateML classifier?
- CloudKit public DB moderation: how are reported posts actioned without a backend? (Auto-hide at N reports?)
- Buddy ping: local UNUserNotification to a contact or CloudKit push? (Contacts framework needed)
- Transformation photos: CloudKit private DB asset storage size constraints

---
*Added to roadmap 2026-05-01*
