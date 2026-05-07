import SwiftUI
import SwiftData

// MARK: - MilestoneCelebrationView
//
// Full-screen milestone celebration sheet shown via .fullScreenCover in ChallengeDetailView.
// Displays: dark overlay (0.92 opacity), SwiftUI Canvas confetti (no SpriteKit),
// 64pt milestone badge SF Symbol, milestone message, challenge title attribution,
// and a "Keep Going" dismiss button.
//
// Badge save: on .onAppear, writes earned badge SF symbol to UserChallenge.earnedBadgeSymbolsJSON.
// Idempotent — only appends if not already present.
//
// CHAL-10 / 13-PLAN-06 / UI-SPEC.md MilestoneCelebrationView spec.

struct MilestoneCelebrationView: View {
    let userChallenge: UserChallenge
    let threshold: Int
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var badgeScale: Double = 0.3
    @State private var badgeOpacity: Double = 0.0

    // MARK: - Badge Symbol (UI-SPEC.md Milestone Badge SF Symbols table)

    private var badgeSymbol: String {
        switch threshold {
        case 7:  return "flame.fill"
        case 30: return "trophy.fill"
        case 60: return "medal.fill"
        case 90: return "star.fill"
        default: return "star.fill"  // fallback for custom milestones
        }
    }

    // MARK: - Milestone Message

    private var milestoneMessage: String {
        userChallenge.template?.milestones.first(where: { $0.dayThreshold == threshold })?.message
            ?? "Milestone reached!"
    }

    // MARK: - Accent Color

    private var accentColor: Color {
        Color(hex: userChallenge.template?.accentColorHex ?? "#C4673A")
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Dark overlay — 0.92 opacity per UI-SPEC.md
            Color.black.opacity(0.92).ignoresSafeArea()

            // Confetti canvas behind the badge card (decorative — accessibilityHidden)
            confettiView
                .ignoresSafeArea()
                .accessibilityHidden(true)

            // Badge + message card
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: badgeSymbol)
                    .font(.system(size: 64))
                    .foregroundStyle(accentColor)
                    .scaleEffect(badgeScale)
                    .opacity(badgeOpacity)
                    .accessibilityLabel("Milestone reached: \(milestoneMessage)")

                Text(milestoneMessage)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text(userChallenge.template?.title ?? "")
                    .font(.body)
                    .fontDesign(.rounded)
                    .foregroundStyle(.white.opacity(0.8))

                Spacer()

                Button("Keep Going") { onDismiss() }
                    .font(.body)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
        .onAppear {
            saveBadgeToProfile()
            if reduceMotion {
                // Reduce Motion: show badge statically, skip scale animation
                badgeScale = 1.0
                badgeOpacity = 1.0
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    badgeScale = 1.0
                    badgeOpacity = 1.0
                }
            }
            UIAccessibility.post(
                notification: .announcement,
                argument: "Milestone reached: \(milestoneMessage)"
            )
        }
    }

    // MARK: - Confetti (SwiftUI Canvas + TimelineView — no SpriteKit, no third-party)

    private var confettiView: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let count = 60
                for i in 0..<count {
                    let seed = Double(i) * 137.5  // golden angle scatter
                    let x = (sin(seed + now * 0.8 + Double(i)) * 0.5 + 0.5) * size.width
                    // y falls downward over time, wraps at bottom
                    let rawY = (now * 80.0 + seed * 3.7).truncatingRemainder(dividingBy: size.height)
                    let y = rawY < 0 ? rawY + size.height : rawY
                    let hue = (seed / 360.0).truncatingRemainder(dividingBy: 1.0)
                    let color = Color(hue: hue, saturation: 0.8, brightness: 0.9)
                    let rect = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
    }

    // MARK: - Badge Save Logic (idempotent — CHAL-10)

    /// Appends the earned badge SF symbol name to UserChallenge.earnedBadgeSymbolsJSON.
    /// Idempotent: only appends if the symbol is not already present.
    /// T-13-21: malformed JSON falls back to [] and is overwritten with valid data.
    private func saveBadgeToProfile() {
        let symbol = badgeSymbol
        // Decode existing array — T-13-21: try? returns nil on malformed JSON, falls back to []
        var symbols: [String] = []
        if let json = userChallenge.earnedBadgeSymbolsJSON,
           let data = json.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            symbols = decoded
        }
        // Idempotent: only append if not already present
        guard !symbols.contains(symbol) else { return }
        symbols.append(symbol)
        // Encode and persist — SwiftData tracks @Model mutations automatically; no explicit save() needed
        if let data = try? JSONEncoder().encode(symbols),
           let json = String(data: data, encoding: .utf8) {
            userChallenge.earnedBadgeSymbolsJSON = json
        }
    }
}
