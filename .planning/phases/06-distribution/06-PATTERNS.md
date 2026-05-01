# Phase 06: Distribution - Pattern Map

**Mapped:** 2026-04-27
**Files analyzed:** 3 new/modified files (2 PrivacyInfo.xcprivacy, 1 AppIcon.png fix)
**Analogs found:** 3 / 3

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `VitaminG/VitaminG/VitaminG/PrivacyInfo.xcprivacy` | config (bundle resource) | n/a — static declaration | `VitaminG/VitaminG/VitaminG/VitaminG.entitlements` | role-match (same XML plist format, same per-target bundle resource pattern) |
| `VitaminG/VitaminG/VitaminGWidget/PrivacyInfo.xcprivacy` | config (bundle resource) | n/a — static declaration | `VitaminG/VitaminG/VitaminGWidget/VitaminGWidget.entitlements` | role-match (widget-target XML plist, same structure) |
| `VitaminG/VitaminG/VitaminG/Assets.xcassets/AppIcon.appiconset/AppIcon.png` | asset (modification) | n/a — binary asset fix | n/a — unique asset | no-analog (procedural fix, not a code pattern) |

---

## Pattern Assignments

### `VitaminG/VitaminG/VitaminG/PrivacyInfo.xcprivacy` (config, static declaration)

**Analog:** `VitaminG/VitaminG/VitaminG/VitaminG.entitlements`

**XML envelope pattern** (lines 1-3 of entitlements):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
```
The `PrivacyInfo.xcprivacy` file uses the identical XML plist envelope. Copy this header exactly — the DOCTYPE declaration is required by Apple's validator.

**Target membership pattern — CRITICAL for this project:**

The project uses Xcode's `PBXFileSystemSynchronizedRootGroup` (visible in `project.pbxproj` lines 87-114). In this mode, any file placed inside `VitaminG/VitaminG/VitaminG/` is **automatically included** in the `VitaminG` target's build. There is no need to manually edit `project.pbxproj` to add a `PBXBuildFile` entry or a `PBXResourcesBuildPhase` entry.

Proof from `project.pbxproj` (line 201-203):
```
fileSystemSynchronizedGroups = (
    591E4AE92F8097D500CE6C31 /* VitaminG */,
);
```
The VitaminG target's `fileSystemSynchronizedGroups` points to the folder root. Drop `PrivacyInfo.xcprivacy` into the folder — Xcode picks it up on next open.

**Xcode UI approach (if creating via File > New File):**
When Xcode prompts for target membership, check **only VitaminG** (not VitaminGWidgetExtension, not VitaminGTests). Xcode's "App Privacy" file template creates the correct file type (`com.apple.privacy` UTI).

**Exact file content** (from RESEARCH.md Section 1):
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

**Justification for both reason codes** (from `NotificationPreferences.swift` lines 17-19 and 37-39):
- `CA92.1` — `UserDefaults.standard.integer(forKey: hourKey)` and `UserDefaults.standard.set(...)` in the main app's `NotificationPreferences.save()` method
- `1C8F.1` — `UserDefaults(suiteName: "group.com.kyleharrington.VitaminG")` writes in the same `save()` method; the suite name matches the App Group entitlement in `VitaminG.entitlements` line 6

**Note on Xcode 15.2 UI gap:** The `1C8F.1` reason code does not appear in Xcode's structured privacy editor dropdown in Xcode 15.2. Use "Open As > Source Code" in Xcode's editor to paste the XML directly. Xcode 15.3+ shows all four reason codes.

---

### `VitaminG/VitaminG/VitaminGWidget/PrivacyInfo.xcprivacy` (config, static declaration)

**Analog:** `VitaminG/VitaminG/VitaminGWidget/VitaminGWidget.entitlements`

**XML envelope pattern** (lines 1-3 of widget entitlements):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
```
Identical envelope to the main app. The widget uses the same plist format.

**Target membership pattern:**

From `project.pbxproj` lines 269-271:
```
fileSystemSynchronizedGroups = (
    AA010000000000011 /* VitaminGWidget */,
);
```
The `VitaminGWidgetExtension` target also uses `PBXFileSystemSynchronizedRootGroup`. Drop `PrivacyInfo.xcprivacy` into `VitaminG/VitaminG/VitaminGWidget/` — it is picked up automatically for the widget extension target.

**Exact file content** (widget needs only 1C8F.1, not CA92.1):
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

**Justification for 1C8F.1 only** (from `WidgetNotificationPreferences.swift` lines 22-29):
```swift
static func sharedHour() -> Int {
    let shared = UserDefaults(suiteName: suiteName)
    return shared?.object(forKey: hourKey) as? Int ?? defaultHour
}
```
The widget reads exclusively from `UserDefaults(suiteName: "group.com.kyleharrington.VitaminG")` — App Group suite access only. It never touches `UserDefaults.standard`. Therefore CA92.1 (standard UserDefaults) is not required; only 1C8F.1 (App Group suite UserDefaults) is needed.

**Verification against widget entitlements** (`VitaminGWidget.entitlements` lines 5-7):
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.kyleharrington.VitaminG</string>
</array>
```
The suite name `group.com.kyleharrington.VitaminG` in `WidgetNotificationPreferences.swift` line 12 matches this entitlement exactly. The 1C8F.1 reason code maps to this App Group suite access.

---

### `AppIcon.png` — alpha channel removal (asset modification)

**Analog:** No code analog — this is a binary asset procedural fix.

**Context** (from `Assets.xcassets/AppIcon.appiconset/Contents.json` lines 2-8):
```json
{
  "filename" : "AppIcon.png",
  "idiom" : "universal",
  "platform" : "ios",
  "size" : "1024x1024"
}
```
The asset catalog uses single-size Xcode 14+ universal mode — only `AppIcon.png` at 1024x1024 is needed. Xcode auto-scales all other sizes. Dark and tinted slots (lines 9-27 of Contents.json) have no filename — they are optional and can remain blank.

**Fix command:**
```bash
# Verify current state (will show hasAlpha: yes)
sips -g hasAlpha "/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

# Strip alpha channel (overwrite in place)
sips --setProperty format png \
  --out "/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Assets.xcassets/AppIcon.appiconset/AppIcon.png" \
  "/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

# Verify fix (must show hasAlpha: no before archiving)
sips -g hasAlpha "/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
```

**Blocker:** This must be completed before `Product > Archive` — Xcode Organizer validates the icon during upload and will reject with "The App Store Icon in the asset catalog in 'VitaminG.app' can't be transparent nor contain an Alpha Channel."

---

## Shared Patterns

### Plist XML Envelope
**Source:** Both `VitaminG.entitlements` (lines 1-3) and `VitaminGWidget.entitlements` (lines 1-3)
**Apply to:** Both PrivacyInfo.xcprivacy files

Every Apple property list in this project uses this identical three-line header:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
```
Do not deviate — Apple's validators expect this exact DOCTYPE string.

### File System Synchronized Group — Automatic Target Inclusion
**Source:** `project.pbxproj` lines 87-114 (PBXFileSystemSynchronizedRootGroup section)
**Apply to:** Both PrivacyInfo.xcprivacy files

This project does NOT use the traditional `PBXBuildFile` + `PBXResourcesBuildPhase` pattern. It uses Xcode's newer `PBXFileSystemSynchronizedRootGroup` where the entire folder is automatically synchronized to the target. This means:
- Creating a file inside `VitaminG/VitaminG/VitaminG/` automatically adds it to the VitaminG target
- Creating a file inside `VitaminG/VitaminG/VitaminGWidget/` automatically adds it to the VitaminGWidgetExtension target
- No `project.pbxproj` edits are needed for new files in these directories
- Exception: files listed in `PBXFileSystemSynchronizedBuildFileExceptionSet.membershipExceptions` (currently only `Info.plist` for each target) are excluded from auto-sync

### App Group Suite Name Consistency
**Source:** `VitaminG.entitlements` line 6, `VitaminGWidget.entitlements` line 6, `NotificationPreferences.swift` line 8, `WidgetNotificationPreferences.swift` line 12
**Apply to:** Both PrivacyInfo.xcprivacy files (the 1C8F.1 reason code declaration)

The suite name `group.com.kyleharrington.VitaminG` is the shared App Group identifier. All four files reference it consistently. The PrivacyInfo declarations with 1C8F.1 cover this exact suite access pattern.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| App Store screenshots | asset | n/a | No screenshot tooling or templates in codebase; use Xcode Simulator File > New Screen Shot with iPhone 16 Pro Max |
| App Store metadata (description, keywords) | external | n/a | No App Store Connect metadata files in codebase; written directly in App Store Connect web UI |
| Privacy Policy page | external | n/a | No hosted web page exists; must be created on GitHub Pages or similar before submission |

---

## Xcode Project File — Key Identifiers

For reference if the planner needs to describe project.pbxproj edits (unlikely given synchronized groups):

| Target | PBXNativeTarget UUID | fileSystemSynchronizedGroups UUID | Folder Path |
|---|---|---|---|
| VitaminG (main app) | `591E4AE62F8097D500CE6C31` | `591E4AE92F8097D500CE6C31` | `VitaminG/VitaminG/VitaminG/` |
| VitaminGWidgetExtension | `AA0100000000000E` | `AA010000000000011` | `VitaminG/VitaminG/VitaminGWidget/` |

---

## Metadata

**Analog search scope:** `VitaminG/VitaminG/VitaminG/` (main app), `VitaminG/VitaminG/VitaminGWidget/` (widget), `VitaminG.xcodeproj/project.pbxproj`
**Files scanned:** 6 (VitaminG.entitlements, VitaminGWidget.entitlements, VitaminG/Info.plist, VitaminGWidget/Info.plist, NotificationPreferences.swift, WidgetNotificationPreferences.swift, Contents.json, project.pbxproj)
**Pattern extraction date:** 2026-04-27
