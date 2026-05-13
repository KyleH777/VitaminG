import SwiftUI
import SwiftData

enum BreathingPhase: CaseIterable {
    case inhale, holdFull, exhale, holdEmpty

    var label: String {
        switch self {
        case .inhale:    return "Inhale"
        case .holdFull:  return "Hold"
        case .exhale:    return "Exhale"
        case .holdEmpty: return "Hold"
        }
    }

    var fillTarget: Double {
        switch self {
        case .inhale:    return 1.0
        case .holdFull:  return 1.0
        case .exhale:    return 0.0
        case .holdEmpty: return 0.0
        }
    }

    var next: BreathingPhase {
        switch self {
        case .inhale:    return .holdFull
        case .holdFull:  return .exhale
        case .exhale:    return .holdEmpty
        case .holdEmpty: return .inhale
        }
    }
}

struct CravingToolsModuleView: View {
    let userChallenge: UserChallenge

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext

    @State private var phase: BreathingPhase = .inhale
    @State private var countdown: Int = 4
    @State private var fillFraction: Double = 0.0
    @State private var isActive: Bool = true
    @State private var currentQuote: VGQuote = VGQuoteBank.randomQuote()
    @State private var pingSent: Bool = false

    private static let phaseDurationSeconds: UInt64 = 4

    private var accentColor: Color {
        Color(hex: userChallenge.template?.accentColorHex ?? "#C4673A")
    }

    private var challengeTitle: String {
        userChallenge.template?.title ?? "your challenge"
    }

    // Local-fallback cooldown check — Plan 14-08 will add a typed UserChallenge extension;
    // this keeps Plan 14-06 self-contained and compilable beforehand.
    private var canPing: Bool {
        guard let last = userChallenge.buddyPingLastSent else { return true }
        return Date().timeIntervalSince(last) >= 86_400
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    boxBreathingSection
                    Divider().padding(.horizontal, 32)
                    motivationalPromptSection
                    if let buddyName = userChallenge.buddyDisplayName, !buddyName.isEmpty {
                        Divider().padding(.horizontal, 32)
                        buddyPingSection(buddyName: buddyName)
                    }
                }
                .padding(.vertical, 24)
            }
            .background(VGTheme.sandLight)
            .navigationTitle("Craving Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.body.weight(.semibold))
                        .fontDesign(.rounded)
                }
            }
            .onAppear {
                isActive = true
                Task { await runBreathingLoop() }
            }
            .onDisappear {
                isActive = false
            }
        }
    }

    // MARK: - Section 1: Box breathing

    private var boxBreathingSection: some View {
        VStack(spacing: 16) {
            Text(phase.label)
                .font(.title2.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.clay)
                .accessibilityLabel("Box breathing: \(phase.label), \(countdown) seconds")

            ZStack {
                Circle()
                    .strokeBorder(
                        reduceMotion ? accentColor : accentColor.opacity(0.3),
                        lineWidth: reduceMotion ? 3 : 2
                    )
                    .frame(width: 200, height: 200)

                if !reduceMotion {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 200, height: 200)
                        .scaleEffect(fillFraction)
                        .animation(.linear(duration: 4), value: fillFraction)
                }

                Text("\(countdown)")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(VGTheme.clay)
                    .accessibilityHidden(true)
            }
            .frame(width: 200, height: 200)
        }
    }

    // MARK: - Section 2: Motivational prompt

    private var motivationalPromptSection: some View {
        VStack(spacing: 16) {
            Text("Stay Grounded")
                .font(.title2.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.clay)

            Text(currentQuote.text)
                .font(VGTheme.serifItalic(17))
                .multilineTextAlignment(.center)
                .foregroundStyle(VGTheme.clay)
                .padding(.horizontal, 24)

            Button("Another One") {
                currentQuote = VGQuoteBank.randomQuote()
            }
            .font(.body.weight(.semibold))
            .fontDesign(.rounded)
            .foregroundStyle(accentColor)
        }
    }

    // MARK: - Section 3: Buddy ping

    private func buddyPingSection(buddyName: String) -> some View {
        VStack(spacing: 12) {
            Button(pingSent ? "Ping Sent!" : "Ping \(buddyName)") {
                Task { await sendPing(buddyName: buddyName) }
            }
            .font(.body.weight(.semibold))
            .fontDesign(.rounded)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)
            .disabled(!canPing || pingSent)
            .accessibilityLabel(pingSent
                ? "Ping sent. Available again in 24 hours."
                : "Ping \(buddyName)")
        }
    }

    // MARK: - Breathing loop

    private func runBreathingLoop() async {
        phase = .inhale
        while isActive {
            fillFraction = phase.fillTarget
            for tick in stride(from: 4, through: 1, by: -1) {
                countdown = tick
                try? await Task.sleep(for: .seconds(1))
                if !isActive { return }
            }
            phase = phase.next
        }
    }

    // MARK: - Buddy ping action

    private func sendPing(buddyName: String) async {
        await NotificationScheduler.shared.scheduleBuddyPing(
            challengeID: userChallenge.id,
            buddyDisplayName: buddyName,
            challengeTitle: challengeTitle
        )
        userChallenge.buddyPingLastSent = Date()
        try? modelContext.save()
        pingSent = true
        Task {
            try? await Task.sleep(for: .seconds(3))
            await MainActor.run { pingSent = false }
        }
    }
}
