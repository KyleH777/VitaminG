# Phase 17: Onboarding Overhaul - Pattern Map

**Mapped:** 2026-05-17
**Files analyzed:** 10 new/modified files
**Analogs found:** 10 / 10

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `Views/Onboarding/WelcomeScreen.swift` | view | request-response | `Views/Onboarding/WelcomeScreen.swift` (self) | exact — modify in place |
| `Views/Onboarding/OnboardingView.swift` | router/view | event-driven | `Views/Onboarding/OnboardingView.swift` (self) | exact — modify in place |
| `ViewModels/OnboardingViewModel.swift` | viewmodel | event-driven | `ViewModels/ProfileViewModel.swift` | role-match |
| `Views/Onboarding/LoginScreen.swift` | view | request-response | `Views/Onboarding/LoginScreen.swift` (self) | exact — modify in place |
| `Views/Onboarding/NameScreen.swift` | view | request-response | `Views/Onboarding/NameScreen.swift` (self) | exact — modify in place |
| `Views/ProfileView.swift` | view | CRUD | `Views/GoalListView.swift` (contextMenu) + `Views/ProfileView.swift` (self) | exact — modify in place |
| `Views/Onboarding/TermsAndConditionsScreen.swift` (new) | view | request-response | `Views/Onboarding/NameScreen.swift` | role-match (sandLight light screen) |
| `Views/Onboarding/UsernameScreen.swift` (new) | view | request-response | `Views/Onboarding/NameScreen.swift` | exact (same text-field + StepBarView pattern) |
| `Views/Onboarding/ProfilePictureScreen.swift` (new) | view | file-I/O | `Views/ProfileView.swift` (photosPicker + handlePhotoSelection) | role-match |
| `Views/Onboarding/CameraPermissionScreen.swift` (new) | view | event-driven | `Views/Onboarding/NotificationOnboardingScreen.swift` | exact (dark-clay priming slide pattern) |

---

## Pattern Assignments

### `Views/Onboarding/WelcomeScreen.swift` (modify)

**Analog:** Self — `VitaminG/VitaminG/VitaminG/Views/Onboarding/WelcomeScreen.swift`

**Imports pattern** (lines 1-2):
```swift
import SwiftUI
import AuthenticationServices
```

**Tagline repositioning** — move `Text("GOALS. GROWTH. COMMUNITY.")` from after the app name to before the app icon. Current VStack order (lines 113-162):
```swift
// CENTER VSTACK — CURRENT ORDER:
//   1. "YOUR DAILY DOSE" badge
//   2. RoundedRectangle app icon
//   3. Text("Vitamin G")  ← app name
//   4. Text("GOALS. GROWTH. COMMUNITY.")  ← tagline — MOVE THIS ABOVE #2

// TARGET ORDER:
//   1. "YOUR DAILY DOSE" badge
//   2. Text("GOALS. GROWTH. COMMUNITY.")  ← tagline moved here
//   3. RoundedRectangle app icon
//   4. Text("Vitamin G")
```

Tagline style to preserve (line 155-159):
```swift
Text("GOALS. GROWTH. COMMUNITY.")
    .font(.system(size: 13, weight: .light))
    .foregroundStyle(VGTheme.muted)
    .kerning(2)
    .padding(.top, 10)
// When moving above the icon, replace .padding(.top, 10) with .padding(.bottom, 16)
```

**Button area — remove** (lines 166-238): Remove Button 1 ("Create account"), Button 3 (Google stub), Button 4 ("I'll set this up later"), and `@State private var showGoogleComingSoon`. Keep only the `SignInWithAppleButton` block.

**SignInWithAppleButton pattern to keep** (lines 179-200):
```swift
SignInWithAppleButton(.signIn, onRequest: { request in
    request.requestedScopes = [.fullName, .email]
}, onCompletion: { result in
    switch result {
    case .success(let auth):
        if let cred = auth.credential as? ASAuthorizationAppleIDCredential {
            let uid = cred.user
            appleUserID = uid
            UserDefaults.standard.set(uid, forKey: "vg_appleUserID")
            // NEW: capture fullName for NameScreen pre-fill
            // onboardingVM.appleFullName = cred.fullName
        }
        if !savedName.trimmingCharacters(in: .whitespaces).isEmpty {
            path.append(.login)          // D-03: returning user
        } else {
            path.append(.termsAndConditions)   // D-03: new user
        }
    case .failure:
        break
    }
})
.signInWithAppleButtonStyle(.black)
.frame(maxWidth: .infinity, minHeight: 54)
.clipShape(RoundedRectangle(cornerRadius: 14))
```

**@AppStorage pattern** (lines 49-50):
```swift
@AppStorage("vg_onboardingName") private var savedName: String = ""
@AppStorage("vg_appleUserID") private var appleUserID: String = ""
```

**Remove** the `showGoogleComingSoon` state and its `.alert` modifier (lines 244-248).

---

### `Views/Onboarding/OnboardingView.swift` (modify)

**Analog:** Self — `VitaminG/VitaminG/VitaminG/Views/Onboarding/OnboardingView.swift`

**Current OnboardingStep enum** (lines 6-14):
```swift
enum OnboardingStep: Hashable {
    case name
    case login
    case recovery
    case motivationCategories   // REMOVE
    case notifications
    case communityGoal
    case createGoal             // REMOVE (D-16)
}
```

**Target enum** (add 4 cases, remove 2):
```swift
enum OnboardingStep: Hashable {
    case name
    case login
    case recovery
    case termsAndConditions     // NEW
    case username               // NEW
    case profilePicture         // NEW
    case notifications
    case cameraPermission       // NEW
    case communityGoal
    // .createGoal DELETED per D-16
}
```

**NavigationStack body pattern to extend** (lines 26-46) — add 4 new destination cases, remove 2:
```swift
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
            // ADD:
            case .termsAndConditions:
                TermsAndConditionsScreen(path: $path, onSkip: finish)
            case .username:
                UsernameScreen(path: $path, onSkip: finish)
            case .profilePicture:
                ProfilePictureScreen(path: $path, onSkip: finish)
            case .notifications:
                NotificationOnboardingScreen(path: $path, onSkip: finish)
            // ADD:
            case .cameraPermission:
                CameraPermissionScreen(path: $path, onSkip: finish)
            case .communityGoal:
                CommunityGoalOnboardingScreen(path: $path, onSkip: finish)
            // .motivationCategories and .createGoal cases DELETED
            }
        }
}
```

**`finish()` and `restartOnboarding()` — unchanged** (lines 51-59):
```swift
private func finish() {
    hasCompletedOnboarding = true
    Task { await onboardingVM.completeOnboarding() }
}

private func restartOnboarding() {
    onboardingVM.restartOnboarding()
    path = []
}
```

**`@State private var onboardingVM`** — ViewModel must be passed to new screens that need username/photo state. Pass `onboardingVM` as a parameter to `UsernameScreen` and `ProfilePictureScreen` (same pattern as existing screens that receive `path` and `onSkip`).

---

### `ViewModels/OnboardingViewModel.swift` (modify)

**Analog:** `VitaminG/VitaminG/VitaminG/ViewModels/ProfileViewModel.swift` for the `@Observable @MainActor` pattern and username validation shape.

**Current ViewModel shape** (lines 8-42) — thin, extend it:
```swift
@MainActor
@Observable
final class OnboardingViewModel {
    var hasCreatedFirstGoal: Bool = false
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var savedName: String { ... }
    var isReturningUser: Bool { !savedName.isEmpty }

    func completeOnboarding() async { ... }
    func restartOnboarding() { ... }
}
```

**New properties to add:**

T&C and username @AppStorage:
```swift
// Add as @AppStorage on the view, not on the VM, to match existing patterns.
// The VM holds ephemeral async/session state; @AppStorage is on each screen view.
```

Apple credential passthrough (ephemeral — not persisted):
```swift
var appleFullName: PersonNameComponents? = nil
```

Username check state (new enum + new properties):
```swift
enum UsernameCheckState {
    case idle, checking, available, taken, invalid(String)
}

var usernameInput: String = ""
var usernameCheckState: UsernameCheckState = .idle
private var debounceTask: Task<Void, Never>?
```

Debounce pattern — mirrors Swift Concurrency task cancellation idiom used in the codebase:
```swift
func onUsernameChanged(_ newValue: String) {
    debounceTask?.cancel()
    debounceTask = Task {
        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }
        await checkUsernameAvailability(newValue)
    }
}
```

Photo data (ephemeral session state):
```swift
var profilePhotoData: Data? = nil
```

**Username validation regex** — copy from `ProfileViewModel.swift` (lines 238-247):
```swift
// ProfileViewModel.swift lines 238-247 — copy character-set validation:
let allowed = CharacterSet.lowercaseLetters
    .union(.decimalDigits)
    .union(CharacterSet(charactersIn: "_"))
if draftUsername.unicodeScalars.contains(where: { !allowed.contains($0) }) {
    // invalid
}
```

**@Observable @MainActor** declaration (lines 8-9) — must be preserved exactly as both decorators are required:
```swift
@MainActor
@Observable
final class OnboardingViewModel {
```

---

### `Views/Onboarding/LoginScreen.swift` (modify)

**Analog:** Self — `VitaminG/VitaminG/VitaminG/Views/Onboarding/LoginScreen.swift`

**Import to add:**
```swift
import AuthenticationServices
```

**Existing `bottomButtons` computed property** (lines 122-144) — add `SignInWithAppleButton` above the two existing text links:
```swift
private var bottomButtons: some View {
    VStack(spacing: 0) {
        // ADD: Apple re-auth button (AUTH-07)
        SignInWithAppleButton(.signIn, onRequest: { request in
            request.requestedScopes = [.fullName, .email]
        }, onCompletion: { result in
            switch result {
            case .success:
                onSkip()   // Re-auth success → complete onboarding
            case .failure:
                // Show inline error (add @State var reAuthFailed: Bool = false)
                break
            }
        })
        .signInWithAppleButtonStyle(.black)
        .frame(maxWidth: .infinity, minHeight: 50)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 28)
        .padding(.bottom, 12)

        // Existing links — unchanged:
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
```

---

### `Views/Onboarding/NameScreen.swift` (modify)

**Analog:** Self — `VitaminG/VitaminG/VitaminG/Views/Onboarding/NameScreen.swift`

**onAppear block** (lines 104-107) — extend to accept pre-fill from Apple credential:
```swift
// CURRENT:
.onAppear {
    name = storedName
    fieldFocused = true
}

// TARGET — accept optional pre-fill parameter:
// 1. Add init parameter: let prefilledName: String?
// 2. Extend .onAppear:
.onAppear {
    if storedName.isEmpty, let prefill = prefilledName, !prefill.isEmpty {
        name = prefill
    } else {
        name = storedName
    }
    fieldFocused = true
}
```

**`advanceIfValid()` routing change** (line 114): Change `.motivationCategories` to `.username`:
```swift
// CURRENT:
path.append(.motivationCategories)

// TARGET:
path.append(.username)
```

**StepBarView** (line 34): Update `total:` to match new 7-step flow:
```swift
// CURRENT:
StepBarView(current: 0, total: 4)  // Name is step 0, was 4 steps total

// TARGET (Name is step 1 in new flow: T&C=0, Name=1):
StepBarView(current: 1, total: 7)
```

---

### `Views/ProfileView.swift` (modify — PROF-05)

**Analog:** Self (for camera/photo patterns) + `Views/GoalListView.swift` lines 164-173 for contextMenu pattern.

**contextMenu pattern from GoalListView.swift** (lines 164-172):
```swift
.contextMenu {
    Button(role: .destructive) {
        // action
    } label: {
        Label("Delete", systemImage: "trash")
    }
}
```

**Apply contextMenu to avatar Button** in `heroBanner` (lines 123-145) — add `.contextMenu` modifier to the avatar `Button`:
```swift
Button { requestCameraAndShow() } label: {
    ZStack(alignment: .bottomTrailing) {
        AvatarView(...)
        // camera badge overlay
    }
}
.buttonStyle(.plain)
.accessibilityLabel("Change profile photo")
// ADD (only shown when viewing another user's profile):
.contextMenu {
    Button(role: .destructive) { reportUser() } label: {
        Label("Report User", systemImage: "flag")
    }
    Button(role: .destructive) { showBlockConfirm = true } label: {
        Label("Block User", systemImage: "slash.circle")
    }
}
```

**Block confirmation alert pattern** — matches existing `.alert` pattern in ProfileView (line 80-85) and RecoveryScreen (lines 32-37):
```swift
// From RecoveryScreen.swift lines 32-37:
.alert("Start fresh?", isPresented: $showStartFreshAlert) {
    Button("Start fresh", role: .destructive, action: onRestartOnboarding)
    Button("Cancel", role: .cancel) {}
} message: {
    Text("This clears your local profile data.")
}

// Block confirmation — same shape:
.alert("Block \(reportedUsername)?", isPresented: $showBlockConfirm) {
    Button("Block", role: .destructive) { blockUser() }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("They won't appear in your community feed.")
}
```

**Camera permission denied alert** already in ProfileView (lines 80-85) — copy this exact pattern for any future permission-denied states:
```swift
.alert("Camera Access Denied", isPresented: $cameraPermissionDenied) {
    Button("Open Settings") {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("Please allow camera access in Settings to update your profile photo.")
}
```

**Note on PROF-05 target:** `Views/PublicProfileView.swift` is the correct primary target for Report/Block since ProfileView shows the current user's own data. `PublicProfileView` receives `recordID: String` and shows other users. PROF-05 contextMenu and "Report or Block" button should be added to **both** `ProfileView.swift` (per D-12 literal reading) **and** `PublicProfileView.swift` (per logical fit). `PublicProfileView` already has `AvatarView` and display name `Text` (lines 51-60) as contextMenu targets.

---

### `Views/Onboarding/TermsAndConditionsScreen.swift` (new)

**Analog:** `Views/Onboarding/NameScreen.swift` — same sandLight background, backArrow, StepBarView, bottom CTA button layout.

**File structure to copy:**
```swift
import SwiftUI
import QuickLook     // NEW import for PDFPreviewView

struct TermsAndConditionsScreen: View {
    @Binding var path: [OnboardingStep]
    let onSkip: () -> Void

    @AppStorage("vg_hasAgreedToTerms") private var hasAgreedToTerms: Bool = false
    @State private var showTerms = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VGTheme.sandLight.ignoresSafeArea()    // matches NameScreen background

            VStack(alignment: .leading, spacing: 0) {
                // Nav row — identical to NameScreen lines 22-31:
                HStack {
                    Button(action: { path.removeLast() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(VGTheme.clay)
                    }
                    Spacer()
                }
                .padding(.bottom, 20)

                // Step bar — NameScreen lines 33-35:
                StepBarView(current: 0, total: 7)    // T&C is step 0
                    .padding(.bottom, 28)

                // Headline + body content here
                // "Read Terms" button opens PDFPreviewView sheet
                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)

            // Bottom CTA — identical shape to NameScreen lines 88-101:
            VStack(spacing: 8) {
                Button(action: agree) {
                    Text("I Agree — Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(VGTheme.terra)
                        .foregroundStyle(VGTheme.warmWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 36)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showTerms) {
            PDFPreviewView(url: termsURL!)
                .ignoresSafeArea()
                .presentationDetents([.large])
        }
    }

    private var termsURL: URL? {
        Bundle.main.url(forResource: "Vitamin_G_Terms_and_Conditions", withExtension: "pdf")
    }

    private func agree() {
        hasAgreedToTerms = true
        path.append(.name)
    }
}
```

**PDFPreviewView** — new `UIViewControllerRepresentable` (no codebase analog; use RESEARCH.md pattern exactly):
```swift
import QuickLook

struct PDFPreviewView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(url: url) }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) { self.url = url }
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController,
                               previewItemAt index: Int) -> any QLPreviewItem { url as NSURL }
    }
}
```

Place `PDFPreviewView` in the same file as `TermsAndConditionsScreen.swift` (below it) or in a new `Views/Components/PDFPreviewView.swift`.

---

### `Views/Onboarding/UsernameScreen.swift` (new)

**Analog:** `Views/Onboarding/NameScreen.swift` — closest structural match: sandLight bg, back arrow, StepBarView, large text field, bottom Continue button.

**Imports pattern** — copy from NameScreen and add CloudKit:
```swift
import SwiftUI
import CloudKit    // for username uniqueness check
```

**Screen structure** — copy NameScreen layout, replace TextField with username-specific version:
```swift
struct UsernameScreen: View {
    @Binding var path: [OnboardingStep]
    let onSkip: () -> Void
    var viewModel: OnboardingViewModel    // passed from OnboardingView

    @AppStorage("vg_onboardingUsername") private var storedUsername: String = ""
    @State private var usernameInput: String = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            VGTheme.sandLight.ignoresSafeArea()   // matches NameScreen

            VStack(alignment: .leading, spacing: 0) {
                // Back arrow — copy from NameScreen lines 22-31
                // StepBarView(current: 2, total: 7)  — Username is step 2
                // Headline and subtitle
                // TextField with "@" prefix and inline ✓/✗ feedback below field
                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)

            // Continue button — disabled until .available state:
            VStack(spacing: 8) {
                Button(action: advanceIfAvailable) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(canContinue ? VGTheme.terra : VGTheme.sandMid)
                        .foregroundStyle(canContinue ? VGTheme.warmWhite : VGTheme.sandDeep)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canContinue)   // matches NameScreen line 98
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 36)
        }
        .navigationBarHidden(true)
        .onChange(of: usernameInput) { _, newValue in
            viewModel.onUsernameChanged(newValue)
        }
    }

    private var canContinue: Bool {
        if case .available = viewModel.usernameCheckState { return true }
        return false
    }

    private func advanceIfAvailable() {
        guard canContinue else { return }
        storedUsername = usernameInput
        path.append(.profilePicture)
    }
}
```

**Inline ✓/✗ feedback beneath field** — inline Text below the underline, matching NameScreen's underline separator style:
```swift
// Below the Rectangle underline (copy NameScreen lines 77-80 pattern):
Rectangle()
    .fill(VGTheme.terra)
    .frame(height: 2)

// ADD inline state feedback:
Group {
    switch viewModel.usernameCheckState {
    case .checking:
        ProgressView().scaleEffect(0.7)
    case .available:
        Label("Available", systemImage: "checkmark.circle.fill")
            .foregroundStyle(VGTheme.sage)        // sage = available (per CONTEXT.md)
            .font(.system(size: 12))
    case .taken:
        Label("Already taken", systemImage: "xmark.circle.fill")
            .foregroundStyle(VGTheme.terra)       // terra = taken (per CONTEXT.md)
            .font(.system(size: 12))
    case .invalid(let msg):
        Text(msg).foregroundStyle(VGTheme.terra).font(.system(size: 12))
    case .idle:
        EmptyView()
    }
}
.frame(maxWidth: .infinity, alignment: .leading)
.padding(.top, 8)
```

**Race condition recovery** — inline error, no navigation, field cleared:
```swift
// In advanceIfAvailable(), after claimUsername:
// If post-save re-check fails:
usernameInput = ""
viewModel.usernameCheckState = .idle
// Show inline error via a @State var raceConditionError: String?
// Display below field same as .invalid state label
```

---

### `Views/Onboarding/ProfilePictureScreen.swift` (new)

**Analog:** `Views/ProfileView.swift` (lines 13-15, 76-79) for `PhotosPickerItem` and `.photosPicker` modifier; `Views/Modules/ContactPickerRepresentable.swift` for `UIViewControllerRepresentable` camera picker shape.

**Imports pattern:**
```swift
import SwiftUI
import PhotosUI      // for PhotosPickerItem and .photosPicker modifier
import AVFoundation  // for camera check
```

**PhotosPickerItem state + modifier** — copy from ProfileView (lines 14, 76-79):
```swift
@State private var selectedPhotoItem: PhotosPickerItem? = nil

// Modifier on the view body:
.photosPicker(isPresented: $showLibraryPicker, selection: $selectedPhotoItem, matching: .images)
.onChange(of: selectedPhotoItem) { _, item in
    Task { await handlePhotoSelection(item) }
}
```

**handlePhotoSelection** — copy structure from ProfileViewModel.swift (lines 225-231):
```swift
func handlePhotoSelection(_ item: PhotosPickerItem?) async {
    guard let item else { return }
    guard let data = try? await item.loadTransferable(type: Data.self) else { return }
    let compressed = CommunityService.compressToJPEG(data, maxBytes: 200_000) ?? data
    // Store in viewModel instead of modelContext:
    viewModel.profilePhotoData = compressed
}
```

**CameraPickerView** — `UIViewControllerRepresentable`, copy structure from `ContactPickerRepresentable.swift` (lines 16-54):
```swift
struct CameraPickerView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    // Coordinator pattern — mirrors ContactPickerRepresentable.Coordinator:
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        init(onCapture: @escaping (UIImage) -> Void) { self.onCapture = onCapture }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { onCapture(image) }
            picker.dismiss(animated: true)
        }
    }
}
```

**Screen layout** — lighter sandLight background with StepBarView (step 3 of 7):
```swift
// Bottom buttons — two options + skip, matching CommunityGoalOnboardingScreen lines 138-156:
VStack(spacing: 8) {
    Button("Choose from Library") { showLibraryPicker = true }
        // terra fill button
    Button("Take Photo") { showCameraPicker = true }
        // outlined ghost button
    Button("Skip for now") { path.append(.notifications) }
        // muted text link matching NotificationOnboardingScreen line 107-113
}
```

**AVCaptureDevice camera auth check before showing camera** — copy from ProfileView.swift (lines 490-507):
```swift
// Before setting showCameraPicker = true:
switch AVCaptureDevice.authorizationStatus(for: .video) {
case .authorized:
    showCameraPicker = true
case .notDetermined:
    AVCaptureDevice.requestAccess(for: .video) { granted in
        DispatchQueue.main.async {
            if granted { self.showCameraPicker = true }
            else { self.cameraPermissionDenied = true }
        }
    }
default:
    cameraPermissionDenied = true
}
```

---

### `Views/Onboarding/CameraPermissionScreen.swift` (new)

**Analog:** `Views/Onboarding/NotificationOnboardingScreen.swift` — exact structural mirror. This is the highest-fidelity analog in the codebase.

**Imports pattern** (line 1 of NotificationOnboardingScreen):
```swift
import SwiftUI
import AVFoundation   // ADD for AVCaptureDevice.requestAccess
```

**Full dark-clay layout pattern** — copy entire body structure from NotificationOnboardingScreen:

ZStack with clay + RadialGradient (lines 19-29):
```swift
ZStack {
    VGTheme.clay.ignoresSafeArea()

    RadialGradient(
        colors: [VGTheme.clayMid, VGTheme.clay],
        center: UnitPoint(x: 0.5, y: 0.3),
        startRadius: 0,
        endRadius: 400
    )
    .ignoresSafeArea()

    VStack(spacing: 0) {
        Spacer()
        // Mock preview card (lines 34-76) — replace with camera/photo themed card
        // Headline block (lines 79-93) — "Share your journey"
    }
}
```

**Mock preview card** — copy the card container from NotificationOnboardingScreen (lines 34-76), replace content with camera-themed imagery (e.g., a simulated photo grid).

**Headline block pattern** (lines 79-93):
```swift
VStack(alignment: .leading, spacing: 14) {
    Text("Share your\n\(Text("journey.").font(Font.custom("Georgia-Italic", size: 42)).foregroundStyle(VGTheme.terraSoft))")
        .font(Font.custom("Georgia", size: 42))
        .foregroundStyle(VGTheme.sand)

    Text("Snap progress photos and goal check-ins. Camera access lets you share your story.")
        .font(.system(size: 14, weight: .light))
        .foregroundStyle(VGTheme.muted)
        .lineSpacing(4)
        .fixedSize(horizontal: false, vertical: true)
}
.frame(maxWidth: .infinity, alignment: .leading)
.padding(.horizontal, 28)
.padding(.bottom, 40)
```

**Bottom CTA buttons** — `.safeAreaInset` pattern (lines 95-118):
```swift
.safeAreaInset(edge: .bottom) {
    VStack(spacing: 10) {
        Button(action: allow) {
            Text("Allow Camera")
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(VGTheme.sand)
                .foregroundStyle(VGTheme.clay)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }

        Button(action: skip) {
            Text("Skip for now")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(VGTheme.sand.opacity(0.55))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
    }
    .padding(.horizontal, 28)
    .padding(.bottom, 12)
    .background(VGTheme.clay)
}
.navigationBarHidden(true)
```

**`allow()` action** — AVCaptureDevice pattern from ProfileView.swift (lines 490-507):
```swift
private func allow() {
    AVCaptureDevice.requestAccess(for: .video) { granted in
        DispatchQueue.main.async {
            // granted or not, advance to next step
            path.append(.communityGoal)
        }
    }
}

private func skip() {
    path.append(.communityGoal)
}
```

---

## Shared Patterns

### @AppStorage for onboarding state
**Source:** `Views/Onboarding/WelcomeScreen.swift` (lines 49-50), `Views/Onboarding/NameScreen.swift` (line 12)
**Apply to:** All new onboarding screens

```swift
// Existing keys (read-only by new screens):
@AppStorage("vg_onboardingName") private var storedName: String = ""
@AppStorage("vg_appleUserID") private var appleUserID: String = ""
@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

// New keys for Phase 17:
@AppStorage("vg_hasAgreedToTerms") private var hasAgreedToTerms: Bool = false
@AppStorage("vg_onboardingUsername") private var storedUsername: String = ""
```

### Back arrow nav row
**Source:** `Views/Onboarding/NameScreen.swift` (lines 22-31)
**Apply to:** TermsAndConditionsScreen, UsernameScreen, ProfilePictureScreen (light-background screens)

```swift
HStack {
    Button(action: { path.removeLast() }) {
        Image(systemName: "chevron.left")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(VGTheme.clay)
    }
    Spacer()
}
.padding(.bottom, 20)
```

### StepBarView
**Source:** `Views/Onboarding/NameScreen.swift` (lines 121-134)
**Apply to:** TermsAndConditionsScreen, NameScreen (updated total), UsernameScreen, ProfilePictureScreen, CommunityGoalOnboardingScreen (updated total)

```swift
// Step assignments for new 7-step flow:
// T&C = current:0, Name = current:1, Username = current:2,
// ProfilePicture = current:3, Notifications = current:4,
// Camera = current:5, CommunityGoal = current:6
StepBarView(current: X, total: 7)

// StepBarView definition (NameScreen.swift lines 121-134):
struct StepBarView: View {
    let current: Int
    let total: Int
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i <= current ? VGTheme.terra : VGTheme.sandMid)
                    .frame(height: 3)
            }
        }
    }
}
```

### Primary CTA button style
**Source:** `Views/Onboarding/NameScreen.swift` (lines 89-99)
**Apply to:** All onboarding screens with a primary action

```swift
Button(action: action) {
    Text("Continue")
        .font(.system(size: 17, weight: .semibold))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(isEnabled ? VGTheme.terra : VGTheme.sandMid)
        .foregroundStyle(isEnabled ? VGTheme.warmWhite : VGTheme.sandDeep)
        .clipShape(RoundedRectangle(cornerRadius: 14))
}
.disabled(!isEnabled)
```

### Dark-clay priming slide layout
**Source:** `Views/Onboarding/NotificationOnboardingScreen.swift` (full file)
**Apply to:** CameraPermissionScreen (exact copy, content swapped)

Key: use `.safeAreaInset(edge: .bottom)` for the button tray, not a `ZStack(alignment: .bottom)`. This prevents the keyboard/content overlap that `ZStack` can cause.

### Alert (destructive action confirmation)
**Source:** `Views/Onboarding/RecoveryScreen.swift` (lines 32-37)
**Apply to:** ProfileView block confirmation, UsernameScreen race-condition error (use inline text, not alert)

```swift
.alert("Block \(username)?", isPresented: $showBlockConfirm) {
    Button("Block", role: .destructive) { blockUser() }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("They won't appear in your community feed.")
}
```

### UIViewControllerRepresentable bridge shape
**Source:** `Views/Modules/ContactPickerRepresentable.swift` (lines 16-54)
**Apply to:** CameraPickerView, PDFPreviewView

```swift
// Three-part structure:
// 1. struct conforming to UIViewControllerRepresentable
// 2. makeUIViewController + updateUIViewController
// 3. final class Coordinator: NSObject, <delegate>
```

### CloudKit async/await CKQuery pattern
**Source:** `Services/CommunityService.swift` (lines 24-31), `Services/ProfileSharingService.swift` (full file)
**Apply to:** New `UsernameLookupService` (or extension on `ProfileSharingService`)

```swift
// CommunityService.fetchPosts pattern — copy for username check:
let container = CKContainer(identifier: "iCloud.com.kyleharrington.VitaminG")
let db = container.publicCloudDatabase
let predicate = NSPredicate(format: "username == %@", username.lowercased())
let query = CKQuery(recordType: "PublicProfile", predicate: predicate)
let (results, _) = try await db.records(matching: query, resultsLimit: 1)
// results.isEmpty == username is available

// ProfileSharingService.publishProfile — extend to write username field:
record["username"] = username.lowercased() as CKRecordValue
```

### compressToJPEG helper
**Source:** `Services/CommunityService.swift` (lines 147-160)
**Apply to:** ProfilePictureScreen photo handling; add resize step before compression

```swift
// Existing helper (lines 147-160):
static func compressToJPEG(_ data: Data, maxBytes: Int) -> Data? {
    guard let image = UIImage(data: data) else { return nil }
    var quality: CGFloat = 0.8
    var compressed = image.jpegData(compressionQuality: quality) ?? data
    while compressed.count > maxBytes && quality > 0.1 {
        quality -= 0.1
        compressed = image.jpegData(compressionQuality: quality) ?? compressed
    }
    return compressed
}

// New resize-then-compress helper to add alongside it:
static func resizeAndCompress(_ image: UIImage, maxDimension: CGFloat = 512, quality: CGFloat = 0.75) -> Data? {
    let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)
    let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    let renderer = UIGraphicsImageRenderer(size: newSize)
    let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    return resized.jpegData(compressionQuality: quality)
}
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `PDFPreviewView` (inside TermsAndConditionsScreen.swift) | utility/bridge | request-response | No QuickLook usage in codebase — use RESEARCH.md Area 6 pattern verbatim |
| `UsernameLookupService` (new service file) | service | CRUD | No username lookup exists; CloudKit CKQuery pattern from CommunityService applies but the specific isUsernameTaken + writeUsername + countRecords API shape is new |
| `BlockListService` (new utility) | service | CRUD | No UserDefaults block list in codebase — use RESEARCH.md Area 8 pattern |
| `MailComposeView` or `mailto:` handler | utility/bridge | request-response | No MFMailComposeViewController usage in codebase — use RESEARCH.md Area 7 pattern |

---

## Metadata

**Analog search scope:** `VitaminG/VitaminG/VitaminG/Views/`, `VitaminG/VitaminG/VitaminG/ViewModels/`, `VitaminG/VitaminG/VitaminG/Services/`
**Files scanned:** 14 source files read directly
**Pattern extraction date:** 2026-05-17

### Key Design System Values (VGTheme — from VGTheme.swift lines 6-46)
For quick reference when implementing new screens:
- Background (light screens): `VGTheme.sandLight` (#FAF5EE)
- Background (dark screens): `VGTheme.clay` (#3D2F1E)
- Primary accent / CTA fill: `VGTheme.terra` (#C4673A)
- Available indicator: `VGTheme.sage` (#7A9E7E)
- Error / taken indicator: `VGTheme.terra` (#C4673A)
- Primary text: `VGTheme.clay`
- Secondary text: `VGTheme.muted` (#9A8A78)
- Field underline: `VGTheme.terra` (2px Rectangle)
- Serif font: `Font.custom("Georgia", size: X)`
- Serif italic: `Font.custom("Georgia-Italic", size: X)` (also `VGTheme.serifItalic(X)` helper)
- Navigation: `.navigationBarHidden(true)` on all onboarding screens
