import SwiftUI

// MARK: - NotificationOnboardingScreen
// Onboarding Screen 4: Full-screen dark notification opt-in.
// Matches the design spec dark clay aesthetic with a mock notification preview.

struct NotificationOnboardingScreen: View {

    @Binding var path: [OnboardingStep]
    let onSkip: () -> Void

    @AppStorage("vg_onboardingName") private var storedName: String = ""

    var firstName: String {
        storedName.split(separator: " ").first.map(String.init) ?? "You"
    }

    var body: some View {
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

                // Mock notification card (decorative preview)
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(VGTheme.terra)
                            .frame(width: 34, height: 34)
                            .overlay(
                                Text("G")
                                    .font(Font.custom("Georgia-Italic", size: 16))
                                    .foregroundStyle(VGTheme.warmWhite)
                            )
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Vitamin G")
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(VGTheme.sand)
                            Text("now")
                                .font(.caption2)
                                .foregroundStyle(VGTheme.muted)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 12)

                    Text("Good morning, \(firstName)")
                        .font(Font.custom("Georgia", size: 19))
                        .foregroundStyle(VGTheme.sand)
                        .padding(.bottom, 6)

                    Text("Day 12 of your Summer Body Challenge. You're 72% there.")
                        .font(.callout.weight(.light))
                        .foregroundStyle(VGTheme.sand.opacity(0.7))
                        .lineSpacing(4)
                        .lineLimit(2)
                }
                .padding(18)
                .background(.ultraThinMaterial.opacity(0.3))
                .background(Color.white.opacity(0.11))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                )
                .padding(.horizontal, 28)
                .padding(.bottom, 32)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Example notification preview")
                .accessibilityHidden(true)

                // Headline
                VStack(alignment: .leading, spacing: 14) {
                    Text("Stay on track, every day.")
                        .font(Font.custom("Georgia", size: 42))
                        .foregroundStyle(VGTheme.sand)
                        .accessibilityAddTraits(.isHeader)

                    Text("One daily nudge at the time you choose. No noise — just your reminder to keep going.")
                        .font(.callout.weight(.light))
                        .foregroundStyle(VGTheme.muted)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                Button(action: allow) {
                    Text("Allow Notifications")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(VGTheme.sand)
                        .foregroundStyle(VGTheme.clay)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .accessibilityHint("Requests permission to send daily goal reminders")

                Button(action: skip) {
                    Text("Maybe later")
                        .font(.callout)
                        .foregroundStyle(VGTheme.sand.opacity(0.55))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .frame(minHeight: 44)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 12)
            .background(VGTheme.clay)
        }
        .navigationBarHidden(true)
    }

    private func allow() {
        Task {
            let granted = await NotificationScheduler.shared.requestAuthorization()
            if granted {
                path.append(.nudgeTimePicker)
            } else {
                path.append(.cameraPermission)
            }
        }
    }

    private func skip() {
        path.append(.cameraPermission)
    }
}
