import SwiftUI
import AuthenticationServices


// MARK: - TabletConfig
private struct TabletConfig: Identifiable {
    let id: Int
    let leftFraction: CGFloat
    let duration: Double
    let delay: Double
    let size: CGFloat
    let color1: Color
    let color2: Color
    let rotation: Double
    // Pile position
    let pileOffsetX: CGFloat
    let pileRotation: Double
}

// MARK: - RainingTabletItem
private struct RainingTabletItem: View {
    let config: TabletConfig
    let screenHeight: CGFloat
    @State private var yOffset: CGFloat = -80

    var body: some View {
        VGCapsule(size: config.size, color1: config.color1, color2: config.color2)
            .rotationEffect(.degrees(config.rotation))
            .offset(y: yOffset)
            .task {
                try? await Task.sleep(for: .seconds(config.delay))
                withAnimation(.linear(duration: config.duration).repeatForever(autoreverses: false)) {
                    yOffset = screenHeight + 100
                }
            }
    }
}

// MARK: - WelcomeScreen
// Onboarding Screen 1: Splash — redesigned per Vitamin G brand spec.
// Raining vitamin tablets, warm clay background, app icon center stage.

struct WelcomeScreen: View {

    @Binding var path: [OnboardingStep]
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("vg_onboardingName") private var savedName: String = ""
    @AppStorage("vg_appleUserID") private var appleUserID: String = ""

    private let tablets: [TabletConfig] = [
        TabletConfig(id: 0,  leftFraction: 0.05, duration: 2.8, delay: 0.0, size: 32, color1: VGTheme.terraSoft, color2: VGTheme.terra,   rotation: 15,  pileOffsetX: 18,  pileRotation: -22),
        TabletConfig(id: 1,  leftFraction: 0.14, duration: 3.2, delay: 0.4, size: 28, color1: VGTheme.sage,      color2: VGTheme.sageMid, rotation: -20, pileOffsetX: 48,  pileRotation: 14),
        TabletConfig(id: 2,  leftFraction: 0.24, duration: 2.6, delay: 0.8, size: 34, color1: VGTheme.gold,      color2: Color(red: 0.604, green: 0.478, blue: 0.188), rotation: 30, pileOffsetX: 80, pileRotation: -8),
        TabletConfig(id: 3,  leftFraction: 0.34, duration: 3.4, delay: 0.2, size: 26, color1: VGTheme.purple,    color2: Color(red: 0.416, green: 0.306, blue: 0.541), rotation: -10, pileOffsetX: 108, pileRotation: 20),
        TabletConfig(id: 4,  leftFraction: 0.45, duration: 2.9, delay: 1.0, size: 30, color1: VGTheme.terraSoft, color2: Color(red: 0.627, green: 0.322, blue: 0.176), rotation: 25, pileOffsetX: 136, pileRotation: -5),
        TabletConfig(id: 5,  leftFraction: 0.56, duration: 3.1, delay: 0.6, size: 28, color1: VGTheme.sage,      color2: VGTheme.sageMid, rotation: -18, pileOffsetX: 164, pileRotation: 18),
        TabletConfig(id: 6,  leftFraction: 0.66, duration: 2.7, delay: 1.4, size: 32, color1: VGTheme.gold,      color2: Color(red: 0.604, green: 0.478, blue: 0.188), rotation: 12, pileOffsetX: 192, pileRotation: -12),
        TabletConfig(id: 7,  leftFraction: 0.75, duration: 3.3, delay: 0.3, size: 26, color1: VGTheme.purple,    color2: Color(red: 0.416, green: 0.306, blue: 0.541), rotation: -30, pileOffsetX: 218, pileRotation: 25),
        TabletConfig(id: 8,  leftFraction: 0.85, duration: 2.5, delay: 0.9, size: 34, color1: VGTheme.terraSoft, color2: VGTheme.terra,   rotation: 20,  pileOffsetX: 246, pileRotation: -15),
        TabletConfig(id: 9,  leftFraction: 0.92, duration: 3.0, delay: 0.5, size: 28, color1: VGTheme.sage,      color2: VGTheme.sageMid, rotation: -8,  pileOffsetX: 272, pileRotation: 10),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Background
                VGTheme.clay
                    .ignoresSafeArea()

                // Radial warm glow
                RadialGradient(
                    colors: [Color(red: 0.353, green: 0.227, blue: 0.133), VGTheme.clay],
                    center: .center,
                    startRadius: 0,
                    endRadius: geo.size.height * 0.55
                )
                .ignoresSafeArea()

                // Raining tablets
                if !reduceMotion {
                    ForEach(tablets) { t in
                        RainingTabletItem(config: t, screenHeight: geo.size.height)
                            .position(x: geo.size.width * t.leftFraction, y: geo.size.height / 2)
                    }
                }

                // Tablet pile at bottom
                ZStack(alignment: .bottomLeading) {
                    // First layer
                    ForEach(tablets) { t in
                        VGCapsule(size: t.size, color1: t.color1, color2: t.color2)
                            .rotationEffect(.degrees(t.pileRotation))
                            .offset(x: t.pileOffsetX - 20, y: 0)
                            .opacity(0.85)
                    }
                    // Second layer (offset)
                    ForEach(tablets.prefix(6)) { t in
                        VGCapsule(size: t.size * 0.8, color1: t.color2, color2: t.color1)
                            .rotationEffect(.degrees(t.pileRotation * -0.6))
                            .offset(x: t.pileOffsetX, y: -t.size * 0.65)
                            .opacity(0.65)
                    }
                }
                .frame(height: 60)
                .padding(.bottom, 130)
                .padding(.leading, 0)
                .frame(maxWidth: .infinity, alignment: .bottomLeading)

                // Center content
                VStack(spacing: 0) {
                    Spacer()

                    // "Your daily dose" badge
                    HStack(spacing: 7) {
                        VGCapsule(size: 16, color1: VGTheme.terraSoft, color2: VGTheme.terra)
                        Text("YOUR DAILY DOSE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(VGTheme.sand.opacity(0.7))
                            .kerning(1.5)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.10))
                    .overlay(
                        Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .clipShape(Capsule())
                    .padding(.bottom, 20)

                    // Tagline — moved above app icon per D-02
                    Text("GOALS. GROWTH. COMMUNITY.")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(VGTheme.muted)
                        .kerning(2)
                        .padding(.bottom, 16)

                    // App icon
                    RoundedRectangle(cornerRadius: 30)
                        .fill(VGTheme.sand)
                        .frame(width: 108, height: 108)
                        .overlay(
                            Text("G")
                                .font(Font.custom("Georgia-Italic", size: 54))
                                .foregroundStyle(VGTheme.clay)
                        )
                        .shadow(color: .black.opacity(0.5), radius: 24, y: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .padding(.bottom, 22)

                    // App name
                    Text("Vitamin G")
                        .font(Font.custom("Georgia", size: 48))
                        .foregroundStyle(VGTheme.sand)

                    Spacer()
                }
                .padding(.horizontal, 28)

                // Bottom buttons — Sign in with Apple only (per D-01, AUTH-01)
                VStack(spacing: 12) {
                    // Sign in with Apple (sole auth CTA)
                    SignInWithAppleButton(.signIn, onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    }, onCompletion: { result in
                        switch result {
                        case .success(let auth):
                            if let cred = auth.credential as? ASAuthorizationAppleIDCredential {
                                let uid = cred.user
                                appleUserID = uid
                                UserDefaults.standard.set(uid, forKey: "vg_appleUserID")
                                // TODO Plan 4: pass cred.fullName to onboardingVM.appleFullName
                            }
                            // D-03: returning user → .login; new user → .termsAndConditions
                            if !savedName.trimmingCharacters(in: .whitespaces).isEmpty {
                                path.append(.login)
                            } else {
                                path.append(.termsAndConditions)
                            }
                        case .failure:
                            break
                        }
                    })
                    .signInWithAppleButtonStyle(.black)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 44)
            }
        }
        .navigationBarHidden(true)
    }
}
