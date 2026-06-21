import SwiftUI

struct MoodPromptCard: View {
    @Bindable var viewModel: ExploreViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if !viewModel.hasMoodSelectedToday {
            cardContent
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header row
            HStack {
                Text("How are you feeling?")
                    .font(VGTheme.serif(18))
                    .foregroundStyle(VGTheme.textPrimary)
                Spacer()
                // Checkmark dismiss button (accessibility fallback — dismisses without selecting)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(VGTheme.accentSage)
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Dismiss mood prompt without selecting")
            }

            // Mood chip row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MoodOption.allCases) { mood in
                        Button {
                            selectMood(mood)
                        } label: {
                            HStack(spacing: 4) {
                                Text(mood.emoji)
                                    .font(.callout)
                                    .accessibilityHidden(true)
                                Text(mood.rawValue)
                                    .font(.callout.weight(.medium))
                                    .fontDesign(.rounded)
                            }
                            .foregroundStyle(VGTheme.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(VGTheme.background)
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(VGTheme.separator, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .frame(minHeight: 44)
                        .accessibilityLabel(mood.rawValue)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(18)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(VGTheme.separator, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private func selectMood(_ mood: MoodOption) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if reduceMotion {
            viewModel.selectMood(mood)
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                viewModel.selectMood(mood)
            }
        }
    }

    private func dismiss() {
        // Dismiss via checkmark button without selecting a mood — marks date gate only,
        // no mood value stored (distinguishable from a real .okay selection).
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if reduceMotion {
            viewModel.dismissMoodPrompt()
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                viewModel.dismissMoodPrompt()
            }
        }
    }
}
