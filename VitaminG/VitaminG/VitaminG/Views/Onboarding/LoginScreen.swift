// VitaminG/Views/Onboarding/LoginScreen.swift
import SwiftUI
import AuthenticationServices

struct LoginScreen: View {

    @Binding var path: [OnboardingStep]
    let onSkip: () -> Void

    @AppStorage("vg_onboardingName") private var savedName: String = ""
    @State private var reAuthFailed: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VGTheme.sandLight.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                backArrow

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
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("WELCOME BACK")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(VGTheme.muted)
                            .kerning(1.5)
                            .accessibilityHidden(true)
                        Text("Vitamin G")
                            .font(VGTheme.serif(24))
                            .foregroundStyle(VGTheme.clay)
                            .accessibilityAddTraits(.isHeader)
                    }
                }
                .padding(.bottom, 20)

                Text("Good to see\nyou again.")
                    .font(VGTheme.serif(36))
                    .foregroundStyle(VGTheme.clay)
                    .lineSpacing(4)
                    .padding(.bottom, 10)

                Text("Your goals and streaks are right where you left them.")
                    .font(.callout)
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

    private var backArrow: some View {
        HStack {
            Button(action: { path.removeLast() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(VGTheme.clay)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel("Go back")
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
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Continue as \(savedName)")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(VGTheme.clay)
                    Text("Tap to jump back in")
                        .font(.caption2)
                        .foregroundStyle(VGTheme.muted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(VGTheme.terra)
                    .accessibilityHidden(true)
            }
            .padding(14)
            .background(VGTheme.warmWhite)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: VGTheme.clay.opacity(0.06), radius: 8, y: 1)
        }
        .accessibilityLabel("Continue as \(savedName)")
    }

    private var bottomButtons: some View {
        VStack(spacing: 0) {
            // Apple re-auth button (AUTH-07, D-11) — above "Having trouble?" link
            SignInWithAppleButton(.signIn, onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            }, onCompletion: { result in
                switch result {
                case .success:
                    reAuthFailed = false
                    onSkip()
                case .failure:
                    reAuthFailed = true
                }
            })
            .signInWithAppleButtonStyle(.black)
            .frame(maxWidth: .infinity, minHeight: 54)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 28)
            .padding(.bottom, 12)

            if reAuthFailed {
                Text("Sign in failed. Please try again.")
                    .font(.callout.weight(.light))
                    .foregroundStyle(VGTheme.terra)
                    .padding(.horizontal, 28)
                    .accessibilityLiveRegion(.polite)
            }

            Button(action: { path.append(.recovery) }) {
                Text("Having trouble?")
                    .font(.callout)
                    .foregroundStyle(VGTheme.muted)
                    .frame(minHeight: 44)
            }

            Button(action: {
                savedName = ""
                path = [.name]
            }) {
                Text("This isn't me")
                    .font(.body)
                    .foregroundStyle(VGTheme.sand.opacity(0.55))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 44)
    }
}
