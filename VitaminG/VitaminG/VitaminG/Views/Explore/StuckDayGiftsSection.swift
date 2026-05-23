import SwiftUI
import SwiftData

/// Three curated easy-win goals seeded by day-of-year. Tapping "Add" inserts the goal
/// and hides the card for the rest of the day.
struct StuckDayGiftsSection: View {
    @Bindable var viewModel: ExploreViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var goalVM = GoalViewModel()

    /// Today's 3 gifts. Derived once — stable for the lifetime of this view.
    private let todaysGifts: [StuckDayGift] = ExploreContent.todaysStuckDayGifts

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let visibleGifts = todaysGifts.filter { !viewModel.isStuckGiftHidden(for: $0) }

            if visibleGifts.isEmpty {
                Text("You've added all today's gifts. Nice work!")
                    .font(.system(size: 14))
                    .foregroundStyle(VGTheme.textMuted)
                    .padding(.horizontal, 16)
            } else {
                VStack(spacing: 8) {
                    ForEach(visibleGifts) { gift in
                        giftRow(gift)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func giftRow(_ gift: StuckDayGift) -> some View {
        HStack(spacing: 12) {
            Text(gift.emoji)
                .font(.system(size: 24))
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(gift.title)
                    .font(.system(size: 14, weight: .medium))
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.textPrimary)
                    .lineLimit(2)
                Text(gift.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(VGTheme.textMuted)
            }

            Spacer()

            Button {
                addStuckDayGift(gift)
            } label: {
                Text("+ ADD")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(VGTheme.accentTerra)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(VGTheme.accentTerra.opacity(0.12))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add \(gift.title) to my goals")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(VGTheme.separator, lineWidth: 1)
        )
    }

    private func addStuckDayGift(_ gift: StuckDayGift) {
        let input = GoalInput(
            title: gift.title,
            tier: .immediate,
            category: gift.category,
            frequency: .daily,
            reminderTime: nil,
            isPrivate: true,
            startDate: Date()
        )
        try? goalVM.addGoal(input: input, context: modelContext)
        viewModel.markStuckGiftHidden(gift)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
