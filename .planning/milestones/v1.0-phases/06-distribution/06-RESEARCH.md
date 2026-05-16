# Phase 06: Distribution - Research

**Researched:** 2026-04-27
**Domain:** iOS App Store Distribution — PrivacyInfo.xcprivacy, CloudKit schema promotion, TestFlight, App Store submission, screenshot requirements
**Confidence:** HIGH (primary sources verified via Apple official documentation and confirmed in developer forums)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Create `PrivacyInfo.xcprivacy` in the main app target (`VitaminG/`). Required-reason API entry: `NSPrivacyAccessedAPICategoryUserDefaults` with reasons `CA92.1` and `1C8F.1`.
- **D-02:** No other required-reason APIs needed. The app does not use file timestamp APIs, system boot time APIs, disk space APIs, or active keyboard APIs.
- **D-03:** `photoData` field exists in `UserProfile` (SchemaV2) but no photo upload/picker UI was ever implemented — no Photos data declared.
- **D-04:** Goal titles and descriptions → Data Linked to You (User Content category).
- **D-05:** Display name → Data Linked to You (Contact Info / Name category).
- **D-06:** Notification time preference → not declared — stored in `UserDefaults` locally, never transmitted off-device.
- **D-07:** No "Data Used to Track You" declarations.
- **D-08:** Category: Productivity (primary). No secondary category.
- **D-09:** Pricing: Free, no in-app purchases.
- **D-10:** Age Rating: 4+.
- **D-11:** Description tone: Warm, personal, intentional. Tagline: "Your daily dose of goals."
- **D-12:** Keywords: goal tracker, daily goals, gratitude, habit tracker, productivity, reminders, streaks, life goals, motivation (all 100 chars).
- **D-13:** iPhone-only submission in App Store Connect.
- **D-14:** Required screenshot size: iPhone 6.7" (1290×2796 px). [SEE ASSUMPTION A1 — this changed in Sept 2024]
- **D-15:** Optional second size: iPhone 6.5" (1284×2778 px).
- **D-16:** 5 key screens to capture.
- **D-17:** Xcode Simulator screenshots + warm gradient background overlay + one short caption per screenshot.
- **D-18:** Dark mode screenshots optional.
- **D-19:** CloudKit container ID: `iCloud.com.kyleharrington.VitaminG`.
- **D-20:** Required promotion sequence documented in CONTEXT.md.
- **D-21:** Schema promotion is irreversible for existing fields.
- **D-22:** TestFlight scope: Internal testing only.

### Claude's Discretion

- Exact App Store description body copy
- Screenshot caption text and exact overlay layout
- Whether to include App Preview video (recommended to skip for initial submission)
- Specific error message copy in the App Store listing subtitle and promotional text

### Deferred Ideas (OUT OF SCOPE)

- App Preview (video)
- iPad-optimized layout
- Localization / App Store listing in multiple languages
- In-app purchases or subscription model
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SYNC-03 | CloudKit schema promoted to Production before App Store submission | CloudKit Console deploy workflow documented in Section 4; prerequisites and verification steps confirmed via fatbobman and official CloudKit docs |
</phase_requirements>

---

## Summary

Phase 6 is a delivery-only phase: the code is complete and no new Swift files are written except `PrivacyInfo.xcprivacy`. The three execution domains are (1) privacy manifest creation, (2) CloudKit schema promotion + TestFlight validation, and (3) App Store Connect metadata and submission.

**Critical pre-flight blockers discovered in research:**
1. The existing `AppIcon.png` is RGBA (with alpha channel) — App Store validation will reject it with ITMS error. The alpha channel must be stripped before archiving.
2. The screenshot size requirement changed on September 23, 2024 from 6.7" primary to 6.9" primary (1320×2868 px for iPhone 16 Pro Max). CONTEXT.md D-14 references the old 6.7" requirement. The 6.7" size is still accepted as a fallback if 6.9" is not provided, but submitting 6.9" is now the recommended path.
3. The widget target (`VitaminGWidget`) also reads UserDefaults from the App Group suite — it requires its own `PrivacyInfo.xcprivacy` file with reason `1C8F.1`.

**Primary recommendation:** Execute in sequence: (1) fix AppIcon.png alpha, (2) create both PrivacyInfo.xcprivacy files, (3) promote CloudKit schema, (4) archive + upload to TestFlight, (5) validate on physical device, (6) complete App Store metadata + submit.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| PrivacyInfo.xcprivacy (main app) | App Bundle — main target | — | Per-bundle declaration; each binary that uses required-reason APIs must declare them in its own bundle |
| PrivacyInfo.xcprivacy (widget) | App Bundle — widget extension target | — | Widget is a separate bundle; reads App Group UserDefaults independently of main app |
| CloudKit schema promotion | External service (CloudKit Console) | — | Done in Apple's web console before archive; not a code artifact |
| TestFlight distribution | External service (App Store Connect) | — | Upload via Xcode Organizer; validation on physical device |
| App Store metadata | External service (App Store Connect) | — | Privacy label, screenshots, description filled in web UI |
| App icon (fix alpha) | Asset catalog | — | Must be corrected before archive build |

---

## Standard Stack

### Core (no new dependencies — all native Apple tooling)

| Tool | Version | Purpose | Notes |
|------|---------|---------|-------|
| Xcode | 15.4+ (latest stable) | Archive, organizer, upload | Must use Xcode 14+ for App Store uploads |
| CloudKit Console | web (cloudkit.developer.apple.com) | Schema deployment | Browser-based; no install required |
| App Store Connect | web (appstoreconnect.apple.com) | Metadata, TestFlight, submission | Browser-based |
| iOS Simulator | Xcode-bundled | Screenshot capture | Use iPhone 16 Pro Max (6.9") target for current requirement |
| Preview.app / sips | macOS built-in | Strip alpha from AppIcon.png | No third-party tool needed |

**No new Swift packages or CocoaPods are added in this phase.**

---

## Architecture Patterns

### System Architecture Diagram

```
[Developer Machine]
     |
     |-- Xcode Archive (Release scheme, App Store Connect profile)
     |        |
     |        +--> Xcode Organizer --> [App Store Connect] --> TestFlight build
     |                                         |
     |                                         +--> Internal tester devices (physical iPhone)
     |                                         |         |
     |                                         |         +--> CloudKit Production (iCloud.com.kyleharrington.VitaminG)
     |                                         |
     |                                         +--> App Store Review submission
     |
     |-- CloudKit Console (cloudkit.developer.apple.com)
              |
              +--> Container: iCloud.com.kyleharrington.VitaminG
                       |
                       +--> [Development] schema --- Deploy --> [Production] schema
                                                                      |
                                                                      +--> Record types: CD_Goal, CD_CompletionEvent, CD_UserProfile
                                                                           (Note: SwiftData prepends "CD_" to record type names)
```

### Recommended File Structure for Phase 6 Artifacts

```
VitaminG/VitaminG/VitaminG/
├── PrivacyInfo.xcprivacy          # NEW — main app target
VitaminG/VitaminG/VitaminGWidget/
├── PrivacyInfo.xcprivacy          # NEW — widget extension target

App Store Connect (web):
├── Screenshots (6.9" primary: 1320×2796 or 1290×2796)
├── App description, keywords, subtitle
└── Privacy nutrition label answers

CloudKit Console:
└── Deploy Schema Changes to Production (one-time action before TestFlight)
```

---

## Section 1: PrivacyInfo.xcprivacy — Exact Format

### What PrivacyInfo.xcprivacy Is

`PrivacyInfo.xcprivacy` is a property list file required by Apple since May 1, 2024. It declares which "required reason APIs" a bundle uses and why. It is distinct from the App Store Privacy Nutrition Label: the manifest is a code artifact compiled into the bundle; the nutrition label is filled out manually in App Store Connect. Xcode can generate a privacy report from all manifests in the project to assist with filling the nutrition label.
[CITED: developer.apple.com/documentation/bundleresources/privacy-manifest-files]
[CITED: developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk]

### UserDefaults Reason Codes — Complete List

All four valid reason codes for `NSPrivacyAccessedAPICategoryUserDefaults`:
[VERIFIED: Apple Developer Forums thread 744454, confirmed via multiple sources]

| Code | Meaning | Applies to VitaminG? |
|------|---------|----------------------|
| **CA92.1** | Read/write UserDefaults accessible only to the app itself (standard `UserDefaults.standard`) | YES — main app reads `notificationHour`/`notificationMinute` from `UserDefaults.standard` |
| **1C8F.1** | Read/write UserDefaults accessible to apps, extensions, and App Clips in the same App Group (suite name `group.com.kyleharrington.VitaminG`) | YES — both main app and widget read from `UserDefaults(suiteName: "group.com.kyleharrington.VitaminG")` |
| C56D.1 | For third-party SDKs providing wrapper functions around UserDefaults | NO — VitaminG has no third-party SDKs |
| AC6B.1 | Read `com.apple.configuration.managed` or `com.apple.feedback.managed` key (MDM) | NO — not an enterprise/MDM app |

**VitaminG uses both CA92.1 and 1C8F.1.** The `NotificationPreferences.save()` method writes to `UserDefaults.standard` (requires CA92.1) AND to `UserDefaults(suiteName: "group.com.kyleharrington.VitaminG")` (requires 1C8F.1).

**Note:** Xcode 15.2 does not show the 1C8F.1 option in the UI dropdown; it must be added manually via the XML editor or by using Xcode 15.3+. [CITED: developer.apple.com/forums/thread/744454]

### Main App PrivacyInfo.xcprivacy — Exact XML

File location: `VitaminG/VitaminG/VitaminG/PrivacyInfo.xcprivacy`

This file must be added to the **VitaminG target's "Copy Bundle Resources" build phase**.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>

    <key>NSPrivacyTrackingDomains</key>
    <array/>

    <key>NSPrivacyCollectedDataTypes</key>
    <array/>

    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
                <string>1C8F.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

**Key explanations:**
- `NSPrivacyTracking: false` — no cross-app/cross-site tracking
- `NSPrivacyTrackingDomains: []` — no tracking domains
- `NSPrivacyCollectedDataTypes: []` — the collected data types are declared separately in App Store Connect (nutrition label), not here
- `NSPrivacyAccessedAPITypes` — lists the required-reason APIs and justifications

### Widget Extension PrivacyInfo.xcprivacy — REQUIRED

**`VitaminGWidget` MUST have its own `PrivacyInfo.xcprivacy`.** [VERIFIED: developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk + Apple Developer Forums thread 742221 DTS Engineer response]

The rule, per a DTS Engineer: "Add a privacy manifest file to each target that builds an app or third-party SDK that collects data or uses required reason APIs."

`WidgetNotificationPreferences.swift` calls `UserDefaults(suiteName: "group.com.kyleharrington.VitaminG")` — this is a required-reason API use within the widget bundle. The widget does NOT use `UserDefaults.standard`, so it does NOT need CA92.1, but it does need 1C8F.1.

File location: `VitaminG/VitaminG/VitaminGWidget/PrivacyInfo.xcprivacy`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>

    <key>NSPrivacyTrackingDomains</key>
    <array/>

    <key>NSPrivacyCollectedDataTypes</key>
    <array/>

    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>1C8F.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

### How to Add PrivacyInfo.xcprivacy in Xcode

For each target:
1. In Xcode Project Navigator, right-click the target's folder → New File
2. Select "App Privacy" template (or create empty file named `PrivacyInfo.xcprivacy`)
3. In Target Membership (right panel), check **only** the correct target (main app OR widget, not both)
4. Xcode shows a structured editor; switch to XML source view to paste the exact XML above
5. Verify in Build Phases → Copy Bundle Resources that `PrivacyInfo.xcprivacy` appears for that target

---

## Section 2: App Icon Fix — Blocking Prerequisite

**The existing `AppIcon.png` has an alpha channel (RGBA mode) and will fail App Store validation.**
[VERIFIED: `sips` tool output showing "8-bit/color RGBA" — confirmed alpha channel present]

Apple's error will be: "The App Store Icon in the asset catalog in 'VitaminG.app' can't be transparent nor contain an Alpha Channel."
[CITED: developer.apple.com/forums/thread/96003]

### How to Fix (macOS Preview — no tools required)

1. Open `VitaminG/VitaminG/VitaminG/Assets.xcassets/AppIcon.appiconset/AppIcon.png` in Preview.app
2. File → Export → uncheck "Alpha" → Export (overwrite same file)
3. Verify: `sips -g hasAlpha AppIcon.png` should return `hasAlpha: no`

Alternatively via command line:
```bash
sips --setProperty format png --out AppIcon_fixed.png AppIcon.png
# Then verify no alpha:
sips -g pixelWidth -g pixelHeight -g hasAlpha AppIcon_fixed.png
```

**The icon asset catalog is already configured correctly for Xcode 14+ single-size mode** — the `Contents.json` has `"idiom": "universal", "platform": "ios", "size": "1024x1024"` which triggers Xcode's automatic downscaling. No additional sizes need to be provided for iOS. The dark and tinted appearance slots are optional; leaving them without a filename is valid.
[CITED: useyourloaf.com/blog/xcode-14-single-size-app-icon]
[VERIFIED: Contents.json inspection confirms single-size universal iOS configuration]

---

## Section 3: Screenshot Requirements — CONTEXT.md D-14 Correction

**CONTEXT.md D-14 contains an outdated screenshot size.** On September 23, 2024, Apple changed the primary required screenshot size from 6.7" to 6.9".
[CITED: gummicube.com/blog/apple-screenshot-dimensions-have-changed — "change became effective September 23, 2024"]
[CITED: developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications — "6.9" display required if app runs on iPhone"]

### Current Requirements (as of September 2024)

| Display | Required? | Accepted Pixel Dimensions (portrait) | Simulator Target |
|---------|-----------|--------------------------------------|-----------------|
| 6.9" | **Required** (primary) | 1290×2796 or 1320×2868 | iPhone 16 Pro Max |
| 6.5" | Required **only if** 6.9" not provided | 1284×2778 or 1242×2688 | iPhone 14 Plus, iPhone 11 Pro Max |
| All others | Auto-scaled | — | Not needed |

**Practical path:** Use iPhone 16 Pro Max simulator → `File > New Screen Shot` → screenshots save to Desktop at 1290×2796. This satisfies the 6.9" requirement and Apple auto-scales to all smaller devices.

**D-14 should be updated:** Replace "iPhone 6.7" (1290×2796 px) — use Xcode Simulator with iPhone 15 Pro Max target" with "iPhone 6.9" (1290×2796 px) — use Xcode Simulator with iPhone 16 Pro Max target."

### Xcode Simulator Screenshot Capture

```bash
# Programmatic capture (saves to specified path)
xcrun simctl io booted screenshot --type=png screenshot_name.png

# Or: in Simulator, use File > New Screen Shot (saves to Desktop)
```

Screenshots captured from Simulator save at the device's native logical resolution. The iPhone 16 Pro Max Simulator captures at 1290×2796 px portrait (native resolution, accepted by App Store Connect for the 6.9" slot).

---

## Section 4: CloudKit Schema Promotion — Exact Steps

### Prerequisites

Before promoting, verify the Development schema is complete:
[CITED: developer.apple.com/documentation/cloudkit/deploying-an-icloud-container-s-schema]
[CITED: fatbobman.com/en/snippet/why-core-data-or-swiftdata-cloud-sync-stops-working-after-app-store-login]

1. Run the app in Development mode (Simulator or physical device with DEBUG build)
2. Create at least one Goal, one CompletionEvent, and one UserProfile to ensure all record types are registered in Development
3. If any record type is missing from Development schema, call `ModelContainerFactory.initializeCloudKitSchema()` in DEBUG mode to force schema registration (already implemented in codebase)

### Exact CloudKit Console Steps

1. Navigate to **https://cloudkit.developer.apple.com** (CloudKit Console — replaced the old "CloudKit Dashboard")
2. Select **CloudKit Database** from the app list
3. In the container dropdown (top-left), choose **iCloud.com.kyleharrington.VitaminG**
4. Ensure you are in the **Development** environment (toggle at top)
5. In the left sidebar, locate **Schema → Deploy Schema Changes...**
6. Review the diff view — confirm it shows:
   - `CD_Goal` record type with all fields: `CD_id`, `CD_title`, `CD_goalDescription`, `CD_tierRawValue`, `CD_isCompleted`, `CD_creationDate`, `CD_associatedInspiration`, `CD_isPublic`
   - `CD_CompletionEvent` record type with fields: `CD_id`, `CD_completedAt`, `CD_tierRawValue`
   - `CD_UserProfile` record type with fields: `CD_id`, `CD_displayName`, `CD_avatarColorHex`, `CD_isPublic`, `CD_cloudKitPublicRecordID`, `CD_photoData`
   - Note: SwiftData prefixes all CloudKit record type names with `CD_`
7. Click **Deploy**

### What Gets Promoted vs. What Doesn't

| Promoted | Not Promoted |
|----------|-------------|
| Record type schemas (field names, types) | Data/records from Development environment |
| Indexes | User data |
| Security roles | TestFlight builds' data |

After promotion, the **Production** environment schema is visible but empty of data. Users installing from TestFlight or App Store will start with a fresh iCloud container — their data is stored in Production, not Development.

### Why This Step Is Required (and Often Missed)

[CITED: multiple developer forum posts, fatbobman, leojkwan.com]

In **Development**: CloudKit automatically creates record types the first time your app writes to them.
In **Production**: CloudKit does NOT auto-create record types. If schema is not promoted, iCloud sync silently fails — data saves locally but never syncs. This is the #1 CloudKit gotcha.

### Irreversibility Warning

After promotion: fields can only be **added** to existing record types. Fields cannot be renamed or deleted from Production. All SchemaV1 and SchemaV2 fields are finalized per D-21 — promotion is safe.

---

## Section 5: App Store Connect Submission Workflow

### Pre-Upload Checklist

- [ ] AppIcon.png has no alpha channel
- [ ] Both PrivacyInfo.xcprivacy files created and added to correct targets
- [ ] CloudKit schema promoted to Production
- [ ] Archive builds from: Product → Archive with scheme set to Release and destination "Any iOS Device (arm64)"

### Archive and Upload Steps

[CITED: help.apple.com/xcode/mac/current/en.lproj/dev442d7f2ca.html]

1. In Xcode: select **Product → Archive** (destination must be "Any iOS Device" not a simulator)
2. Xcode Organizer opens automatically showing the new archive
3. Select the archive → click **Distribute App**
4. Select **App Store Connect** → click **Next**
5. Select **Upload** → click **Next**
6. Distribution options: accept defaults (include bitcode symbols, upload symbols)
7. Signing: **Automatically manage signing** (recommended for first upload) → Next
8. Click **Upload**
9. Build processing takes 10-30 minutes; email arrives when complete

### First-Time App Submission in App Store Connect

1. **Create the app record** (if not done):
   - App Store Connect → My Apps → "+" → New App
   - Platform: iOS
   - Name: "Vitamin G" (or "Vitamin G: Daily Goal Tracker")
   - Primary Language: English (U.S.)
   - Bundle ID: select from list (must match Xcode project bundle ID)
   - SKU: any unique string (e.g., "vitamingapp-001")

2. **App Information tab:**
   - Category: Productivity (primary) [D-08]
   - Subtitle: "Your daily dose of goals"
   - Age Rating: complete the questionnaire → 4+ [D-10]
   - Privacy Policy URL: required for any App Store submission — must add a privacy policy URL

3. **Pricing and Availability tab:**
   - Price: Free [D-09]
   - Availability: All countries/regions

4. **App Privacy tab (Nutrition Label):**
   Fill in manually, consistent with CONTEXT.md decisions:
   - Data Used to Track You: None [D-07]
   - Data Linked to You:
     - User Content → Goals (goal titles, descriptions) [D-04]
     - Contact Info → Name (display name in UserProfile) [D-05]
   - Data Not Linked to You: None
   - Note: notification time preference NOT declared — local UserDefaults, never transmitted [D-06]

5. **Version Information tab:**
   - Screenshots: upload 6.9" images (see Section 3)
   - Description: warm tone, lead with morning reminder value prop [D-11]
   - Keywords: full 100-character string [D-12]
   - What's New: "Initial release"
   - Support URL: GitHub repo URL or personal site
   - App Review Information: add notes explaining iCloud sync behavior (see App Review Notes below)

6. **Select build:** choose the processed TestFlight build

7. **Submit for Review**

### App Review Notes — What to Write

For CloudKit/iCloud apps, include notes in App Review Information → Notes field:
```
This app uses CloudKit for iCloud sync. Core functionality (creating and viewing goals,
receiving notifications, viewing statistics) works fully without an iCloud account.
iCloud sync is additive — data syncs automatically when the user is signed in to iCloud.
No account creation or login is required to use the app.

The Profile tab's "Make Public" feature requires iCloud. When iCloud is unavailable,
this feature is gracefully disabled.
```

**Privacy Policy requirement:** Apple requires a Privacy Policy URL for all apps that handle user data. A minimal hosted privacy policy page must be created before submission. [ASSUMED — standard requirement, not project-specific]

---

## Section 6: TestFlight Internal Testing

### Setup Steps

[CITED: developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers]

1. In App Store Connect → TestFlight tab
2. Click "+" next to **Internal Testing** → create a group (e.g., "Internal")
3. Click **Invite Testers** → add Apple ID email addresses (must be App Store Connect users with Developer or Admin role)
4. Enable **Automatic Distribution** to deliver all new builds to the group automatically

### Internal Tester Limits

- Max 100 internal testers
- TestFlight builds available for 90 days
- Internal testing does NOT require App Store Review approval

### Validation Flows to Test (per D-22)

| Flow | Steps | Expected |
|------|-------|----------|
| Create goal | Open app → Goals tab → "+" → fill form → Save | Goal appears in list |
| Complete goal | Tap completion toggle on a goal | CompletionEvent created; streak updates in Stats |
| View stats | Stats tab | Heatmap shows today's completions; streak counts correct |
| Receive notification | Wait until configured time (or use Settings → change time to ~1 minute from now) | Notification appears with goal titles |
| View profile | Profile tab | Avatar, display name, privacy toggle visible |
| Share profile | Profile tab → Share | vitaming:// URL in share sheet |
| Tap shared link | On another device, tap vitaming:// URL | Opens app to profile view |
| **CloudKit sync verification** | Create goal on TestFlight device → check CloudKit Console → change to Production environment → verify `CD_Goal` record appears | Record visible in Production console |

### TestFlight → Production Environment

TestFlight builds automatically use the **Production** CloudKit environment (not Development). This is why the schema must be promoted BEFORE uploading the TestFlight build.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Multi-size app icons | Manual image resize | Xcode single-size asset catalog | Xcode auto-scales from 1024x1024 for all needed sizes |
| Privacy manifest format | Invent XML structure | Apple's exact keys (NSPrivacyTracking, NSPrivacyAccessedAPITypes) | Wrong keys cause ITMS rejection |
| Upload to App Store | curl / direct API | Xcode Organizer → Distribute App | Handles signing, notarization, symbol upload automatically |
| Schema promotion | API scripts | CloudKit Console web UI | One-time action; console shows diff view for safety |
| Remove alpha from icon | Image editor | `sips` (built-in macOS) | Zero dependency; one command |

---

## Common Pitfalls

### Pitfall 1: Widget Extension Missing PrivacyInfo.xcprivacy
**What goes wrong:** App Store validation passes for main app, but App Store rejects or sends ITMS warning for the widget extension bundle.
**Why it happens:** Developers create the manifest for the main target and assume it covers all extensions — it does not. Each bundle is evaluated independently.
**How to avoid:** Create `PrivacyInfo.xcprivacy` in `VitaminGWidget/` directory AND verify it appears in VitaminGWidget's Target Membership and Build Phases → Copy Bundle Resources.
**Warning signs:** ITMS-91053 email after upload, specifically mentioning the widget extension bundle.

### Pitfall 2: PrivacyInfo.xcprivacy Added to Wrong Target
**What goes wrong:** The file exists on disk but isn't bundled — either not in target membership or not in Copy Bundle Resources.
**Why it happens:** Creating a file in Xcode sometimes adds it to all targets or the wrong target.
**How to avoid:** After creating both files, verify in Xcode's Target → Build Phases → Copy Bundle Resources that each manifest appears in exactly the correct target.
**Warning signs:** No ITMS error at upload, but App Review sends Missing API Declaration email post-review.

### Pitfall 3: CloudKit Schema Not Promoted Before TestFlight Upload
**What goes wrong:** TestFlight testers experience no iCloud sync; data saves locally but never appears on a second device. No error shown to the user.
**Why it happens:** Development environment auto-creates schema; Production does not. The promotion step is a manual web UI action.
**How to avoid:** Promote schema FIRST, then archive and upload. Never archive first then promote — the deployed build connects to whichever schema was live at launch time.
**Warning signs:** CloudKit Console → switch to Production environment → Record Types shows no record types (or only default system types).

### Pitfall 4: AppIcon Alpha Channel Blocking Upload
**What goes wrong:** Xcode Organizer upload fails with validation error: "The App Store Icon... can't be transparent nor contain an Alpha Channel."
**Why it happens:** The existing `AppIcon.png` is RGBA (confirmed by research). Apple enforces opaque icons.
**How to avoid:** Strip alpha BEFORE attempting to archive. Use Preview.app → Export (uncheck Alpha) or `sips` command.
**Warning signs:** Xcode shows error in the Organizer "Validate App" step before upload even starts.

### Pitfall 5: Screenshot Size Mismatch (6.7" submitted when 6.9" required)
**What goes wrong:** App Store Connect rejects screenshot upload or warns that screenshots don't match the required device.
**Why it happens:** The requirement changed September 23, 2024. CONTEXT.md D-14 still references 6.7" (1290×2796 on iPhone 15 Pro Max).
**How to avoid:** Use iPhone 16 Pro Max simulator (6.9", 1290×2796 px) for primary screenshots. The 1290×2796 pixel dimension is shared by both 6.7" and one of the accepted 6.9" sizes — this may work as-is, but using the iPhone 16 Pro Max simulator explicitly satisfies the 6.9" requirement.
**Warning signs:** App Store Connect upload UI rejects screenshot file or shows "not accepted for this display size."

**Important nuance:** The pixel dimensions 1290×2796 are accepted for BOTH the 6.7" (iPhone 15 Pro Max) and the 6.9" display slot. If CONTEXT.md screenshots are already taken at 1290×2796 (from iPhone 15 Pro Max simulator), they may satisfy the 6.9" slot in App Store Connect — Apple's spec lists 1290×2796 as one of the accepted dimensions for the 6.9" category. Verify in App Store Connect UI which slot the upload is assigned to. The safest path is to shoot on iPhone 16 Pro Max simulator at 1290×2796 explicitly.

### Pitfall 6: iCloud Graceful Degradation (App Review Guideline 5.1.1)
**What goes wrong:** App Store Review may flag the app if core features require iCloud and the reviewer's device is not signed into iCloud.
**Why it happens:** Guideline 5.1.1 requires that apps work without mandatory account sign-in unless directly necessary.
**How to avoid:** VitaminG uses `cloudKitDatabase: .automatic` via SwiftData — this configuration gracefully falls back to local-only storage when iCloud is unavailable. The app DOES work without iCloud (goals, stats, notifications all function locally). The Profile "Make Public" toggle gracefully fails when iCloud is absent. This is distinct from old-style CloudKit apps that would crash without iCloud. Include a note in App Review Notes explaining this behavior.
**Warning signs:** App Review response referencing guideline 5.1.1 asking about functionality without iCloud.

### Pitfall 7: Privacy Policy URL Required
**What goes wrong:** App Store Connect submission blocked because Privacy Policy URL field is empty.
**Why it happens:** Apple requires a Privacy Policy URL for apps that collect or sync user data — VitaminG syncs user content via CloudKit.
**How to avoid:** Create and host a minimal privacy policy before submission. Options: GitHub Pages, Notion public page, or any public URL. Must be included in the App Information section of App Store Connect.
**Warning signs:** App Store Connect submission flow shows "Privacy Policy URL is required."

---

## Code Examples

### Strip Alpha from AppIcon.png

```bash
# Source: Apple sips man page (built-in macOS tool)

# Check current state
sips -g hasAlpha "/path/to/AppIcon.png"
# Output: hasAlpha: yes  (current state — needs fixing)

# Strip alpha (creates new file; then replace original)
sips --setProperty format png --out AppIcon_opaque.png AppIcon.png

# Verify fix
sips -g hasAlpha AppIcon_opaque.png
# Output: hasAlpha: no  (correct)
```

### Take Screenshot from Simulator (command line)

```bash
# Source: developer.apple.com/documentation/xcode/capturing-screenshots-and-videos-from-simulator
xcrun simctl io booted screenshot --type=png "screenshot_$(date +%Y%m%d_%H%M%S).png"
```

### Verify PrivacyInfo.xcprivacy in Bundle (post-archive check)

```bash
# After archiving, confirm PrivacyInfo.xcprivacy is in both bundles:
# Check main app:
find ~/Library/Developer/Xcode/Archives -name "PrivacyInfo.xcprivacy" 2>/dev/null
```

### CloudKit Schema Pre-Promotion Verification

```swift
// Source: ModelContainerFactory.swift (already implemented)
// Run in DEBUG before promotion to ensure all record types are registered:
#if DEBUG && !targetEnvironment(simulator)
ModelContainerFactory.initializeCloudKitSchema(container: container)
#endif
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Multiple icon sizes in asset catalog | Single 1024×1024 "universal" entry | Xcode 14 (2022) | No manual resizing needed |
| CloudKit Dashboard (old URL) | CloudKit Console (cloudkit.developer.apple.com) | WWDC21 | New URL; old dashboard URLs redirect |
| No privacy manifest required | PrivacyInfo.xcprivacy required for required-reason APIs | May 1, 2024 | Missing manifest triggers ITMS rejection |
| 6.7" primary screenshot requirement | 6.9" primary screenshot requirement | September 23, 2024 | Must capture on iPhone 16 Pro Max simulator |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | CONTEXT.md D-14 says 6.7" is required; research indicates 6.9" became primary on Sept 23, 2024. The 1290×2796 px dimension is accepted for both 6.7" and 6.9" slots in App Store Connect, so the decision may still work. | Section 3 | Screenshot upload rejected if App Store Connect enforces 6.9" exclusively; low risk if same pixel dimensions are accepted in 6.9" slot |
| A2 | Privacy Policy URL is required for this app (due to CloudKit user content sync) | Section 5 | Submission blocked if URL not provided — high confidence this is required |
| A3 | `NSPrivacyCollectedDataTypes` key should be an empty array (not omitted) in the manifest. Some sources omit it; the XML template above includes it for completeness | Section 1 | No functional impact; extra empty key is harmless |
| A4 | App Store Review won't reject due to CloudKit dependency because SwiftData's `.automatic` mode gracefully falls back to local-only storage — the app is fully functional without iCloud | Section 5 / Pitfall 6 | Rejection under guideline 5.1.1 if reviewer can't test sync; low risk given graceful degradation |

---

## Open Questions

1. **Does 1290×2796 px satisfy the 6.9" slot in App Store Connect?**
   - What we know: 1290×2796 is listed as an accepted size for 6.9" in Apple's official spec document
   - What's unclear: Whether submitting via iPhone 15 Pro Max (which produces 1290×2796) triggers a 6.7" slot vs. 6.9" slot assignment in the App Store Connect UI
   - Recommendation: Use iPhone 16 Pro Max simulator explicitly to avoid ambiguity; its 1290×2796 output will unambiguously hit the 6.9" slot

2. **Does the App Icon dark/tinted appearance need to be provided?**
   - What we know: The Contents.json has dark and tinted appearance entries with no filename — these are optional slots
   - What's unclear: Whether leaving them blank causes a warning in the Organizer validation
   - Recommendation: Leave blank for initial submission; App Store does not reject for missing dark/tinted icon variants

3. **Privacy Policy URL — where to host?**
   - What we know: A public URL is required; any hosted page suffices
   - What's unclear: Exact content requirements for the policy
   - Recommendation: Create a minimal GitHub Pages page or Notion public page with a basic privacy policy mentioning iCloud sync before submission

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode 15.3+ | PrivacyInfo 1C8F.1 reason UI | ASSUMED ✓ | Xcode 15.x on developer machine | Manually edit XML (works fine) |
| CloudKit Console (browser) | Schema promotion | ✓ | Web-based | None needed |
| App Store Connect (browser) | Metadata, TestFlight, submission | ✓ | Web-based | None needed |
| Physical iPhone with iCloud | TestFlight CloudKit validation (D-22) | ASSUMED ✓ | Any iOS 17+ device | Cannot validate Production sync without physical device |
| sips (macOS) | Alpha channel removal from AppIcon.png | ✓ | Built into macOS | Preview.app export |

---

## Validation Architecture

**Per config.json: `workflow.nyquist_validation: true` — section included.**

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest (existing) |
| Config file | VitaminGTests/VitaminGTests.swift |
| Quick run command | `xcodebuild test -scheme VitaminG -destination 'platform=iOS Simulator,name=iPhone 15'` |
| Full suite command | Same — all unit tests in a single scheme |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SYNC-03 | CloudKit schema promoted to Production | Manual validation | CloudKit Console → switch to Production → verify record types | Manual only — cannot automate CloudKit console actions |

**Note:** SYNC-03 is a deployment task, not a code behavior. Automated tests cannot verify CloudKit Console state. The validation gate is human inspection of the Production schema and physical device TestFlight sync verification.

### Wave 0 Gaps

None — Phase 6 has no new Swift code requiring unit tests. The sole testable artifact is the PrivacyInfo.xcprivacy format, which is validated by Xcode's built-in asset validation during archive.

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | App uses Apple ID / iCloud — not a custom auth system |
| V3 Session Management | No | No app-level session; iCloud handles identity |
| V4 Access Control | Partial | CloudKit public database is read-accessible; `PublicProfile` privacy toggle controls what is public — already implemented |
| V5 Input Validation | Yes | All string inputs validated at ViewModel layer (existing, verified in prior phases) |
| V6 Cryptography | No | CloudKit handles encryption at rest and in transit; no custom crypto |

### Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Privacy manifest missing/incorrect | Tampering (App Review rejection) | Two PrivacyInfo.xcprivacy files with exact reason codes |
| App icon alpha channel in bundle | Tampering (upload rejection) | Strip alpha before archive |
| CloudKit Production schema not deployed | Elevation of Privilege (silent sync failure) | Promote schema before TestFlight upload |
| User data exposed via public CloudKit records | Information Disclosure | `isPublic` flag gate on all records; default private — already implemented |

---

## Sources

### Primary (HIGH confidence)
- [developer.apple.com/documentation/bundleresources/privacy-manifest-files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files) — PrivacyInfo structure and requirement
- [developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk](https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk) — per-target manifest requirement
- [developer.apple.com/forums/thread/742221](https://developer.apple.com/forums/thread/742221) — DTS Engineer: each target with required-reason APIs needs its own manifest
- [developer.apple.com/forums/thread/744454](https://developer.apple.com/forums/thread/744454) — 1C8F.1 reason code and Xcode 15.3 requirement
- [developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications) — 6.9" now primary requirement
- [developer.apple.com/forums/thread/96003](https://developer.apple.com/forums/thread/96003) — App icon alpha channel rejection
- [developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers](https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers) — TestFlight internal tester setup
- [useyourloaf.com/blog/xcode-14-single-size-app-icon](https://useyourloaf.com/blog/xcode-14-single-size-app-icon) — single-size icon catalog verification
- `sips -g pixelWidth -g pixelHeight -g hasAlpha AppIcon.png` — VERIFIED alpha channel present in project's AppIcon.png

### Secondary (MEDIUM confidence)
- [fatbobman.com/en/snippet/why-core-data-or-swiftdata-cloud-sync-stops-working-after-app-store-login](https://fatbobman.com/en/snippet/why-core-data-or-swiftdata-cloud-sync-stops-working-after-app-store-login) — CloudKit schema promotion requirement confirmed
- [swiftylion.com/articles/coredata-cloudkit-not-sync-in-production](https://swiftylion.com/articles/coredata-cloudkit-not-sync-in-production) — CloudKit Console UI navigation steps
- [leojkwan.com/swiftdata-cloudkit-deploy-schema-changes](https://www.leojkwan.com/swiftdata-cloudkit-deploy-schema-changes) — Deploy Schema Changes button location
- [gummicube.com/blog/apple-screenshot-dimensions-have-changed](https://www.gummicube.com/blog/apple-screenshot-dimensions-have-changed) — September 23, 2024 screenshot requirement change
- [mszpro.com/itms-91053-missing-api-declaration](https://mszpro.com/itms-91053-missing-api-declaration-for-accessing-userdefaults-timestamps-other-apis) — UserDefaults reason code descriptions

### Tertiary (LOW confidence — for general context only)
- Apple Developer Forums discussions on CloudKit and App Store Review rejections — general pattern guidance

---

## Metadata

**Confidence breakdown:**
- PrivacyInfo.xcprivacy format: HIGH — directly from Apple official documentation and DTS engineer forum response
- Widget needs separate manifest: HIGH — DTS Engineer explicitly confirmed rule
- Reason codes (CA92.1, 1C8F.1): HIGH — confirmed via Apple forums and multiple cross-references
- CloudKit schema promotion steps: MEDIUM — web UI described from multiple developer sources; exact button labels may differ slightly from current console version
- Screenshot size change (6.9"): HIGH — confirmed via Apple official spec page + independent source with date
- AppIcon alpha channel: HIGH — verified directly against project file with `sips`
- App Review CloudKit graceful degradation: MEDIUM — based on developer forum experience; SwiftData .automatic is more forgiving than direct CloudKit code

**Research date:** 2026-04-27
**Valid until:** 2026-07-27 (90 days — stable APIs; screenshot requirements unlikely to change again soon)
