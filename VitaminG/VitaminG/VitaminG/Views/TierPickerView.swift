import SwiftUI

// MARK: - TierPickerView

/// 2x2 card grid for tier selection. Replaces the .navigationLink Picker per D-11.
struct TierPickerView: View {
    @Binding var selectedTier: GoalTier

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(GoalTier.ordered) { tier in
                TierCardView(tier: tier, isSelected: selectedTier == tier)
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.15)) {
                            selectedTier = tier
                        }
                    }
                    .accessibilityLabel("\(tier.displayName), \(tier.description)")
                    .accessibilityAddTraits(selectedTier == tier ? [.isButton, .isSelected] : .isButton)
            }
        }
    }
}

// MARK: - TierCardView

private struct TierCardView: View {
    let tier: GoalTier
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: tier.icon)
                .font(.system(size: 28))
                .foregroundStyle(tier.color)
                .frame(height: 34)

            Text(tier.displayName)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            Text(tier.description)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? tier.color.opacity(0.12) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? tier.color : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
    }
}
