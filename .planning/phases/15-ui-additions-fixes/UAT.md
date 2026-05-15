---
phase: 15
plan: "15-09"
status: partial
created: "2026-05-15"
---

# Phase 15 UAT — ui-additions-fixes

## Automated Assertions: PASS

All source-level grep assertions passed. One apparent failure (`@username` literal grep)
is a false negative — ProfileView correctly renders `Text("@\(username)")` at line 154.

| Requirement | Check | Result |
|-------------|-------|--------|
| UIADD-01/02 stayCloseSection | ≥2 | 2 ✓ |
| UIADD-01/02 AboutUsView link | ≥1 | 1 ✓ |
| UIADD-01/02 FAQView link | ≥1 | 1 ✓ |
| UIADD-01/02 quickStatsRow | ≥2 | 2 ✓ |
| UIADD-01/02 checkInCTA | ≥2 | 2 ✓ |
| UIADD-01/02 AboutUsView.swift exists | yes | ✓ |
| UIADD-01/02 FAQView.swift exists | yes | ✓ |
| UIADD-01/02 earnedBadgeCount | ≥1 | 1 ✓ |
| UIADD-01/02 no JSONDecoder in View | 0 | 0 ✓ |
| UIADD-03 VitaminDispenserView | ≥2 | 3 ✓ |
| UIADD-03 MoodScannerView | ≥2 | 3 ✓ |
| UIADD-03 VitaminShelfGrid | ≥2 | 3 ✓ |
| UIADD-03 no catalogueSection | 0 | 0 ✓ |
| UIADD-03 @discardableResult | 1 | 1 ✓ |
| UIADD-04 communityGoals in CommunityTabView | ≥1 | 1 ✓ |
| UIADD-04 no communityFeed in CommunityTabView | 0 | 0 ✓ |
| UIADD-04 CommunityGoalsLandingView.swift exists | yes | ✓ |
| UIADD-04 postCheckInPhoto in LandingView | ≥1 | 1 ✓ |
| UIADD-04 no joinedAt in LandingView | 0 | 0 ✓ |
| UIADD-04 startDate in LandingView | ≥1 | 1 ✓ |
| UIADD-04 CommunityGoalsLandingView in ContentView | ≥2 | 3 ✓ |
| UIADD-05 overrideMoodDisplay | ≥3 | 4 ✓ |
| UIADD-05 requestCameraAndShow | ≥2 | 2 ✓ |
| UIADD-05 AVCaptureDevice.authorizationStatus | 1 | 1 ✓ |
| UIADD-05 handlePhotoSelection | ≥1 | 1 ✓ |
| UIADD-05 no compressToJPEG in View | 0 | 0 ✓ |
| UIADD-06 SignInWithAppleButton | 1 | 1 ✓ |
| UIADD-06 import AuthenticationServices | 1 | 1 ✓ |
| UIADD-06 Google coming soon text | 1 | 1 ✓ |
| UIADD-07 SchemaV8.swift exists | yes | ✓ |
| UIADD-07 var username: String? | 1 | 1 ✓ |
| UIADD-07 migrateV7toV8 | ≥1 | 2 ✓ |
| UIADD-07 SchemaV8.UserProfile in Schema8pV2 | ≥1 | 1 ✓ |
| UIADD-07 draftUsername in ViewModel | ≥2 | 7 ✓ |
| UIADD-07 validateAndSaveUsername | ≥1 | 1 ✓ |
| UIADD-07 draftUsername in EditSheet | ≥1 | 4 ✓ |
| UIADD-07 @username in ProfileView | ≥1 | Text("@\(username)") at line 154 ✓ |
| Infrastructure communityGoals in AppRoute | 1 | 1 ✓ |
| Infrastructure .communityGoals in ContentView | ≥1 | 3 ✓ |
| Infrastructure NSCameraUsageDescription | 1 | 1 ✓ |
| Infrastructure postCheckInPhoto in CommunityService | ≥1 | 1 ✓ |

## Human UAT: PENDING

Status: awaiting user on-device verification of 40 items (see 15-09-PLAN.md Task 2).
