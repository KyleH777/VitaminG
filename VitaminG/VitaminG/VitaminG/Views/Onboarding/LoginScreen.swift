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
