import SwiftUI
import AVFoundation

// MARK: - CameraPermissionScreen
// Onboarding Screen 7: Full-screen dark camera permission priming slide.
// Mirrors NotificationOnboardingScreen exactly — dark clay bg, glassmorphism card,
// same .safeAreaInset CTA tray pattern.
// AUTH-06: "Allow Camera" triggers AVCaptureDevice.requestAccess and advances.
// "Skip for now" advances to .communityGoal without requesting camera access.
// T-17-04-03 mitigation: AVCaptureDevice callback dispatched to main thread.

struct CameraPermissionScreen: View {

    @Binding var path: [OnboardingStep]
    let onSkip: () -> Void

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

                // Mock camera preview card (glassmorphism — mirrors NotificationOnboardingScreen)
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
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(VGTheme.sand)
                            Text("Camera")
                                .font(.system(size: 11))
                                .foregroundStyle(VGTheme.muted)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 12)

                    // Camera placeholder viewfinder
                    Rectangle()
                        .fill(VGTheme.clay.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundStyle(VGTheme.muted)
                        )
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

                // Headline block (mirrors NotificationOnboardingScreen exactly)
                VStack(alignment: .leading, spacing: 14) {
                    Text("Share your\n\(Text("journey.").font(Font.custom("Georgia-Italic", size: 42)).foregroundStyle(VGTheme.terraSoft))")
                        .font(Font.custom("Georgia", size: 42))
                        .foregroundStyle(VGTheme.sand)

                    Text("Your profile picture and goal photos help your community connect with your progress.")
                        .font(.system(size: 14, weight: .light))
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
    }

    // MARK: - Actions

    /// Requests camera access and advances to .communityGoal regardless of grant outcome.
    /// The permission dialog educates the user; the flow proceeds either way.
    private func allow() {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            DispatchQueue.main.async {
                path.append(.communityGoal)
            }
        }
    }

    private func skip() {
        path.append(.communityGoal)
    }
}
