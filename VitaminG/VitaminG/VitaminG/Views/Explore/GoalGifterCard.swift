import SwiftUI
import SwiftData

struct GoalGifterCard: View {
    @Bindable var viewModel: ExploreViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var goalVM = GoalViewModel()
    @State private var showingConfetti = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header row: pill icon + title
            HStack(alignment: .center, spacing: 12) {
                VGCapsule(size: 48, color1: VGTheme.terraSoft, color2: VGTheme.terra)
                    .rotationEffect(.degrees(viewModel.isDispensing ? 15 : 0))
                    .animation(
                        reduceMotion ? nil : .interpolatingSpring(stiffness: 300, damping: 10),
                        value: viewModel.isDispensing
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("Shake out some growth")
                        .font(VGTheme.serif(20))
                        .foregroundStyle(VGTheme.textPrimary)
                    Text("One daily goal, just for you")
                        .font(.system(size: 14))
                        .foregroundStyle(VGTheme.textMuted)
                }
            }

            // State: already gifted today
            if viewModel.hasGiftedToday {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(VGTheme.accentSage)
                        .font(.system(size: 20))
                    Text("Come back tomorrow")
                        .font(.system(size: 15))
                        .foregroundStyle(VGTheme.textMuted)
                }
            }
            // State: goal dispensed, waiting for user to add
            else if let goal = viewModel.dispensedGoal {
                VStack(alignment: .leading, spacing: 10) {
                    Text(goal.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(VGTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        addGiftedGoal(goal)
                    } label: {
                        Text("Add this goal")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(VGTheme.accentTerra)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            // State: not yet activated
            else {
                Button {
                    activateGifter()
                } label: {
                    Text("Surprise me")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(VGTheme.accentTerra)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Surprise me — tap to receive today's goal")
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [VGTheme.accentTerra.opacity(0.12), VGTheme.accentTerra.opacity(0.04)],
                startPoint: .top, endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(VGTheme.accentTerra.opacity(0.2), lineWidth: 1))
        .padding(.horizontal, 16)
        // DragGesture triggers gifter (VitaminDispenserView pattern)
        .gesture(DragGesture(minimumDistance: 10).onEnded { _ in activateGifter() })
        .overlay {
            if showingConfetti {
                ExploreConfettiOverlay(onDismiss: { showingConfetti = false })
                    .transition(.opacity)
            }
        }
    }

    private func activateGifter() {
        guard viewModel.onGifterActivated() != nil else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func addGiftedGoal(_ gift: GifterGoal) {
        let input = GoalInput(
            title: gift.title,
            tier: .immediate,
            category: gift.category,
            frequency: .daily,
            reminderTime: nil,
            isPrivate: true,
            startDate: Date()
        )
        if let inserted = try? goalVM.addGoal(input: input, context: modelContext) {
            inserted.associatedInspiration = "vg_gifter"
            viewModel.markGiftedToday()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation { showingConfetti = true }
        }
    }
}
