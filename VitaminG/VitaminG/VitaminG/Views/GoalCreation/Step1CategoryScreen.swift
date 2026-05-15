import SwiftUI

struct Step1CategoryScreen: View {
    @Bindable var wizardVM: GoalCreationWizardViewModel
    var isOnboarding: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerText
                categoryGrid
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(VGTheme.sandLight.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { nextButton }
        .navigationBarBackButtonHidden(isOnboarding)
    }

    private var headerText: some View {
        VStack(alignment: .leading, spacing: 6) {
            stepDots
            Text("What kind of\ngoal is this?")
                .font(.custom("CormorantGaramond-Regular", size: 34))
                .foregroundStyle(VGTheme.clay)
                .lineSpacing(2)
            Text("Pick the vibe — we'll personalize from here.")
                .font(.subheadline)
                .foregroundStyle(VGTheme.muted)
        }
    }

    private var stepDots: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill(i == 0 ? VGTheme.terra : VGTheme.sandMid)
                    .frame(width: i == 0 ? 22 : 8, height: 8)
            }
        }
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(GoalCategory.allCases) { category in
                CategoryCard(
                    category: category,
                    isSelected: wizardVM.selectedCategory == category
                ) {
                    wizardVM.selectedCategory = category
                }
            }
        }
    }

    private var nextButton: some View {
        Button { wizardVM.currentStep = 1 } label: {
            Text("Next")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(VGTheme.terra)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
}

private struct CategoryCard: View {
    let category: GoalCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                Text(category.emoji).font(.system(size: 28))
                Text(category.rawValue)
                    .font(.custom("CormorantGaramond-Medium", size: 18))
                    .foregroundStyle(isSelected ? VGTheme.terra : VGTheme.clay)
                Text(category.subtitle)
                    .font(.caption2)
                    .foregroundStyle(VGTheme.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(isSelected ? Color.white : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18)
                .strokeBorder(isSelected ? VGTheme.terra : VGTheme.sandMid, lineWidth: 2))
            .shadow(color: isSelected ? VGTheme.terra.opacity(0.2) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}
