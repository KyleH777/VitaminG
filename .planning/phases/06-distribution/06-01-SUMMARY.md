---
phase: 06-distribution
plan: 01
status: human_needed
completed: 2026-05-01
---

# Summary: Phase 06-01 — Distribution

## What Was Built

Three automated tasks executed successfully. Five human tasks remain (require physical device / web console).

## Automated Tasks Completed

### Task 1: AppIcon.png alpha stripped
- **Problem:** `app_icon.png` (untracked, lowercase) had `hasAlpha: yes`. `Contents.json` referenced `AppIcon.png` (deleted from git index).
- **Resolution:** JPEG round-trip via `sips` to strip alpha channel; output saved as `AppIcon.png` matching Contents.json reference.
- **Verification:** `sips -g hasAlpha AppIcon.png` → `hasAlpha: no`, `pixelWidth: 1024`, `pixelHeight: 1024`

### Task 2: Main app PrivacyInfo.xcprivacy created
- **File:** `VitaminG/VitaminG/VitaminG/PrivacyInfo.xcprivacy`
- **Reasons declared:** `CA92.1` (UserDefaults.standard for notification time keys) + `1C8F.1` (App Group suite for widget sharing)
- **Justification:** `NotificationPreferences.swift` and `SettingsView.swift` both write to UserDefaults.standard; `NotificationPreferences.swift` also writes to `UserDefaults(suiteName: "group.com.kyleharrington.VitaminG")`
- **Target:** Auto-included via `PBXFileSystemSynchronizedRootGroup`

### Task 3: Widget PrivacyInfo.xcprivacy created
- **File:** `VitaminG/VitaminG/VitaminGWidget/PrivacyInfo.xcprivacy`
- **Reason declared:** `1C8F.1` only (widget reads App Group suite; does NOT use `UserDefaults.standard`)
- **CA92.1 correctly absent** — widget only reads via `UserDefaults(suiteName:)`, never `UserDefaults.standard`
- **Target:** Auto-included via `PBXFileSystemSynchronizedRootGroup`

## Commit
`50cd43c` — feat(06-01): app icon alpha fix and privacy manifests

## Human Tasks Remaining

| Task | What's needed | Where |
|------|--------------|-------|
| Task 4 | Promote CloudKit schema Dev → Production | cloudkit.developer.apple.com |
| Task 5 | 5 screenshots at 1290×2796 on iPhone 16 Pro Max Simulator | Xcode Simulator |
| Task 6 | Archive + upload to TestFlight | Xcode Organizer + App Store Connect |
| Task 7 | Validate TestFlight build on physical iPhone; confirm SYNC-03 (CD_Goal records in CloudKit Production) | Physical device |
| Task 8 | Complete App Store Connect listing (description, keywords, privacy label, screenshots, Privacy Policy URL) + submit | appstoreconnect.apple.com |

## Self-Check: PARTIAL
Automated tasks passed all verification criteria. Human tasks remain — see HUMAN-UAT.md.

## key-files
### created
- VitaminG/VitaminG/VitaminG/PrivacyInfo.xcprivacy
- VitaminG/VitaminG/VitaminGWidget/PrivacyInfo.xcprivacy
- VitaminG/VitaminG/VitaminG/Assets.xcassets/AppIcon.appiconset/AppIcon.png (restored without alpha)
