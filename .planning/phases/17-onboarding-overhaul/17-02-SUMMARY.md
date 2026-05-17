---
phase: "17"
plan: "02"
subsystem: onboarding
tags: [auth, t&c, pdf, quicklook, onboarding-step, terms-and-conditions]
dependency_graph:
  requires:
    - "17-01: OnboardingStep enum with .termsAndConditions case and Text placeholder"
  provides:
    - TermsAndConditionsScreen with QuickLook PDF sheet and I Agree button
    - PDFPreviewView UIViewControllerRepresentable wrapping QLPreviewController
    - vg_hasAgreedToTerms AppStorage persistence
    - .termsAndConditions destination wired in OnboardingView navigationDestination switch
  affects:
    - New user onboarding flow: WelcomeScreen → TermsAndConditionsScreen → NameScreen
tech_stack:
  added:
    - QuickLook (QLPreviewController via UIViewControllerRepresentable)
  patterns:
    - UIViewControllerRepresentable bridge with NSObject Coordinator as QLPreviewControllerDataSource
    - if-let guard on Bundle.main.url() — no force-unwrap in production PDF sheet path
    - DEBUG assert on bundle resource presence (onAppear)
key_files:
  created:
    - VitaminG/VitaminG/VitaminG/Views/Onboarding/TermsAndConditionsScreen.swift
  modified:
    - VitaminG/VitaminG/VitaminG/Views/Onboarding/OnboardingView.swift
decisions:
  - "StepBarView(current:0, total:7) — T&C is step 0; total:7 follows PATTERNS.md over UI-SPEC §2 total:6 per plan interface section note"
  - "if-let guard on termsURL enforced per T-17-02-02 mitigation — PDFPreviewView never constructed with nil URL"
  - "Font.custom('Georgia', size:42) used for headline — matches NameScreen analog exactly"
  - "PDFPreviewView defined in same file as TermsAndConditionsScreen (not a separate file) — plan specified same-file placement"
metrics:
  duration: "~8 minutes"
  completed: "2026-05-17T16:15:00Z"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 1
  files_created: 1
---

# Phase 17 Plan 02: T&C Screen Summary

TermsAndConditionsScreen with QuickLook PDF viewer (if-let guard, no force-unwrap) wired as the .termsAndConditions navigationDestination, replacing the Plan 1 placeholder stub.

## What Was Built

**Task 1 (checkpoint:human-action) — SKIPPED**

Pre-condition satisfied: T&C PDF already added to Xcode Copy Bundle Resources per user confirmation. No action required.

**Task 2 — Create TermsAndConditionsScreen.swift (commit 5749b55)**

New file at `VitaminG/VitaminG/VitaminG/Views/Onboarding/TermsAndConditionsScreen.swift` containing two structs:

`TermsAndConditionsScreen`:
- sandLight background with `.ignoresSafeArea()` — matches NameScreen pattern
- Back arrow nav row (chevron.left, 18pt .medium, VGTheme.clay) with `path.removeLast()`
- `StepBarView(current: 0, total: 7)` — T&C is step 0 of the 7-step onboarding flow
- Headline: "Before we begin" (Georgia 42pt, VGTheme.clay, lineSpacing 4)
- Subtitle: "Please read and agree to our Terms & Conditions to continue using Vitamin G." (14pt .light, VGTheme.muted, lineSpacing 4, fixedSize)
- "Read Terms" outlined capsule button (13pt .semibold, VGTheme.clay text, strokeBorder VGTheme.sandMid lineWidth 1)
- Sheet via `if let url = termsURL { PDFPreviewView(url: url).ignoresSafeArea().presentationDetents([.large]) }` — no force-unwrap (T-17-02-02 mitigated)
- `@AppStorage("vg_hasAgreedToTerms") private var hasAgreedToTerms: Bool = false`
- `agree()`: sets hasAgreedToTerms = true, appends `.name` to path
- `DEBUG assert(termsURL != nil, ...)` in `.onAppear` — catches missing bundle resource in development
- `.navigationBarHidden(true)`

`PDFPreviewView: UIViewControllerRepresentable`:
- `let url: URL`
- `makeUIViewController`: creates `QLPreviewController()`, sets `controller.dataSource = context.coordinator`
- `updateUIViewController`: empty
- `makeCoordinator`: returns `Coordinator(url: url)`
- `class Coordinator: NSObject, QLPreviewControllerDataSource` — holds `let url: URL`, `numberOfPreviewItems` returns 1, `previewController(_:previewItemAt:)` returns `url as NSURL`

**Task 3 — Wire .termsAndConditions destination in OnboardingView (commit 1b5bf0e)**

One-line replacement in `OnboardingView.swift`:
- Removed: `Text("T&C — Plan 2")` placeholder (installed by Plan 1)
- Added: `TermsAndConditionsScreen(path: $path, onSkip: finish)`

New user flow is now fully functional through this step: WelcomeScreen → TermsAndConditionsScreen → NameScreen.

## Deviations from Plan

None — plan executed exactly as written.

Task 1 was pre-approved as skipped per the human checkpoint pre-condition in the execution objective.

## Verification Results

Post-task build: **BUILD SUCCEEDED** (zero errors, iPhone 17 Pro simulator)

| Criterion | Result |
|-----------|--------|
| TermsAndConditionsScreen.swift exists | PASS |
| struct TermsAndConditionsScreen: View | PASS |
| struct PDFPreviewView: UIViewControllerRepresentable | PASS |
| QLPreviewController() present | PASS |
| vg_hasAgreedToTerms AppStorage | PASS |
| "I Agree — Continue" copy | PASS |
| "Before we begin" headline copy | PASS |
| path.append(.name) in agree() | PASS |
| presentationDetents([.large]) | PASS |
| No termsURL! force-unwrap (if-let guard used) | PASS |
| OnboardingView has TermsAndConditionsScreen wired | PASS |
| OnboardingView does NOT have Text("T&C — Plan 2") | PASS |
| Build zero errors | PASS |

## Known Stubs

None — the T&C screen is fully functional. The PDF sheet requires `Vitamin_G_Terms_and_Conditions.pdf` in Copy Bundle Resources (pre-condition confirmed by user). The `if-let` guard gracefully handles the absent-PDF case in production without crash.

## Threat Surface

No new network endpoints or trust boundaries beyond the plan's registered threat model.

| Flag | File | Description |
|------|------|-------------|
| T-17-02-02 applied | TermsAndConditionsScreen.swift | if-let guard on Bundle.main.url() prevents nil crash; DEBUG assert surfaces missing resource during development |

## Self-Check: PASSED

- TermsAndConditionsScreen.swift: exists and contains all required content
- OnboardingView.swift: modified, TermsAndConditionsScreen wired, placeholder removed
- 5749b55: confirmed in git log (Task 2)
- 1b5bf0e: confirmed in git log (Task 3)
- Build: SUCCEEDED with zero errors
