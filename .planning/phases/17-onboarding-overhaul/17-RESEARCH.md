# Phase 17: Onboarding Overhaul — Research

**Researched:** 2026-05-16
**Domain:** iOS Auth, CloudKit public DB, PhotosUI, AVFoundation permissions, QuickLook, MFMailCompose, SwiftUI navigation
**Confidence:** HIGH (all findings grounded in direct codebase inspection + authoritative iOS framework knowledge)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- D-01: Apple Sign-In is the only auth CTA on WelcomeScreen. Google stub and "Create account" button removed.
- D-02: Keep raining-tablets animation and clay/sand visual. Move "GOALS. GROWTH. COMMUNITY." tagline above the app icon.
- D-03: After Apple Sign-In: if appleUserID + vg_onboardingName stored → LoginScreen; else → new onboarding.
- D-04: NameScreen stays; pre-fill from Apple credential fullName; user can edit.
- D-05: MotivationCategoryScreen removed from onboarding; CommunityGoalOnboardingScreen kept.
- D-06: New flow order: WelcomeScreen → T&CScreen → NameScreen → UsernameScreen → ProfilePictureScreen → NotificationOnboardingScreen → CameraPermissionScreen → CommunityGoalOnboardingScreen → App.
- D-07: Username uniqueness check fires inline debounced 500ms. Inline ✓/✗ feedback. Continue disabled until confirmed available.
- D-08: T&C PDF (Vitamin_G_Terms_and_Conditions.pdf) bundled in app bundle; opened via QuickLook sheet.
- D-09: Single "I Agree — Continue" primary button. No checkbox.
- D-10: LoginScreen "Continue as [name]" card taps through to app (hasCompletedOnboarding = true path).
- D-11: Sign in with Apple button on LoginScreen for re-auth (credential expired/reinstall). On success completes re-auth.
- D-12: Report/Block on ProfileView only (Phase 22 carries forward).
- D-13: Entry points: (1) long-press contextMenu on avatar + display name; (2) explicit "Report or Block" button.
- D-14: Report opens MFMailComposeViewController (or mailto: fallback). Subject: `[Vitamin G] Report User: @{username}`. Body pre-populated with reporter context.
- D-15: Block stores Apple User ID in Set<String> in UserDefaults key `vg_blockedUserIDs`. Confirmation alert shown. Feed filtered client-side.

### Claude's Discretion
- Whether GoalCreationWizardView(isOnboarding: true) remains as the final onboarding step or is removed.
- Exact visual layout of T&C screen.
- StepBarView total: count update.
- Whether to use MFMailComposeViewController or mailto: URL for Report action.

### Deferred Ideas (OUT OF SCOPE)
- Block list management in Settings.
- CloudKit-backed block list sync.
- Report reason picker before email.
- GoalCreationWizardView onboarding integration (Phase 18 redesigns wizard; planner decides).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUTH-01 | Apple Sign-In only — Google removed | WelcomeScreen already has SignInWithAppleButton wired; remove 3 other buttons |
| AUTH-02 | T&C PDF linked and readable inline; user must acknowledge | QuickLook via sheet; QLPreviewController wrapped in UIViewControllerRepresentable |
| AUTH-03 | Unique username via async CKQuery before write; race condition handled | `db.records(matching:)` async/await API; first-write-wins + post-save verification |
| AUTH-04 | Profile picture upload (PHPicker + UIImagePicker); skippable; ≤512px / JPEG 0.75 | PHPickerViewController for library; UIImagePickerController for camera; existing compressToJPEG helper |
| AUTH-05 | Notification permission priming slide | NotificationOnboardingScreen pattern; already in codebase and in flow |
| AUTH-06 | Camera permission priming slide in onboarding | AVCaptureDevice.requestAccess(for: .video); mirror NotificationOnboardingScreen |
| AUTH-07 | Welcome Back screen with Sign in with Apple button for re-auth | LoginScreen already exists; add SignInWithAppleButton; wire ASAuthorizationController |
| PROF-05 | Report and Block on every public profile; App Store Guideline 1.2 | .contextMenu on avatar + display name; MFMailCompose/mailto: for report; UserDefaults Set for block |
</phase_requirements>

---

## Summary

Phase 17 is a surgical rework of the existing onboarding NavigationStack: four new screens (T&C, Username, ProfilePicture, CameraPermission) are added as new `OnboardingStep` enum cases, one case (`.motivationCategories`) is removed, and the routing logic in WelcomeScreen is updated to detect returning users. The codebase is well-positioned — `ProfileSharingService` and `CommunityService` already demonstrate the async/await CloudKit pattern the username uniqueness check will reuse, `PhotosPickerItem` is already in `ProfileViewModel`, and `AVCaptureDevice.requestAccess` is already called in `ProfileView`. No new third-party dependencies are required.

The highest-risk item is the username race condition (AUTH-03): CloudKit's public database has no atomic uniqueness enforcement, so a check-then-write is inherently racy. The mitigation is a post-save verification re-query, which must be implemented even though it adds a second CloudKit round trip. The second risk is QuickLook PDF presentation from SwiftUI, which requires `UIViewControllerRepresentable` wrapping since SwiftUI has no native `QLPreviewController` equivalent on iOS 17.

**Primary recommendation:** Implement in the order listed in the Recommended Implementation Order section — auth gate first, then each new screen in flow order, then the CloudKit uniqueness service as a standalone testable unit, then Report/Block last since it touches a different view hierarchy.

---

## Technical Findings

### Area 1: OnboardingStep Enum — Diff and Routing

**Current state (from OnboardingView.swift):**
```swift
enum OnboardingStep: Hashable {
    case name
    case login
    case recovery
    case motivationCategories   // REMOVE
    case notifications
    case communityGoal
    case createGoal
}
```

**Target state for Phase 17:**
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
    case createGoal             // planner decides whether to keep
}
```

**NavigationStack routing pattern (already established):**
The root of `NavigationStack(path: $path)` is `WelcomeScreen`. All navigation is path-append: `path.append(.termsAndConditions)`. The `navigationDestination(for: OnboardingStep.self)` switch in `OnboardingView` is the single dispatch point — add new cases there. [VERIFIED: direct codebase read]

**New step flow path appends:**
- WelcomeScreen → `.termsAndConditions` (after Apple Sign-In for new user)
- T&CScreen → `.name` (after "I Agree")
- NameScreen → `.username` (replaces existing `.motivationCategories` append in `advanceIfValid()`)
- UsernameScreen → `.profilePicture`
- ProfilePictureScreen → `.notifications` (or skip to `.notifications`)
- NotificationOnboardingScreen → `.cameraPermission`
- CameraPermissionScreen → `.communityGoal`
- CommunityGoalOnboardingScreen → `finish()` (sets `hasCompletedOnboarding = true`)

**StepBarView update:** Current `NameScreen` hardcodes `StepBarView(current: 0, total: 4)`. With 6 user-facing steps (T&C, Name, Username, ProfilePic, Notifications/Camera, CommunityGoal), `total: 6` is the minimum. The planner should assign step indices per screen: T&C=0, Name=1, Username=2, ProfilePic=3, Notifications=4, CameraPermission=4 or 5, CommunityGoal=5. [ASSUMED — final count subject to planner decision on createGoal]

**Returning user routing (D-03) in WelcomeScreen onCompletion:**
```swift
// In the onCompletion handler for SignInWithAppleButton:
if !savedName.trimmingCharacters(in: .whitespaces).isEmpty {
    // Returning user: has name stored → LoginScreen
    path.append(.login)
} else {
    // New user: no name stored → new onboarding
    path.append(.termsAndConditions)
}
```
The current code already does this branch (`onSkip()` vs `path.append(.name)`). The change is: replace `onSkip()` with `path.append(.login)` and replace `path.append(.name)` with `path.append(.termsAndConditions)`. [VERIFIED: direct codebase read]

---

### Area 2: CloudKit Username Uniqueness (AUTH-03)

**Established CloudKit pattern in codebase:**
`CommunityService.fetchPosts` and `ProfileSharingService` already use `db.records(matching: query, resultsLimit:)` with async/await. The username uniqueness check follows the same pattern. [VERIFIED: direct codebase read]

**Recommended query approach (iOS 17+):**
```swift
// UsernameLookupService.swift
import CloudKit

enum UsernameLookupService {
    private static let containerID = "iCloud.com.kyleharrington.VitaminG"
    static let recordType = "PublicProfile"  // same record type used by ProfileSharingService

    /// Returns true if the username is already claimed.
    static func isUsernameTaken(_ username: String) async throws -> Bool {
        let db = CKContainer(identifier: containerID).publicCloudDatabase
        let predicate = NSPredicate(format: "username == %@", username.lowercased())
        let query = CKQuery(recordType: recordType, predicate: predicate)
        let (results, _) = try await db.records(matching: query, resultsLimit: 1)
        return !results.isEmpty
    }
}
```

**Critical prerequisite:** The `PublicProfile` CloudKit record type in the **public database** must have a `username` field (String, queryable). Currently `ProfileSharingService.publishProfile` only writes `displayName` and `avatarColorHex`. Phase 17 must extend it to also write `username` when the user claims one during onboarding. The field must be **indexed** (queryable) in CloudKit Console for predicate queries to work — this is a CloudKit Console schema step, not a code step. [ASSUMED — CloudKit Console state not inspectable from code; planner must include a CloudKit Console task]

**Race condition — first-write-wins pattern (AUTH-03):**
CloudKit has no atomic uniqueness enforcement (confirmed by CLAUDE.md: "Do not use `@Attribute(.unique)` — CloudKit does not support atomic uniqueness checks"). The mitigation:

1. Debounced availability check (500ms after user stops typing) → show ✓/✗
2. User taps Continue → immediately write the username to `PublicProfile`
3. After save returns → re-query to confirm this device's record is the sole holder
4. If re-query finds a different record with same username → show displacement alert: "That username was just claimed. Please choose another."

```swift
// In OnboardingViewModel — post-save verification
func claimUsername(_ username: String) async throws -> Bool {
    // Step 1: Write
    try await UsernameLookupService.writeUsername(username, recordID: appleUserID)
    // Step 2: Verify sole ownership
    let count = try await UsernameLookupService.countRecords(forUsername: username)
    return count == 1  // false = displaced
}
```

**Debounce pattern in OnboardingViewModel:**
```swift
// In OnboardingViewModel (@Observable, @MainActor)
var usernameInput: String = ""
var usernameState: UsernameCheckState = .idle
private var debounceTask: Task<Void, Never>?

enum UsernameCheckState { case idle, checking, available, taken, invalid }

func onUsernameChanged(_ newValue: String) {
    debounceTask?.cancel()
    debounceTask = Task {
        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }
        await checkUsernameAvailability(newValue)
    }
}
```
[ASSUMED — specific field names subject to planner preference; pattern is established Swift concurrency]

**CloudKit field index requirement:** For `NSPredicate(format: "username == %@", ...)` to work, `username` must be listed under "Queryable" fields in CloudKit Dashboard > Public Database > Indexes for `PublicProfile`. If not indexed, the query will return a `CKError.invalidArguments` with a message about missing index. [ASSUMED — cannot verify CloudKit Console state from code]

---

### Area 3: PHPickerViewController + UIImagePickerController (AUTH-04)

**ProfileViewModel already has the pattern:**
`handlePhotoSelection(_ item: PhotosPickerItem?, context:)` exists and calls `CommunityService.compressToJPEG`. The codebase already imports `PhotosUI` and uses `PhotosPickerItem`. [VERIFIED: direct codebase read — ProfileViewModel.swift]

**ProfileView already uses `.photosPicker(isPresented:selection:matching:)` modifier** — the SwiftUI-native wrapper around PHPickerViewController. This is the correct approach for the library picker; no custom `UIViewControllerRepresentable` is needed for photo library access. [VERIFIED: direct codebase read — ProfileView.swift]

**For camera capture:** UIImagePickerController is the correct UIKit camera picker. It requires `UIViewControllerRepresentable`. No SwiftUI-native camera picker exists on iOS 17. The `NSCameraUsageDescription` key must be in Info.plist (already likely present given Phase 15 added camera support to ProfileView). [ASSUMED — Info.plist contents not read; planner must verify]

**UIViewControllerRepresentable wrapper for camera:**
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

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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

**Image compression to ≤512px / JPEG 0.75 (AUTH-04):**
`CommunityService.compressToJPEG` iterates quality down from 0.8 until under `maxBytes`. For the profile picture requirement (≤512px dimension AND JPEG 0.75), add a resize step before JPEG compression:

```swift
static func resizeAndCompress(_ image: UIImage, maxDimension: CGFloat = 512, quality: CGFloat = 0.75) -> Data? {
    let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)
    let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    let renderer = UIGraphicsImageRenderer(size: newSize)
    let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    return resized.jpegData(compressionQuality: quality)
}
```
Add this as a static method on `CommunityService` or a new `ImageProcessor` utility. [ASSUMED — exact utility placement subject to planner preference]

**ProfilePictureScreen dual-source picker pattern:**
```swift
// In ProfilePictureScreen — two buttons:
Button("Choose from Library") { showLibraryPicker = true }
Button("Take Photo") { showCameraPicker = true }
// Then:
.photosPicker(isPresented: $showLibraryPicker, selection: $selectedItem, matching: .images)
.sheet(isPresented: $showCameraPicker) { CameraPickerView(onCapture: handleCapture) }
```

---

### Area 4: AVCaptureDevice Permission Priming (AUTH-06)

**Existing pattern in ProfileView.swift (requestCameraAndShow):**
```swift
AVCaptureDevice.requestAccess(for: .video) { granted in
    DispatchQueue.main.async {
        if granted { self.showingPhotoPicker = true }
        else { self.cameraPermissionDenied = true }
    }
}
```
This is the exact pattern to call from `CameraPermissionScreen`'s "Allow Camera" button. [VERIFIED: direct codebase read — ProfileView.swift]

**CameraPermissionScreen design spec (from CONTEXT.md specifics):**
Mirror `NotificationOnboardingScreen` exactly: dark clay background, RadialGradient, mock preview card, primary CTA + "Skip for now" secondary. Headline: "Share your journey". Body: explains profile picture and goal photo use. Primary CTA: "Allow Camera". Secondary: "Skip for now".

**Permission timing:** The system alert fires on `AVCaptureDevice.requestAccess(for: .video)` the first time only. If the user previously denied, `authorizationStatus` returns `.denied` and the system alert does not re-appear — the priming screen's CTA should detect denied state and route to Settings instead. This is the same logic already in ProfileView. [VERIFIED: direct codebase read]

**Info.plist key required:** `NSCameraUsageDescription` — string explaining camera use. Must already exist from Phase 15 camera work in ProfileView. Planner should verify it exists; if not, add it. [ASSUMED — cannot verify Info.plist without reading it]

---

### Area 5: AuthenticationServices Re-auth on LoginScreen (AUTH-07, D-11)

**Current LoginScreen state:** Has "Continue as [name]" profileCard (calls `onSkip()` → sets `hasCompletedOnboarding = true`), "Having trouble?" link, and "This isn't me" link. No Apple Sign-In button. [VERIFIED: direct codebase read — LoginScreen.swift]

**What to add:** `SignInWithAppleButton(.signIn, onRequest:, onCompletion:)` — the same component already in WelcomeScreen. Import is already `AuthenticationServices`. The onCompletion handler on success calls `onSkip()` (which sets `hasCompletedOnboarding = true`). On failure, show an inline error message.

**Credential state check (optional but recommended):** Before presenting LoginScreen, the app can verify `ASAuthorizationAppleIDProvider().credentialState(forUserID: appleUserID)` to distinguish `.authorized`, `.revoked`, `.notFound`. This is an async check. If `.authorized`, the profile card tap alone suffices; the Apple button is shown as a fallback for `.revoked`/`.notFound`. [ASSUMED — whether to add this check is a planner decision; the simpler approach is to always show the button]

**ASAuthorizationController from SwiftUI:** On iOS 17, you cannot call `ASAuthorizationController.performRequests()` programmatically from a pure SwiftUI context without UIKit scaffolding — but `SignInWithAppleButton` handles this internally. Just use `SignInWithAppleButton` directly as already done in WelcomeScreen. No need for `ASAuthorizationController` manual presentation. [ASSUMED — based on training knowledge; Apple's SwiftUI button wraps the controller]

---

### Area 6: QuickLook PDF Presentation (AUTH-02)

**No existing QuickLook usage in the codebase.** This is the only new UIKit bridge in the phase.

**SwiftUI-native approach (iOS 16+):** SwiftUI does not have a native `QLPreviewController` view. The correct approach is `UIViewControllerRepresentable` wrapping `QLPreviewController`.

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

**Bundle URL for the PDF:**
```swift
// In TermsAndConditionsScreen:
if let url = Bundle.main.url(forResource: "Vitamin_G_Terms_and_Conditions", withExtension: "pdf") {
    showTerms = true  // sheet presents PDFPreviewView(url: url)
}
```

**Adding the PDF to the Xcode project:**
1. Drag `Vitamin_G_Terms_and_Conditions.pdf` into the Xcode project navigator.
2. In the "Add Files" sheet, check "Copy items if needed" and check the VitaminG app target under "Add to targets".
3. Verify in Build Phases → Copy Bundle Resources that the PDF appears.
4. `Bundle.main.url(forResource:withExtension:)` will return non-nil if step 3 is correct.

**Sheet presentation in SwiftUI:**
```swift
.sheet(isPresented: $showTerms) {
    PDFPreviewView(url: termsURL)
        .ignoresSafeArea()
}
```

**Pitfall:** `QLPreviewController` inside a SwiftUI sheet has known sizing issues on some iOS versions — pass `.ignoresSafeArea()` to the sheet content and set the sheet's `presentationDetents` to `[.large]` to avoid content clipping. [ASSUMED — based on training knowledge of known QLPreviewController + SwiftUI sheet quirks]

---

### Area 7: MFMailComposeViewController + mailto: Fallback (PROF-05, D-14)

**No existing MFMailCompose usage in the codebase.** New pattern.

**canSendMail() check is mandatory:** `MFMailComposeViewController.canSendMail()` returns false on simulators and devices without a Mail account configured. Always check before presenting.

**SwiftUI wrapper:**
```swift
import MessageUI

struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let body: String
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients(["support@vitamingapp.com"])  // planner fills in real address
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onDismiss: onDismiss) }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onDismiss: () -> Void
        init(onDismiss: @escaping () -> Void) { self.onDismiss = onDismiss }
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true, completion: onDismiss)
        }
    }
}
```

**mailto: fallback (for devices without Mail):**
```swift
func openReportEmail(subject: String, body: String) {
    if MFMailComposeViewController.canSendMail() {
        showMailCompose = true
    } else {
        // URL-encode subject and body for mailto:
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:support@vitamingapp.com?subject=\(encodedSubject)&body=\(encodedBody)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}
```

**Report email body template (D-14):**
```
Reporter Apple ID: [vg_appleUserID stored value]
Reported username: @[username]
Timestamp: [ISO8601 date]

---
[Additional context from reporter]
```

**Claude's discretion note (from CONTEXT.md):** The planner may choose `mailto:` URL exclusively if MFMailComposeViewController complexity is not warranted. The `mailto:` approach works on all devices where any email client is installed; Mail.app is no longer the only option on iOS 14+. If the planner chooses mailto:-only, skip the UIViewControllerRepresentable wrapper entirely. [ASSUMED — this is a planner decision per CONTEXT.md "Claude's Discretion"]

---

### Area 8: UserDefaults Block List (PROF-05, D-15)

**Key:** `vg_blockedUserIDs`
**Type:** `Set<String>` stored as JSON-encoded `[String]` (UserDefaults cannot natively store `Set`)
**Scope:** Standard `UserDefaults.standard` — no app group needed (block list is not widget-relevant per CONTEXT.md)

**Read/write pattern:**
```swift
// Read
func blockedUserIDs() -> Set<String> {
    guard let data = UserDefaults.standard.data(forKey: "vg_blockedUserIDs"),
          let array = try? JSONDecoder().decode([String].self, from: data) else { return [] }
    return Set(array)
}

// Write
func blockUser(appleUserID: String) {
    var ids = blockedUserIDs()
    ids.insert(appleUserID)
    if let data = try? JSONEncoder().encode(Array(ids)) {
        UserDefaults.standard.set(data, forKey: "vg_blockedUserIDs")
    }
}
```

**Community feed filtering:** The filter runs at the SwiftUI `ForEach` level (or in the ViewModel fetch) by checking `blockedUserIDs().contains(post.authorAppleUserID)`. This requires community posts to expose the author's Apple User ID. Currently `CommunityPost` records store `authorDisplayName` and `authorColorHex` — **they do not store the author's Apple User ID**. This is a data schema gap for Phase 17.

For Phase 17 scope (ProfileView only), the block list stores Apple User IDs from the ProfileView context where the viewed user's Apple User ID is known. Community feed filtering is future work per D-15 ("Community feed filters out blocked users client-side" — requires Apple User ID on CommunityPost records, which is a Phase 21 concern). [VERIFIED: direct codebase read — CommunityService.swift confirms CommunityPost fields]

**Confirmation alert (D-15):**
```swift
.alert("Block \(username)?", isPresented: $showBlockConfirm) {
    Button("Block", role: .destructive) { blockUser() }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("They won't appear in your community feed.")
}
```

---

### Area 9: Report/Block Context Menu on ProfileView (PROF-05, D-13)

**ProfileView heroBanner — target elements:**
1. The `Button { requestCameraAndShow() }` that wraps `AvatarView` — add `.contextMenu` here but guard it: the context menu should only show when viewing *another user's* profile, not your own. Phase 17 adds it to the existing v1.0 ProfileView where it is always the user's own profile. Per D-12, Phase 22 carries the pattern to the public profile redesign.

Since Phase 17 is adding Report/Block to `ProfileView` (the user's own profile), these actions apply to *other users viewed from this profile* — however, looking at the actual ProfileView, it only shows the current user's own data. The more logical read of D-12 is that the planner adds Report/Block to a secondary screen (public profile view) in Phase 17 scope, not to the self-profile. Re-reading D-12: "Report/Block added to ProfileView only (the existing v1.0 profile screen)."

**Resolution:** The existing `ProfileView.swift` shows the *current user's own* profile. There is also likely a `PublicProfileView` or similar for viewing other users. The planner must identify which view is the target. The `.contextMenu` modifiers should be on elements that represent another user. If Phase 17's ProfileView is purely self-view, the explicit "Report or Block" button and context menu on avatar/display name text only make sense when the user is viewing another profile. Planner clarification needed.

**Context menu syntax (iOS 17):**
```swift
Circle()  // avatar
    .contextMenu {
        Button(role: .destructive) { reportUser() } label: {
            Label("Report User", systemImage: "flag")
        }
        Button(role: .destructive) { showBlockConfirm = true } label: {
            Label("Block User", systemImage: "slash.circle")
        }
    }
```
`.contextMenu` requires a long press to activate on iOS 17. The behavior is the same on both `Circle` and `Text` targets. [ASSUMED — based on training knowledge of SwiftUI contextMenu behavior on iOS 17]

**Finding PublicProfileView:** The codebase has a deep link parser for `vitaming://profile/<recordID>` (DeepLinkParser in VitaminGApp). There must be a `PublicProfileView` receiving that route. Planner should locate it — this is the more natural home for Report/Block. If no such view exists, the planner creates one or adds the actions to whatever view renders other users.

---

### Area 10: OnboardingViewModel Extensions

**Current state:** Thin — only tracks `hasCreatedFirstGoal` and reads `savedName`/`isReturningUser`. [VERIFIED: direct codebase read]

**Extensions needed for Phase 17:**
```swift
// New @AppStorage-style state (add to OnboardingViewModel or as @AppStorage in each screen):
@AppStorage("vg_hasAgreedToTerms") var hasAgreedToTerms: Bool = false
@AppStorage("vg_onboardingUsername") var onboardingUsername: String = ""

// New async state for username check:
var usernameCheckState: UsernameCheckState = .idle
private var debounceTask: Task<Void, Never>?

// New photo state:
var profilePhotoData: Data? = nil

// Apple credential passthrough:
var appleFullName: PersonNameComponents? = nil  // set in WelcomeScreen onCompletion, read by NameScreen
```

**Apple credential passthrough for name pre-fill (D-04):**
`ASAuthorizationAppleIDCredential.fullName` is a `PersonNameComponents?`. It is only provided on the *first* sign-in; subsequent sign-ins return nil. The display name field in NameScreen should pre-fill with `"\(fullName.givenName ?? "") \(fullName.familyName ?? "")".trimmingCharacters(in: .whitespaces)` if non-empty. This value is ephemeral — it must be passed from WelcomeScreen's onCompletion handler to the ViewModel before navigating, not stored to UserDefaults (the user will confirm it by tapping Continue). [ASSUMED — behavior of ASAuthorizationAppleIDCredential.fullName returning nil on repeat sign-ins is documented Apple behavior]

---

### Area 11: T&C PDF Bundling

**Xcode project bundle inclusion steps:**
1. PDF file added to project: File → Add Files → check "Copy items if needed" → check VitaminG app target.
2. Build Phases → Copy Bundle Resources: verify `Vitamin_G_Terms_and_Conditions.pdf` appears.
3. Verify at runtime: `Bundle.main.url(forResource: "Vitamin_G_Terms_and_Conditions", withExtension: "pdf") != nil`.

**Pitfall — file name with spaces or special characters:** The `forResource:` parameter must match the filename exactly (case-sensitive on simulator, case-insensitive on device; treat as case-sensitive). The filename `Vitamin_G_Terms_and_Conditions.pdf` uses underscores — the `forResource:` call must use the same exact name without extension. [ASSUMED — standard iOS bundle behavior]

**App size impact:** A T&C PDF is typically 50–200 KB. Negligible. No concern.

---

## Validation Architecture

Questions the planner must wire verification tasks for:

1. **Username uniqueness — does the CloudKit index exist?** Query `CKQuery(recordType: "PublicProfile", predicate: NSPredicate(format: "username == %@", "testuser"))` in a real device build. If it throws `CKError.invalidArguments` mentioning a missing index, the CloudKit Console step was missed.

2. **Does the debounce actually fire at 500ms?** Use `Task.sleep(for: .milliseconds(500))` cancellation semantics — verify in a debug build that rapid typing cancels previous checks (add a `print("check fired for: \(username)")` during development, remove before PR).

3. **Does the block list persist across app kills?** UserDefaults is flushed to disk by the OS asynchronously. Call `UserDefaults.standard.synchronize()` after writing (deprecated but still functional) or rely on the OS flush — test by killing the app immediately after blocking and relaunching.

4. **Does QuickLook open the PDF without a crash?** `Bundle.main.url(forResource:withExtension:)` returns nil if the PDF is not in Copy Bundle Resources — this produces a silent nil and the sheet never opens. Add an `assert(termsURL != nil, "T&C PDF not found in bundle")` in DEBUG builds.

5. **Does the returning-user routing work after reinstall?** After a fresh install, `vg_appleUserID` is in Keychain (if stored there) or absent (if only UserDefaults). The current WelcomeScreen stores to both `@AppStorage("vg_appleUserID")` and `UserDefaults.standard.set(uid, forKey: "vg_appleUserID")`. After reinstall, UserDefaults is wiped — if AppleUserID is not in Keychain, reinstall will always route new users through full onboarding. Verify this is the intended behavior (it is, per D-03 which checks `savedName` not `appleUserID`).

6. **Does MFMailCompose present correctly on a real device?** The simulator returns `canSendMail() == false`. Test the `mailto:` fallback on simulator; test MFMailCompose on a device with Mail configured.

7. **Does the camera permission priming show before the system alert?** Verify `AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined` on first run. If `.authorized` (from ProfileView camera in v1.0), the priming screen is still shown but the system alert will not fire — the permission is already granted.

---

## Implementation Risk Areas

### Risk 1: CloudKit public DB schema not ready for username queries
**Details:** `UsernameLookupService.isUsernameTaken` queries on `username` field of `PublicProfile`. If that field does not exist in the CloudKit Console schema *and* is not indexed as queryable, the query throws. `ProfileSharingService.publishProfile` must be extended to write `username` so the field appears in the schema. CloudKit Console requires manual promotion of new fields before querying in production.
**Mitigation:** Planner includes a task: "Add `username` (String, queryable) to `PublicProfile` record type in CloudKit Console for both Development and Production environments before running username availability check on device."

### Risk 2: Apple credential fullName is nil on repeat sign-ins
**Details:** `ASAuthorizationAppleIDCredential.fullName` is only populated on the user's first authentication with this app. If the user has previously authorized and revoked, re-authorization will return nil fullName. The NameScreen pre-fill logic must handle this gracefully — showing an empty field (not crashing) when nil.
**Mitigation:** Guard the pre-fill: `nameField = credential.fullName.map(PersonNameComponentsFormatter().string(from:)) ?? ""`

### Risk 3: QLPreviewController + SwiftUI sheet layout
**Details:** `QLPreviewController` presented in a SwiftUI `.sheet` has a known interaction issue where the controller's navigation bar renders outside the safe area on some iOS 17 configurations. The sheet may appear blank or sized incorrectly.
**Mitigation:** Use `.sheet { PDFPreviewView(url: url).ignoresSafeArea() }` and set `presentationDetents: [.large]`. Test on a physical device — the simulator behaves differently.

### Risk 4: Username race condition displacement UX
**Details:** Two users simultaneously claim the same username. The check passes for both, both write, the post-save re-query finds the issue for the slower writer. The displacement alert ("that username was just claimed") must route the user back to `UsernameScreen` without losing their name or T&C acceptance state. Path manipulation: `path.removeLast()` is sufficient since UsernameScreen is the prior step.
**Mitigation:** Ensure `vg_hasAgreedToTerms` and `vg_onboardingName` are persisted before the username write so displacement routing does not lose those states.

### Risk 5: GoalCreationWizardView (createGoal step) — planner decision
**Details:** The current `OnboardingStep.createGoal` case routes to `GoalCreationWizardView(isOnboarding: true, onComplete: finish)`. CONTEXT.md marks this as Claude's Discretion (Phase 18 redesigns the wizard). If it stays, it currently works. If removed, the `finish()` call in `CommunityGoalOnboardingScreen` terminates onboarding. The risk is Phase 18 breaking the wizard and onboarding simultaneously.
**Recommendation:** Remove `.createGoal` from Phase 17's onboarding path. Let `CommunityGoalOnboardingScreen` call `finish()` directly. Phase 18 reintroduces the wizard in its own flow. This isolates the Phase 17 change and reduces coupling.

---

## Recommended Implementation Order

This sequence minimizes integration risk by establishing the routing scaffold before adding leaf screens:

**Plan 1: Auth gate + WelcomeScreen cleanup + LoginScreen re-auth (AUTH-01, AUTH-07)**
1. Remove Google button and "Create account" button from WelcomeScreen.
2. Move tagline above app icon in WelcomeScreen layout (VStack reorder).
3. Update WelcomeScreen onCompletion routing (D-03): returning user → `.login`, new user → `.termsAndConditions`.
4. Add `SignInWithAppleButton` to LoginScreen for AUTH-07.
5. Update `OnboardingStep` enum: add 4 new cases, remove `.motivationCategories`.
6. Update `navigationDestination` in `OnboardingView` with new cases (each routes to a placeholder `Text("TODO")` view initially).
7. Remove `.motivationCategories` routing from `NameScreen.advanceIfValid()`.

**Plan 2: T&C screen + PDF bundling (AUTH-02)**
1. Add PDF to Xcode project bundle resources.
2. Create `PDFPreviewView` (`UIViewControllerRepresentable` wrapping `QLPreviewController`).
3. Create `TermsAndConditionsScreen.swift` with "I Agree — Continue" button.
4. Wire into `navigationDestination` for `.termsAndConditions`.
5. Persist `vg_hasAgreedToTerms = true` on agree.

**Plan 3: UsernameScreen + CloudKit uniqueness service (AUTH-03)**
1. Add `username` field write to `ProfileSharingService.publishProfile`.
2. CloudKit Console task: add `username` (String, queryable) to `PublicProfile` schema.
3. Create `UsernameLookupService` with `isUsernameTaken(_:)` and `writeUsername(_:recordID:)`.
4. Extend `OnboardingViewModel` with debounce logic, `UsernameCheckState`, debounce task.
5. Create `UsernameScreen.swift` with inline ✓/✗ feedback (VGTheme.sage / VGTheme.terra).
6. Wire Continue button disabled state to `.available` state only.

**Plan 4: NameScreen pre-fill + ProfilePictureScreen (AUTH-04, D-04)**
1. Extend `OnboardingViewModel` with `appleFullName: PersonNameComponents?` property.
2. Pass fullName from WelcomeScreen onCompletion to ViewModel before path.append.
3. Update `NameScreen` to accept optional pre-fill and update `advanceIfValid()` to go to `.username`.
4. Create `ProfilePictureScreen.swift`: dual-source buttons (library + camera), skip button, photo preview.
5. Add `CameraPickerView` (`UIViewControllerRepresentable` for `UIImagePickerController`).
6. Add `ImageProcessor.resizeAndCompress(_:maxDimension:quality:)` utility.
7. Write chosen `photoData` to `OnboardingViewModel` for transfer to `UserProfile` at onboarding completion.

**Plan 5: CameraPermissionScreen (AUTH-06)**
1. Create `CameraPermissionScreen.swift` — mirror `NotificationOnboardingScreen` structure exactly.
2. "Allow Camera" CTA calls `AVCaptureDevice.requestAccess(for: .video)`.
3. "Skip for now" advances to `.communityGoal`.
4. Wire into `navigationDestination` for `.cameraPermission`.

**Plan 6: Report/Block on ProfileView (PROF-05)**
1. Create `BlockListService` (reads/writes `vg_blockedUserIDs` in UserDefaults).
2. Add `.contextMenu` to avatar `Circle` and display name `Text` in ProfileView heroBanner.
3. Add explicit "Report or Block" button below the profile card.
4. Wire Report action: `openReportEmail(subject:body:)` with MFMailCompose / mailto: fallback.
5. Wire Block action: confirmation alert → `BlockListService.blockUser(appleUserID:)`.
6. Identify the public profile view (target of `vitaming://profile/<recordID>` deep link) and add the same actions there if distinct from `ProfileView`.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `username` field does not yet exist as a queryable index in CloudKit Console's PublicProfile record type | Area 2 | Username queries throw `CKError.invalidArguments`; UniqueUsername check is dead |
| A2 | `NSCameraUsageDescription` already in Info.plist from Phase 15 camera work | Area 3 | Build fails or camera silently denied without the key |
| A3 | 500ms debounce via `Task.sleep(for: .milliseconds(500))` with cancellation is the idiomatic Swift Concurrency approach | Area 2 | Works but may need adjustment if Task.sleep granularity is coarser than expected |
| A4 | `ASAuthorizationAppleIDCredential.fullName` returns nil on repeat sign-ins | Area 5, Risk 2 | Pre-fill always empty for returning users; acceptable degradation but surprising if not handled |
| A5 | QLPreviewController + SwiftUI sheet has layout quirks requiring `.ignoresSafeArea()` | Area 6, Risk 3 | PDF view appears clipped or blank without the workaround |
| A6 | CommunityPost CloudKit records do not store author's Apple User ID | Area 8 | Block list cannot filter community feed in Phase 17; feed filtering is Phase 21 work |
| A7 | The `ProfileView.swift` read is the user's own profile; a separate view handles public profile viewing | Area 9 | If ProfileView is used for both, the contextMenu placement logic changes |
| A8 | Removing GoalCreationWizardView from Phase 17 onboarding is the correct planner choice | Risk 5 | If kept, Phase 18 wizard redesign may conflict |
| A9 | `UserDefaults.standard.synchronize()` or OS flush is sufficient for block list durability | Area 8 | Block list lost if app is killed immediately after blocking before flush |

---

## Sources

### Primary (HIGH confidence — direct codebase inspection)
- `VitaminG/Views/Onboarding/WelcomeScreen.swift` — current auth buttons, onCompletion handler, routing logic
- `VitaminG/Views/Onboarding/OnboardingView.swift` — OnboardingStep enum, NavigationStack pattern, finish()
- `VitaminG/ViewModels/OnboardingViewModel.swift` — current ViewModel shape
- `VitaminG/Views/Onboarding/LoginScreen.swift` — current Welcome Back layout
- `VitaminG/Views/Onboarding/NameScreen.swift` — StepBarView pattern, advanceIfValid() routing
- `VitaminG/Views/Onboarding/NotificationOnboardingScreen.swift` — priming slide pattern to mirror
- `VitaminG/VitaminGApp.swift` — @AppStorage("hasCompletedOnboarding") wiring
- `VitaminG/ViewModels/ProfileViewModel.swift` — handlePhotoSelection, PhotosPickerItem, usernameValidationError
- `VitaminG/Views/ProfileView.swift` — AVCaptureDevice.requestAccess pattern, .photosPicker usage, contextMenu target elements
- `VitaminG/Services/ProfileSharingService.swift` — CKContainer ID, PublicProfile record type, async/await CloudKit pattern
- `VitaminG/Services/CommunityService.swift` — CKQuery with records(matching:resultsLimit:), compressToJPEG
- `VitaminG/Models/SchemaV8.swift` — UserProfile.username and UserProfile.photoData confirmed present

### Secondary (MEDIUM confidence — framework knowledge, not verified against live CloudKit Console)
- CloudKit public database queryable index requirement for NSPredicate queries
- QLPreviewController UIViewControllerRepresentable pattern
- MFMailComposeViewController canSendMail() pattern and mailto: fallback
- AVCaptureDevice.requestAccess(for: .video) async callback pattern
- ASAuthorizationAppleIDCredential.fullName returning nil on repeat authentications

---

## RESEARCH COMPLETE

**Phase:** 17 — Onboarding Overhaul
**Confidence:** HIGH for codebase integration patterns; MEDIUM for CloudKit Console state and QuickLook layout edge cases

### Key Findings
- The codebase already has 80% of the required building blocks: `SignInWithAppleButton` is wired in WelcomeScreen, `PhotosPickerItem` is in ProfileViewModel, `AVCaptureDevice.requestAccess` is in ProfileView, and `CKQuery` with `db.records(matching:resultsLimit:)` is in CommunityService.
- The CloudKit `PublicProfile` record type must be extended with a queryable `username` field — this requires a CloudKit Console step, not just code changes.
- The username race condition requires a post-save re-query verification step; the check-then-write pattern alone is insufficient.
- `QLPreviewController` has no SwiftUI native equivalent; a `UIViewControllerRepresentable` wrapper is required for T&C PDF viewing.
- The block list community feed filtering is only partially implementable in Phase 17 — blocking a user in ProfileView works, but filtering community posts requires the author's Apple User ID in `CommunityPost` records, which are written without that field today.
- `GoalCreationWizardView(isOnboarding: true)` should be removed from the Phase 17 flow to decouple it from Phase 18's wizard redesign.

### File Created
`/Users/kyleharrington/Desktop/AI/Vitamin G/.planning/phases/17-onboarding-overhaul/17-RESEARCH.md`

### Confidence Assessment
| Area | Level | Reason |
|------|-------|--------|
| OnboardingStep routing | HIGH | Direct codebase read of all relevant files |
| CloudKit username query API | HIGH | CommunityService already uses identical pattern |
| CloudKit Console index state | LOW | Cannot inspect CloudKit Console from code |
| PHPickerViewController / PhotosPickerItem | HIGH | Already in ProfileViewModel and ProfileView |
| AVCaptureDevice permission | HIGH | Already in ProfileView.requestCameraAndShow() |
| QLPreviewController wrapping | MEDIUM | No existing usage in codebase; pattern is standard UIKit |
| MFMailComposeViewController | MEDIUM | No existing usage in codebase; pattern is standard UIKit |
| Block list UserDefaults persistence | HIGH | Standard UserDefaults pattern; no novel risk |
| Report/Block contextMenu targets | HIGH | PublicProfileView.swift confirmed as Phase 17 target (user decision); contextMenu targets identified in codebase read |

### Open Questions (PARTIALLY RESOLVED)
1. **Where is the public profile view?** (RESOLVED) PublicProfileView.swift exists and receives `recordID: String`. It is the destination for the `vitaming://profile/<recordID>` deep link and is the confirmed Phase 17 target for PROF-05 (user decision). Plan 05 adds Report/Block to PublicProfileView.
2. **Is `NSCameraUsageDescription` already in Info.plist?** (RESOLVED: YES) Confirmed present at VitaminG/VitaminG/VitaminG/Info.plist line 30: "Vitamin G uses your camera to update your profile photo." No action required. Plan 04 threat model updated to reflect this (T-17-04-04 disposition changed from open to mitigate/confirmed).
3. **Has the `username` field been added to CloudKit Console for PublicProfile?** (UNRESOLVED — requires CloudKit Console access) Cannot verify from code. Plan 03 includes a blocking human checkpoint to confirm the Queryable index exists before username availability checks are tested on device.

### Ready for Planning
Research complete. Planner can now create PLAN.md files using the 6-plan structure in Recommended Implementation Order.
