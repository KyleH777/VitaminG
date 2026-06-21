import SwiftUI

// MARK: - MotivationCategoryScreen
// Onboarding Screen 3: Goal category picker.
// Users tap to select what they want to grow — stored for notification personalization.

struct MotivationCategoryScreen: View {

    @Binding var path: [OnboardingStep]
    let onSkip: () -> Void

    @AppStorage("vg_selectedCategories") private var storedCategories: String = ""
    @State private var selected: Set<Int> = []

    private let categories: [(label: String, icon: String)] = [
        ("Health & Fitness", "◎"),
        ("Mindfulness", "◇"),
        ("Career", "△"),
        ("Relationships", "◈"),
        ("Learning", "◉"),
        ("Nutrition", "◑"),
        ("Creativity", "◐"),
        ("Morning Habits", "☀"),
    ]

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack(alignment: .bottom) {
            VGTheme.sandLight
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Nav row
                HStack {
                    Button(action: { path.removeLast() }) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.medium))
                            .foregroundStyle(VGTheme.clay)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Go back")
                    Spacer()
                }
                .padding(.bottom, 20)

                StepBarView(current: 1, total: 4)
                    .padding(.bottom, 28)

                Text("What do you\nwant to grow?")
                    .font(Font.custom("Georgia", size: 42))
                    .foregroundStyle(VGTheme.clay)
                    .lineSpacing(4)
                    .padding(.bottom, 10)
                    .accessibilityAddTraits(.isHeader)

                Text("Pick what matters most to you right now.")
                    .font(.callout.weight(.light))
                    .foregroundStyle(VGTheme.muted)
                    .padding(.bottom, 24)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(categories.indices, id: \.self) { i in
                        let on = selected.contains(i)
                        Button {
                            if on { selected.remove(i) } else { selected.insert(i) }
                        } label: {
                            HStack(spacing: 10) {
                                Text(categories[i].icon)
                                    .font(.body)
                                    .foregroundStyle(on ? VGTheme.terra : VGTheme.muted)
                                    .accessibilityHidden(true)

                                Text(categories[i].label)
                                    .font(.callout.weight(on ? .semibold : .regular))
                                    .foregroundStyle(on ? VGTheme.clay : VGTheme.muted)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.85)
                                    .multilineTextAlignment(.leading)

                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(on ? VGTheme.terraLight : VGTheme.warmWhite)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(on ? VGTheme.terra : VGTheme.sandMid, lineWidth: 2)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.15), value: on)
                        .accessibilityAddTraits(on ? [.isSelected] : [])
                        .accessibilityLabel(categories[i].label)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)

            VStack(spacing: 0) {
                Button(action: advance) {
                    Text("Continue")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding(.vertical, 18)
                        .background(selected.isEmpty ? VGTheme.sandMid : VGTheme.terra)
                        .foregroundStyle(selected.isEmpty ? VGTheme.sandDeep : VGTheme.warmWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(selected.isEmpty)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 36)
        }
        .navigationBarHidden(true)
    }

    private func advance() {
        storedCategories = selected.sorted().map { categories[$0].label }.joined(separator: ",")
        path.append(.notifications)
    }
}
