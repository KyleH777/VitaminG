import SwiftUI

// MARK: - UsernameScreen
// Onboarding Step 2: Username claim with async CloudKit uniqueness check.
// Uses OnboardingViewModel.onUsernameChanged() for 500ms debounced availability check.
// D-17: post-save race condition recovery — clears field, shows inline error.

struct UsernameScreen: View {

    @Binding var path: [OnboardingStep]
    let onSkip: () -> Void
    var viewModel: OnboardingViewModel

    @AppStorage("vg_appleUserID") private var appleUserID: String = ""
    @AppStorage("vg_onboardingUsername") private var storedUsername: String = ""

    @State private var usernameInput: String = ""
    @State private var isClaiming: Bool = false
    @State private var raceConditionError: String? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            VGTheme.sandLight
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Nav row — same pattern as NameScreen
                HStack {
                    Button(action: { path.removeLast() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(VGTheme.clay)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel("Go back")
                    Spacer()
                }
                .padding(.bottom, 20)

                // Step bar — Username is step 2 of 7
                StepBarView(current: 2, total: 7)
                    .padding(.bottom, 28)

                // Field label
                Text("USERNAME")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(VGTheme.muted)
                    .kerning(1.5)
                    .padding(.bottom, 8)
                    .accessibilityHidden(true)

                // Headline
                Text("Claim your\nusername")
                    .font(Font.custom("Georgia", size: 42))
                    .foregroundStyle(VGTheme.clay)
                    .lineSpacing(4)
                    .padding(.bottom, 8)
                    .accessibilityAddTraits(.isHeader)

                // Subtitle
                Text("Choose a unique handle. This is how others find you.")
                    .font(.callout.weight(.light))
                    .foregroundStyle(VGTheme.muted)
                    .lineSpacing(4)
                    .padding(.bottom, 24)

                // Username text field
                TextField("", text: $usernameInput)
                    .font(Font.custom("CormorantGaramond-Regular", size: 34))
                    .foregroundStyle(VGTheme.clay)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .accessibilityLabel("Username")
                    .accessibilityHint("Choose a unique handle used by others to find you")

                // Terra underline
                Rectangle()
                    .fill(VGTheme.terra)
                    .frame(height: 2)
                    .padding(.bottom, 4)

                // Inline state indicator
                Group {
                    switch viewModel.usernameCheckState {
                    case .idle:
                        EmptyView()
                    case .checking:
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Checking...")
                                .font(.footnote.weight(.light))
                                .foregroundStyle(VGTheme.muted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    case .available:
                        Label("✓ Available", systemImage: "checkmark.circle.fill")
                            .font(.footnote.weight(.light))
                            .foregroundStyle(VGTheme.sage)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    case .taken:
                        Label("✗ Already taken", systemImage: "xmark.circle.fill")
                            .font(.footnote.weight(.light))
                            .foregroundStyle(VGTheme.terra)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    case .invalid(let msg):
                        Text(msg)
                            .font(.footnote.weight(.light))
                            .foregroundStyle(VGTheme.terra)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Race condition error (D-17)
                if let err = raceConditionError {
                    Text(err)
                        .font(.callout.weight(.light))
                        .foregroundStyle(VGTheme.terra)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                        .accessibilityLiveRegion(.polite)
                }

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)

            // Bottom CTA
            VStack(spacing: 8) {
                Button(action: advanceIfAvailable) {
                    if isClaiming {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(VGTheme.terra)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
                        Text("Continue")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(canContinue ? VGTheme.terra : VGTheme.sandMid)
                            .foregroundStyle(canContinue ? VGTheme.warmWhite : VGTheme.sandDeep)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .disabled(!canContinue || isClaiming)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 36)
        }
        .navigationBarHidden(true)
        .onChange(of: usernameInput) { _, newValue in
            viewModel.onUsernameChanged(newValue)
        }
    }

    // MARK: - Computed

    private var canContinue: Bool {
        if case .available = viewModel.usernameCheckState { return true }
        return false
    }

    // MARK: - Actions

    /// Initiates the username claim. On success: stores username and advances.
    /// On D-17 race condition displacement: clears field, shows inline error.
    private func advanceIfAvailable() {
        guard canContinue, !isClaiming else { return }
        isClaiming = true
        raceConditionError = nil
        Task {
            let success = await viewModel.claimUsername(usernameInput.lowercased(), appleUserID: appleUserID)
            if success {
                storedUsername = usernameInput.lowercased()
                path.append(.profilePicture)
            } else {
                // Race condition: another device claimed this username first.
                // Clear field and show inline error (D-17) — no modal alert.
                usernameInput = ""
                viewModel.usernameCheckState = .idle
                raceConditionError = "That username was just taken — try another."
            }
            isClaiming = false
        }
    }
}
