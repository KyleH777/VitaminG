---
phase: 19-tip-jar-about-page-settings
plan: "04"
subsystem: about-page-settings
tags: [about, settings, appearance, privacy, support, tip-jar]
dependency_graph:
  requires: ["19-02", "19-03"]
  provides: ["AboutContent", "AboutView", "SettingsView-Appearance", "SettingsView-Privacy", "SettingsView-Support"]
  affects: ["SettingsView", "ProfileView", "VitaminGApp"]
tech_stack:
  added: []
  patterns: ["@AppStorage segmented picker", "safeAreaInset floating footer", "ProfileViewModel privacy toggle", "if-let mailto guard"]
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/AboutContent.swift
    - VitaminG/VitaminG/VitaminG/Views/AboutView.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Views/SettingsView.swift
    - VitaminG/VitaminG/VitaminGTests/AboutContentTests.swift
    - VitaminG/VitaminG/VitaminGTests/SettingsViewTests.swift
decisions:
  - "VGTheme.separator used as divider in AboutView (not Divider()) for theme consistency"
  - "profileVM.toggleProfilePublic delegates isPublic write to existing CloudKit-aware ViewModel method"
  - "SettingsView.supportMailtoURLString extracted as static let so SettingsViewTests can reference it without instantiating the view"
metrics:
  duration: "~20 minutes"
  completed_date: "2026-05-22"
  tasks_completed: 4
  files_changed: 5
---

# Phase 19 Plan 04: About Page + Settings Expansion Summary

**One-liner:** About page with verbatim founder cancer-recovery bio and floating tip footer; Settings gains Appearance (dark-mode picker), Privacy (public profile toggle), and Support (mailto + About nav) sections.

## What Was Built

### AboutContent.swift (new)
- `enum AboutContent` namespace with `static let appName = "Vitamin G"`, `static let founderBio` (verbatim founder bio, D-03), and `static var appVersionString` reading `CFBundleShortVersionString` / `CFBundleVersion` from `Bundle.main`.

### AboutView.swift (new)
- `ScrollView` + `VStack(alignment: .leading, spacing: 24)` with 24pt horizontal padding and `.padding(.bottom, 100)` to prevent the floating footer from occluding the last bio line.
- App name at `VGTheme.serif(34)`, version at 15pt `VGTheme.muted` with accessibility label, `VGTheme.separator` divider, founderBio at 17pt with `.lineSpacing(5)` (no lineLimit — D-03).
- `.background(VGTheme.sandLight.ignoresSafeArea())`, inline nav title "About Vitamin G".
- `.safeAreaInset(edge: .bottom)` floating footer with `NavigationLink(destination: TipJarView())` — "Tip the Developer ☕", full-width, 17pt semibold, `VGTheme.accentTerra` background, `VGTheme.warmWhite` foreground, `RoundedRectangle(cornerRadius: 14)` (D-02: no inline tip button in scroll content).

### SettingsView.swift (modified)
- Added `static let supportMailtoURLString` for the `mailto:VitaminG.info@gmail.com?subject=Vitamin%20G%20Support` URL (T-19-04-01, test reference).
- Added `@AppStorage("vg_colorScheme") private var colorSchemePref: ColorSchemePreference = .system`.
- Added `@Environment(\.modelContext) private var modelContext`.
- Added `@State private var profileVM = ProfileViewModel()`.
- Three new Form sections after Win Reminder footnote:
  1. `Section("Appearance")` — `Picker` over `ColorSchemePreference.allCases` with `.pickerStyle(.segmented)` (SET-04).
  2. `Section("Privacy")` — `Toggle("Public Profile")` bound to `profile.isPublic`, delegates to `profileVM.toggleProfilePublic(context: modelContext)`; disabled placeholder when profile is nil (SET-03, Pitfall 7).
  3. `Section("Support")` — `Button("Contact Support")` with `if let url = URL(string: Self.supportMailtoURLString)` guard (T-19-04-01); `NavigationLink("About Vitamin G") { AboutView() }` (SET-05, D-01).
- `.onAppear` now calls `profileVM.loadOrCreateProfile(context: modelContext)` (Pitfall 7).

### Test Files
- `AboutContentTests.swift`: 3 tests — founderBio non-empty after trim, appVersionString matches `Version X (Y)` regex, appName equals "Vitamin G". All pass.
- `SettingsViewTests.swift`: 1 test — `supportMailtoURLString` produces non-nil URL with scheme `"mailto"`. Passes.

## Requirements Coverage

| Requirement | Status |
|-------------|--------|
| MON-01: About page with verbatim bio | DONE |
| SET-03: Privacy toggle (isPublic) | DONE |
| SET-04: Appearance picker (dark mode) | DONE |
| SET-05: Contact support + About nav | DONE |
| T-19-04-01: No force-unwrap on mailto URL | DONE |

## Deviations from Plan

### Auto-fixed Issues

None. Plan executed as specified with one minor deviation:

**1. [Rule 2 - Enhancement] Used VGTheme.separator for divider**
- **Found during:** Task 3 implementation
- **Issue:** Plan specified `VGTheme.separator` divider; pre-existing untracked stub used `Divider()`
- **Fix:** Replaced `Divider()` with `VGTheme.separator.frame(height: 1)` for theme consistency
- **Files modified:** `Views/AboutView.swift`

### Context Note

`AboutContent.swift` and `AboutView.swift` existed as untracked files (Wave 0 stubs) but had never been committed. Task 2 implemented the correct verbatim bio content and committed both files. Task 3 corrected the divider token and committed the updated `AboutView.swift`.

## Known Stubs

None — all content wired to real data. `founderBio` contains the verbatim developer-provided text. `appVersionString` reads live from `Bundle.main`.

## Threat Flags

No new security surface introduced beyond the plan's threat model.

## Self-Check: PASSED

- [x] `VitaminG/VitaminG/VitaminG/AboutContent.swift` — exists
- [x] `VitaminG/VitaminG/VitaminG/Views/AboutView.swift` — exists
- [x] `VitaminG/VitaminG/VitaminG/Views/SettingsView.swift` — contains all three sections
- [x] `VitaminG/VitaminG/VitaminGTests/AboutContentTests.swift` — 3 tests pass
- [x] `VitaminG/VitaminG/VitaminGTests/SettingsViewTests.swift` — 1 test passes
- [x] Commits: 832e696, fe27139, 0e1b3f9
- [x] Build: SUCCEEDED
