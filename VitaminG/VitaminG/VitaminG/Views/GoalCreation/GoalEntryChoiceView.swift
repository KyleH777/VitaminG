import SwiftUI

struct GoalEntryChoiceView: View {
    @Environment(\.dismiss) private var dismiss

    /// Called when the user selects "Already have a goal" (step 1) or "Build my own goal" (step 0).
    let onSelectWizard: (Int) -> Void
    /// Called when the user taps a premade goal from PremadeGoalsListView.
    let onSelectPremade: (String, GoalCategory) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Card 1 — Need ideas: navigates into PremadeGoalsListView push
                    NavigationLink {
                        PremadeGoalsListView { title, category in
                            onSelectPremade(title, category)
                            dismiss()
                        }
                    } label: {
                        pathCard(
                            icon: "lightbulb.fill",
                            title: "Need ideas",
                            subtitle: "Browse pre-made goals by category"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Need ideas")
                    .accessibilityHint("Browse pre-made goals by category")

                    // Card 2 — Already have a goal: wizard at step 1
                    Button {
                        onSelectWizard(1)
                        dismiss()
                    } label: {
                        pathCard(
                            icon: "pencil",
                            title: "Already have a goal",
                            subtitle: "Jump straight in — fill in what you know"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Already have a goal")
                    .accessibilityHint("Jump straight in and fill in what you know")

                    // Card 3 — Build my own goal: wizard at step 0
                    Button {
                        onSelectWizard(0)
                        dismiss()
                    } label: {
                        pathCard(
                            icon: "wand.and.stars",
                            title: "Build my own goal",
                            subtitle: "Step-by-step: category, name, schedule"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Build my own goal")
                    .accessibilityHint("Step-by-step: choose category, name, and schedule")
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(VGTheme.sandLight.ignoresSafeArea())
            .navigationTitle("Start your goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Path Card

    private func pathCard(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            // Icon tile
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(VGTheme.accentTerra.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(VGTheme.accentTerra)
                    .accessibilityHidden(true)
            }

            // Title + subtitle
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(VGTheme.serif(18))
                    .foregroundStyle(VGTheme.textPrimary)
                    .multilineTextAlignment(.leading)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(VGTheme.textMuted)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(VGTheme.textMuted)
                .accessibilityHidden(true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(VGTheme.separator, lineWidth: 1)
        )
    }
}
