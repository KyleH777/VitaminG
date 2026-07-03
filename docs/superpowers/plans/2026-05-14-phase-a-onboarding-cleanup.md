# Phase A — Onboarding Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the dead phone/OTP signup screens, wire the onboarding flow correctly for new and returning users, and add Login + Recovery screens.

**Architecture:** `OnboardingViewModel` gains three properties (`savedName`, `isReturningUser`, `restartOnboarding()`) via injected `UserDefaults` so the logic is unit-testable. Views read from `@AppStorage` directly for reactive binding; `OnboardingView` passes a `restartOnboarding` closure down to `RecoveryScreen`. `WelcomeScreen` inspects the saved name to decide which path to take.

**Tech Stack:** Swift 5.9, SwiftUI, SwiftData, XCTest, `@AppStorage` / `UserDefaults`

**Spec:** `docs/superpowers/specs/2026-05-14-phase-a-onboarding-cleanup-design.md`

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `VitaminGTests/OnboardingViewModelTests.swift` | Create | Unit tests for new VM properties/methods |
| `VitaminG/ViewModels/OnboardingViewModel.swift` | Modify | Add `defaults` DI, `savedName`, `isReturningUser`, `restartOnboarding()` |
| `VitaminG/Views/Onboarding/OnboardingView.swift` | Modify | Enum: remove phoneSignup/verificationCode, add login/recovery; switch arms; restartOnboarding helper |
| `VitaminG/Views/Onboarding/WelcomeScreen.swift` | Modify | "Get Started" → `.name`; conditional "Sign in" / "I'll set up later" button |
| `VitaminG/Views/Onboarding/LoginScreen.swift` | Create | Welcome-back screen — shows saved name, routes to app or restart |
| `VitaminG/Views/Onboarding/RecoveryScreen.swift` | Create | Recovery options (iCloud restore, start fresh, support) |
| `VitaminG/Views/Onboarding/PhoneSignupScreen.swift` | Delete | Unused — phone/OTP signup |
| `VitaminG/Views/Onboarding/VerificationCodeScreen.swift` | Delete | Unused — OTP entry |

All paths below are relative to the Xcode project root:
`/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/`

---

## Task 1: Write failing tests for OnboardingViewModel additions

**Files:**
- Create: `VitaminGTests/OnboardingViewModelTests.swift`

These tests will not compile yet (the methods don't exist). That is the "failing" state. Do NOT modify the VM in this task.

- [ ] **Step 1.1 — Create the test file**

```swift
// VitaminGTests/OnboardingViewModelTests.swift
import XCTest
@testable import VitaminG

@MainActor
final class OnboardingViewModelTests: XCTestCase {

    private var sut: OnboardingViewModel!
    private var testDefaults: UserDefaults!
    private let suiteName = "com.vitamingapp.onboardingvm.tests"

    override func setUpWithError() throws {
        testDefaults = UserDefaults(suiteName: suiteName)!
        testDefaults.removePersistentDomain(forName: suiteName)
        sut = OnboardingViewModel(defaults: testDefaults)
    }

    override func tearDown() async throws {
        testDefaults.removePersistentDomain(forName: suiteName)
        sut = nil
        testDefaults = nil
    }

    // MARK: savedName

    func test_savedName_whenNameStored_returnsName() {
        testDefaults.set("Maya", forKey: "vg_onboardingName")
        XCTAssertEqual(sut.savedName, "Maya")
    }

    func test_savedName_whenNothingStored_returnsEmpty() {
        XCTAssertEqual(sut.savedName, "")
    }

    func test_savedName_tripsWhitespace() {
        testDefaults.set("  Maya  ", forKey: "vg_onboardingName")
        XCTAssertEqual(sut.savedName, "Maya")
    }

    // MARK: isReturningUser

    func test_isReturningUser_whenNameStored_returnsTrue() {
        testDefaults.set("Maya", forKey: "vg_onboardingName")
        XCTAssertTrue(sut.isReturningUser)
    }

    func test_isReturningUser_whenNoName_returnsFalse() {
        XCTAssertFalse(sut.isReturningUser)
    }

    func test_isReturningUser_whitespaceOnlyName_returnsFalse() {
        testDefaults.set("   ", forKey: "vg_onboardingName")
        XCTAssertFalse(sut.isReturningUser)
    }

    // MARK: restartOnboarding

    func test_restartOnboarding_clearsNameKey() {
        testDefaults.set("Maya", forKey: "vg_onboardingName")
        sut.restartOnboarding()
        XCTAssertNil(testDefaults.string(forKey: "vg_onboardingName"))
    }

    func test_restartOnboarding_clearsCompletedKey() {
        testDefaults.set(true, forKey: "hasCompletedOnboarding")
        sut.restartOnboarding()
        XCTAssertFalse(testDefaults.bool(forKey: "hasCompletedOnboarding"))
    }
}
```

- [ ] **Step 1.2 — Verify compile failure**

Attempt to build the test target. It should fail with errors like:
- `'OnboardingViewModel' has no member 'savedName'`
- `'OnboardingViewModel' has no member 'isReturningUser'`
- `'OnboardingViewModel' initializer has extra argument 'defaults'`

```bash
cd "/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG" && \
xcodebuild build-for-testing -scheme VitaminG \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet 2>&1 | grep "error:" | head -10
```

Expected: compile errors referencing `OnboardingViewModelTests.swift`. Proceed to Task 2.

---

## Task 2: Extend OnboardingViewModel to make tests pass

**Files:**
- Modify: `VitaminG/ViewModels/OnboardingViewModel.swift`

- [ ] **Step 2.1 — Replace the file with the extended version**

Full replacement (the existing file is 18 lines):

```swift
// VitaminG/ViewModels/OnboardingViewModel.swift
import SwiftUI
import UserNotifications
import Observation

// MARK: - OnboardingViewModel

@MainActor
@Observable
final class OnboardingViewModel {

    var hasCreatedFirstGoal: Bool = false

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Returning-user detection

    var savedName: String {
        (defaults.string(forKey: "vg_onboardingName") ?? "")
            .trimmingCharacters(in: .whitespaces)
    }

    var isReturningUser: Bool { !savedName.isEmpty }

    // MARK: - Actions

    func completeOnboarding() async {
        hasCreatedFirstGoal = true
        // Notification permission is handled inline by NotificationOnboardingScreen.
    }

    /// Clears persisted profile and onboarding completion flag.
    /// Call from OnboardingView when the user chooses "Start fresh".
    func restartOnboarding() {
        defaults.removeObject(forKey: "vg_onboardingName")
        defaults.set(false, forKey: "hasCompletedOnboarding")
    }
}
```

- [ ] **Step 2.2 — Run the new tests**

```bash
cd "/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG" && \
xcodebuild test -scheme VitaminG \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:VitaminGTests/OnboardingViewModelTests \
  -quiet 2>&1 | grep -E "error:|Test Suite|passed|failed" | tail -15
```

Expected output ends with:
```
Test Suite 'OnboardingViewModelTests' passed
```

All 8 tests should pass. If any fail, fix the implementation before continuing.

- [ ] **Step 2.3 — Commit**

```bash
cd "/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG" && \
git add VitaminG/ViewModels/OnboardingViewModel.swift \
        VitaminGTests/OnboardingViewModelTests.swift && \
git commit -m "$(cat <<'EOF'
test: add OnboardingViewModelTests; extend VM with savedName, isReturningUser, restartOnboarding

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Update OnboardingStep enum and OnboardingView wiring

**Files:**
- Modify: `VitaminG/Views/Onboarding/OnboardingView.swift`

- [ ] **Step 3.0 — Delete dead files first (prevents compile errors in 3.2)**

Delete from disk:
```bash
rm "/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Views/Onboarding/PhoneSignupScreen.swift"
rm "/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/Views/Onboarding/VerificationCodeScreen.swift"
```

Then open `VitaminG.xcodeproj` in Xcode, select both deleted files in the navigator, and choose **Delete → Remove Reference** so the project file no longer references them. (Or edit `project.pbxproj` directly and remove each file's `PBXFileReference`, `PBXBuildFile`, and group-child entry.)

- [ ] **Step 3.1 — Replace OnboardingView.swift**

```swift
// VitaminG/Views/Onboarding/OnboardingView.swift
import SwiftUI

// MARK: - OnboardingStep

enum OnboardingStep: Hashable {
    case name
    case login
    case recovery
    case motivationCategories
    case notifications
    case communityGoal
    case createGoal
}

// MARK: - OnboardingView

struct OnboardingView: View {

    @State private var path: [OnboardingStep] = []
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var onboardingVM = OnboardingViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeScreen(path: $path, onSkip: finish)
                .navigationDestination(for: OnboardingStep.self) { step in
                    switch step {
                    case .name:
                        NameScreen(path: $path, onSkip: finish)
                    case .login:
                        LoginScreen(path: $path, onSkip: finish)
                    case .recovery:
                        RecoveryScreen(path: $path, onSkip: finish, onRestartOnboarding: restartOnboarding)
                    case .motivationCategories:
                        MotivationCategoryScreen(path: $path, onSkip: finish)
                    case .notifications:
                        NotificationOnboardingScreen(path: $path, onSkip: finish)
                    case .communityGoal:
                        CommunityGoalOnboardingScreen(path: $path, onSkip: finish)
                    case .createGoal:
                        CreateFirstGoalScreen(
                            onboardingVM: onboardingVM,
                            onComplete: finish,
                            onSkipGoal: finish
                        )
                    }
                }
        }
    }

    // MARK: - Actions

    private func finish() {
        hasCompletedOnboarding = true
        Task { await onboardingVM.completeOnboarding() }
    }

    private func restartOnboarding() {
        onboardingVM.restartOnboarding()
        path = []
    }
}
```

- [ ] **Step 3.2 — Verify build succeeds**

```bash
cd "/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG" && \
xcodebuild build -scheme VitaminG \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet 2>&1 | grep "error:" | head -10
```

Expected: no `error:` lines. The dead files were deleted in Step 3.0 so the removed enum cases will not cause compile errors.

- [ ] **Step 3.3 — Commit**

```bash
cd "/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG" && \
git add VitaminG/Views/Onboarding/OnboardingView.swift && \
git commit -m "$(cat <<'EOF'
refactor: remove phoneSignup/verificationCode from OnboardingStep; add login/recovery cases

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Wire WelcomeScreen buttons

**Files:**
- Modify: `VitaminG/Views/Onboarding/WelcomeScreen.swift`

The existing file is 236 lines. Make two targeted changes:

- [ ] **Step 4.1 — Update "Get Started" navigation target**

Find this block (around line 211):
```swift
Button {
    path.append(.phoneSignup)
} label: {
```

Replace with:
```swift
Button {
    path.append(.name)
} label: {
```

- [ ] **Step 4.2 — Add @AppStorage and update the bottom ghost button**

Add this property inside `WelcomeScreen: View`, just after the `@Environment` line:
```swift
@AppStorage("vg_onboardingName") private var savedName: String = ""
```

Find this block (around line 221):
```swift
Button(action: onSkip) {
    Text("I'll set this up later")
        .font(.system(size: 15, weight: .regular))
        .foregroundStyle(VGTheme.sand.opacity(0.55))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
}
```

Replace with:
```swift
Button(action: {
    if !savedName.trimmingCharacters(in: .whitespaces).isEmpty {
        path.append(.login)
    } else {
        onSkip()
    }
}) {
    Text(savedName.trimmingCharacters(in: .whitespaces).isEmpty
         ? "I'll set this up later"
         : "Sign in")
        .font(.system(size: 15, weight: .regular))
        .foregroundStyle(VGTheme.sand.opacity(0.55))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
}
```

- [ ] **Step 4.3 — Build to confirm no errors**

```bash
cd "/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG" && \
xcodebuild build -scheme VitaminG \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet 2>&1 | grep "error:" | head -5
```

Expected: no errors (ignoring errors from still-present PhoneSignupScreen/VerificationCodeScreen).

- [ ] **Step 4.4 — Commit**

```bash
cd "/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG" && \
git add VitaminG/Views/Onboarding/WelcomeScreen.swift && \
git commit -m "$(cat <<'EOF'
feat: wire WelcomeScreen — Get Started goes to Name; Sign In appears for returning users

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Create LoginScreen

**Files:**
- Create: `VitaminG/Views/Onboarding/LoginScreen.swift`

- [ ] **Step 5.1 — Create the file**

```swift
// VitaminG/Views/Onboarding/LoginScreen.swift
import SwiftUI

struct LoginScreen: View {

    @Binding var path: [OnboardingStep]
    let onSkip: () -> Void

    @AppStorage("vg_onboardingName") private var savedName: String = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            VGTheme.sandLight.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                backArrow

                // App icon + welcome chip
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(VGTheme.sand)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text("G")
                                .font(VGTheme.serifItalic(22))
                                .foregroundStyle(VGTheme.clay)
                        )
                        .shadow(color: VGTheme.clay.opacity(0.18), radius: 14, y: 3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("WELCOME BACK")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(VGTheme.muted)
                            .kerning(1.5)
                        Text("Vitamin G")
                            .font(VGTheme.serif(24))
                            .foregroundStyle(VGTheme.clay)
                    }
                }
                .padding(.bottom, 20)

                Text("Good to see\nyou again.")
                    .font(VGTheme.serif(36))
                    .foregroundStyle(VGTheme.clay)
                    .lineSpacing(4)
                    .padding(.bottom, 10)

                Text("Your goals and streaks are right where you left them.")
                    .font(.system(size: 14))
                    .foregroundStyle(VGTheme.muted)
                    .lineSpacing(4)
                    .padding(.bottom, 24)

                profileCard

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)

            bottomButtons
        }
        .navigationBarHidden(true)
        .onAppear {
            if savedName.trimmingCharacters(in: .whitespaces).isEmpty {
                path = [.name]
            }
        }
    }

    // MARK: - Subviews

    private var backArrow: some View {
        HStack {
            Button(action: { path.removeLast() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(VGTheme.clay)
            }
            Spacer()
        }
        .padding(.bottom, 30)
    }

    private var profileCard: some View {
        Button(action: onSkip) {
            HStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [VGTheme.terra, VGTheme.terraSoft],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(savedName.prefix(1)).uppercased())
                            .font(VGTheme.serif(18))
                            .foregroundStyle(VGTheme.warmWhite)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Continue as \(savedName)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(VGTheme.clay)
                    Text("Tap to jump back in")
                        .font(.system(size: 11))
                        .foregroundStyle(VGTheme.muted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(VGTheme.terra)
            }
            .padding(14)
            .background(VGTheme.warmWhite)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: VGTheme.clay.opacity(0.06), radius: 8, y: 1)
        }
    }

    private var bottomButtons: some View {
        VStack(spacing: 0) {
            Button(action: { path.append(.recovery) }) {
                Text("Having trouble?")
                    .font(.system(size: 13))
                    .foregroundStyle(VGTheme.muted)
                    .padding(.vertical, 10)
            }

            Button(action: {
                savedName = ""
                path = [.name]
            }) {
                Text("This isn't me")
                    .font(.system(size: 15))
                    .foregroundStyle(VGTheme.sand.opacity(0.55))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 44)
    }
}
```

- [ ] **Step 5.2 — Build**

```bash
cd "/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG" && \
xcodebuild build -scheme VitaminG \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet 2>&1 | grep "error:" | head -5
```

Expected: no errors from `LoginScreen.swift`.

- [ ] **Step 5.3 — Commit**

```bash
cd "/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG" && \
git add VitaminG/Views/Onboarding/LoginScreen.swift && \
git commit -m "$(cat <<'EOF'
feat: add LoginScreen — profile-aware welcome-back screen with recovery link

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Create RecoveryScreen

**Files:**
- Create: `VitaminG/Views/Onboarding/RecoveryScreen.swift`

- [ ] **Step 6.1 — Create the file**

```swift
// VitaminG/Views/Onboarding/RecoveryScreen.swift
import SwiftUI

struct RecoveryScreen: View {

    @Binding var path: [OnboardingStep]
    let onSkip: () -> Void
    let onRestartOnboarding: () -> Void

    @State private var showStartFreshAlert = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VGTheme.sandLight.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    backArrow
                    headerSection
                    optionsSection
                    reassuranceBanner
                        .padding(.top, 14)
                        .padding(.bottom, 110)
                }
                .padding(.horizontal, 28)
                .padding(.top, 16)
            }

            primaryButton
        }
        .navigationBarHidden(true)
        .alert("Start fresh?", isPresented: $showStartFreshAlert) {
            Button("Start fresh", role: .destructive, action: onRestartOnboarding)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears your local profile data. Your iCloud data is preserved.")
        }
    }

    // MARK: - Subviews

    private var backArrow: some View {
        HStack {
            Button(action: { path.removeLast() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(VGTheme.clay)
            }
            Spacer()
        }
        .padding(.bottom, 20)
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("📱")
                .font(.system(size: 60))
                .frame(maxWidth: .infinity, alignment: .center)

            Text("Let's get you\nback in.")
                .font(VGTheme.serif(32))
                .foregroundStyle(VGTheme.clay)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .lineSpacing(4)

            Text("Your goals and streaks are safe.\nWe just need to verify it's you.")
                .font(.system(size: 14))
                .foregroundStyle(VGTheme.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .lineSpacing(4)
        }
        .padding(.bottom, 30)
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("RECOVERY OPTIONS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(VGTheme.muted)
                .kerning(1.5)
                .padding(.bottom, 10)

            recoveryOptionCard(
                icon: "🔄",
                title: "Restore from iCloud",
                subtitle: "Sync your goals and streak from iCloud backup",
                isHighlighted: true,
                action: onSkip
            )

            recoveryOptionCard(
                icon: "🔑",
                title: "Start fresh",
                subtitle: "Clear everything and start a new profile",
                isHighlighted: false,
                action: { showStartFreshAlert = true }
            )

            recoveryOptionCard(
                icon: "🤝",
                title: "Contact support",
                subtitle: "Real human · usually within 24h",
                isHighlighted: false,
                action: openSupport
            )
        }
    }

    private var reassuranceBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("🛡️").font(.system(size: 18))
            Text("Your streak is protected. Your data lives in iCloud.")
                .font(.system(size: 12))
                .foregroundStyle(VGTheme.clay)
                .lineSpacing(4)
        }
        .padding(14)
        .background(VGTheme.terraLight)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(VGTheme.terraSoft, lineWidth: 1)
        )
    }

    private var primaryButton: some View {
        Button(action: onSkip) {
            Text("Restore from iCloud")
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(VGTheme.terra)
                .foregroundStyle(VGTheme.warmWhite)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 44)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func recoveryOptionCard(
        icon: String,
        title: String,
        subtitle: String,
        isHighlighted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 11)
                    .fill(isHighlighted ? VGTheme.terraLight : VGTheme.sandLight)
                    .frame(width: 42, height: 42)
                    .overlay(Text(icon).font(.system(size: 22)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(VGTheme.clay)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(VGTheme.muted)
                }

                Spacer()

                if isHighlighted {
                    Circle()
                        .fill(VGTheme.terra)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(VGTheme.warmWhite)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(VGTheme.warmWhite)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isHighlighted ? VGTheme.terra : Color.clear, lineWidth: 2)
            )
            .shadow(color: VGTheme.clay.opacity(0.05), radius: 6, y: 1)
        }
        .padding(.bottom, 8)
    }

    private func openSupport() {
        let email = Bundle.main.object(forInfoDictionaryKey: "VGSupportEmail") as? String
                    ?? "support@vitamingapp.com"
        guard let url = URL(string: "mailto:\(email)") else { return }
        UIApplication.shared.open(url)
    }
}
```

- [ ] **Step 6.2 — Build**

```bash
cd "/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG" && \
xcodebuild build -scheme VitaminG \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet 2>&1 | grep "error:" | head -5
```

Expected: no errors from `RecoveryScreen.swift`.

- [ ] **Step 6.3 — Commit**

```bash
cd "/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG" && \
git add VitaminG/Views/Onboarding/RecoveryScreen.swift && \
git commit -m "$(cat <<'EOF'
feat: add RecoveryScreen — iCloud restore, start fresh, and support contact options

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Verify clean build and run full test suite

(Files were deleted in Task 3, Step 3.0)

- [ ] **Step 7.1 — Verify clean build with all tests**

```bash
cd "/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG" && \
xcodebuild test -scheme VitaminG \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet 2>&1 | grep -E "error:|Test Suite 'All tests'|passed|failed" | tail -10
```

Expected:
```
Test Suite 'All tests' passed at ...
```

No `error:` lines. No `failed` test suites.

- [ ] **Step 7.2 — Confirm no dead references**

```bash
grep -r "phoneSignup\|verificationCode\|PhoneSignupScreen\|VerificationCodeScreen" \
  "/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG/VitaminG/" \
  --include="*.swift"
```

Expected: no output.

- [ ] **Step 7.3 — Final commit**

```bash
cd "/Users/kyleharrington/Desktop/AI/Vitamin G/VitaminG/VitaminG" && \
git add -u && \
git commit -m "$(cat <<'EOF'
chore: Phase A complete — onboarding cleanup, login/recovery screens added

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Success Criteria Checklist

- [ ] `OnboardingViewModelTests` — all 8 tests pass
- [ ] All existing tests still pass (no regressions)
- [ ] Zero `error:` lines in build output
- [ ] No Swift files reference `phoneSignup` or `verificationCode`
- [ ] `WelcomeScreen` "Get Started" navigates to `NameScreen`
- [ ] `WelcomeScreen` shows "Sign in" when `vg_onboardingName` is non-empty
- [ ] `LoginScreen` shows saved name in the profile card
- [ ] `LoginScreen` "This isn't me" clears name and navigates to `NameScreen`
- [ ] `RecoveryScreen` "Start fresh" shows confirmation alert before clearing data
- [ ] `RecoveryScreen` "Restore from iCloud" calls `onSkip` (sets `hasCompletedOnboarding = true`)
