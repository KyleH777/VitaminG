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

            recoveryOptionCard(icon: "🔄", title: "Restore from iCloud",
                subtitle: "Sync your goals and streak from iCloud backup",
                isHighlighted: true, action: onSkip)

            recoveryOptionCard(icon: "🔑", title: "Start fresh",
                subtitle: "Clear everything and start a new profile",
                isHighlighted: false, action: { showStartFreshAlert = true })

            recoveryOptionCard(icon: "🤝", title: "Contact support",
                subtitle: "Real human · usually within 24h",
                isHighlighted: false, action: openSupport)
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
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(VGTheme.terraSoft, lineWidth: 1))
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

    @ViewBuilder
    private func recoveryOptionCard(icon: String, title: String, subtitle: String,
                                    isHighlighted: Bool, action: @escaping () -> Void) -> some View {
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
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(isHighlighted ? VGTheme.terra : Color.clear, lineWidth: 2))
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
