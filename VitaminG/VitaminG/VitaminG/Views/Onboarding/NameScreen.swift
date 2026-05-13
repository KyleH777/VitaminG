import SwiftUI

// MARK: - NameScreen
// Onboarding Screen 2: Name entry.
// Collects the user's display name in the Robinhood-inspired large-type style.

struct NameScreen: View {

    @Binding var path: [OnboardingStep]
    let onSkip: () -> Void

    @AppStorage("vg_onboardingName") private var storedName: String = ""
    @State private var name: String = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            VGTheme.sandLight
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Nav row
                HStack {
                    Button(action: { path.removeLast() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(VGTheme.clay)
                    }
                    Spacer()
                }
                .padding(.bottom, 20)

                // Step bar
                StepBarView(current: 0, total: 4)
                    .padding(.bottom, 28)

                // Headline
                VStack(alignment: .leading, spacing: 12) {
                    Text("What should\nwe call you?")
                        .font(Font.custom("Georgia", size: 42))
                        .foregroundStyle(VGTheme.clay)
                        .lineSpacing(4)

                    Text("Your name shows on your profile and community posts.")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(VGTheme.muted)
                        .lineSpacing(4)
                }
                .padding(.bottom, 40)

                // Name field
                VStack(alignment: .leading, spacing: 0) {
                    Text("DISPLAY NAME")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(VGTheme.muted)
                        .kerning(1.5)
                        .padding(.bottom, 8)

                    HStack(alignment: .bottom, spacing: 0) {
                        TextField("", text: $name)
                            .font(Font.custom("Georgia", size: 34))
                            .foregroundStyle(VGTheme.clay)
                            .focused($fieldFocused)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .onSubmit { advanceIfValid() }

                        if name.isEmpty {
                            Capsule()
                                .fill(VGTheme.terra)
                                .frame(width: 2, height: 30)
                                .opacity(fieldFocused ? 1 : 0)
                        }
                    }
                    .padding(.bottom, 12)

                    Rectangle()
                        .fill(VGTheme.terra)
                        .frame(height: 2)
                }

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)

            // Bottom
            VStack(spacing: 8) {
                Button(action: advanceIfValid) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(name.trimmingCharacters(in: .whitespaces).isEmpty ? VGTheme.sandMid : VGTheme.terra)
                        .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty ? VGTheme.sandDeep : VGTheme.warmWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 36)
        }
        .navigationBarHidden(true)
        .onAppear {
            name = storedName
            fieldFocused = true
        }
    }

    private func advanceIfValid() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        storedName = String(trimmed.prefix(50))
        path.append(.motivationCategories)
    }
}

// MARK: - StepBarView
// Reusable step progress bar — matches the design spec terracotta/sandMid pattern.

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
