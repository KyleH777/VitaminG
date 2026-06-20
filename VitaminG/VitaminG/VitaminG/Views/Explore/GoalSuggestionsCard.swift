import SwiftUI
import SwiftData

struct GoalSuggestionsCard: View {
    @Bindable var aiViewModel: AIViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var goalVM = GoalViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header row: sparkles icon + title + subtitle
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(VGTheme.accentTerra)
                    .frame(width: 48, height: 48)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Goals suggested for you")
                        .font(VGTheme.serif(20))
                        .foregroundStyle(VGTheme.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text("Based on your goals and interests")
                        .font(.callout)
                        .foregroundStyle(VGTheme.textMuted)
                }
            }

            // Suggestion rows
            VStack(spacing: 0) {
                ForEach(Array(aiViewModel.suggestions.enumerated()), id: \.offset) { index, suggestion in
                    let isAdded = aiViewModel.addedSuggestionIndices.contains(index)

                    HStack(alignment: .center, spacing: 8) {
                        Text(suggestion)
                            .font(.body)
                            .foregroundStyle(isAdded ? VGTheme.textMuted : VGTheme.textPrimary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .redacted(reason: aiViewModel.isLoadingSuggestions ? .placeholder : [])

                        if isAdded {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(VGTheme.accentSage)
                                .frame(minWidth: 44, minHeight: 44)
                                .accessibilityLabel("Added")
                        } else {
                            Button {
                                addSuggestion(title: suggestion, at: index)
                            } label: {
                                Text("Add Goal")
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(VGTheme.accentTerra)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .frame(minHeight: 44)
                            .disabled(aiViewModel.isLoadingSuggestions)
                            .accessibilityLabel("Add goal: \(suggestion)")
                        }
                    }
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())

                    if index < aiViewModel.suggestions.count - 1 {
                        Divider()
                            .foregroundStyle(VGTheme.separator)
                    }
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [VGTheme.accentTerra.opacity(0.12), VGTheme.accentTerra.opacity(0.04)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(VGTheme.accentTerra.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Goals suggested for you, \(aiViewModel.suggestions.count) suggestions")
    }

    private func addSuggestion(title: String, at index: Int) {
        let input = GoalInput(
            title: title,
            tier: .immediate,       // QuickWin = .immediate per D-05; Anti-pattern 6: do NOT create a new case
            category: .other,       // AI suggestions have no explicit category (A2)
            frequency: .daily,
            reminderTime: nil,
            isPrivate: true,
            startDate: Date()
        )
        if (try? goalVM.addGoal(input: input, context: modelContext)) != nil {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.easeInOut(duration: 0.2)) {
                aiViewModel.addedSuggestionIndices.insert(index)
            }
        }
    }
}
