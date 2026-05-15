import SwiftUI
import SwiftData

// MARK: - ChallengeDiscoveryView

/// Root view for the Challenges tab (CHAL-08, D-04, CHAL-23).
///
/// Shows Featured Challenges seeded from ChallengeTemplate.featuredTemplates,
/// a horizontal category browse row, and a "Build Your Own" CTA that opens
/// CustomChallengeBuilderView (Plan 14-09) as a sheet.
///
/// Navigation: tapping a joined challenge card pushes ChallengeDetailView via
/// NavigationLink(value: AppRoute.challengeDetail(userChallenge)).
struct ChallengeDiscoveryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ChallengeViewModel()
    @State private var goalVM = GoalViewModel()
    @Query private var templates: [ChallengeTemplate]
    @Query private var userChallenges: [UserChallenge]
    @State private var showBuildYourOwn = false
    @State private var searchText = ""

    private let catalogue = ChallengeLibrary.categories
    private var filtered: [GoalCategorySection] {
        guard !searchText.isEmpty else { return catalogue }
        return catalogue.compactMap { section in
            let goals = section.goals.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
            return goals.isEmpty ? nil : GoalCategorySection(
                name: section.name, icon: section.icon,
                colorToken: section.colorToken, goals: goals)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                featuredSection
                catalogueSection
                buildYourOwnButton
            }
            .padding(.top, 8)
        }
        .background(VGTheme.background)
        .navigationTitle("Challenges")
        .onAppear {
            viewModel.seedFeaturedTemplates(context: modelContext)
        }
        .sheet(isPresented: $showBuildYourOwn) {
            CustomChallengeBuilderView()
        }
    }

    // MARK: - Featured Section

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured Challenges")
                .font(.title2)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.textPrimary)

            if templates.filter({ $0.isFeatured }).isEmpty {
                emptyFeaturedState
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(templates.filter { $0.isFeatured }, id: \.id) { template in
                        ChallengeCardView(
                            template: template,
                            userChallenge: userChallenges.first { $0.template?.id == template.id },
                            onJoin: { joinChallenge(template) }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Catalogue Section

    private var catalogueSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14)).foregroundStyle(VGTheme.textFaint)
                TextField("Search goals…", text: $searchText)
                    .font(.system(size: 13.5))
                    .foregroundStyle(VGTheme.textPrimary)
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(VGTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(VGTheme.separator, lineWidth: 1))
            .padding(.horizontal, 16)

            // 12-category list
            ForEach(filtered) { section in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text(section.icon).font(.system(size: 14))
                            .foregroundStyle(VGTheme.accentTerra)
                        Text(section.name.uppercased())
                            .font(.system(size: 10, weight: .semibold)).kerning(1.2)
                            .foregroundStyle(VGTheme.textMuted)
                    }
                    .padding(.horizontal, 16)

                    ForEach(section.goals) { goal in
                        HStack(spacing: 12) {
                            Circle().fill(VGTheme.accentTerra).frame(width: 7, height: 7)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(goal.title).font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(VGTheme.textPrimary)
                                HStack(spacing: 8) {
                                    Text(goal.duration).font(.system(size: 11)).foregroundStyle(VGTheme.textMuted)
                                    Text(goal.level)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(goal.level == "Easy" ? VGTheme.accentSage : VGTheme.accentGold)
                                }
                            }
                            Spacer()
                            Button("+ Add") {
                                let input = GoalInput(title: goal.title, tier: .immediate,
                                                     category: .habit, frequency: .daily,
                                                     reminderTime: nil, isPrivate: false, startDate: nil)
                                try? goalVM.addGoal(input: input, context: modelContext)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(VGTheme.accentTerra)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(VGTheme.accentTerra.opacity(0.12))
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(VGTheme.accentTerra.opacity(0.3), lineWidth: 1))
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background(VGTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(VGTheme.separator, lineWidth: 1))
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 14)
            }
        }
    }

    // MARK: - Build Your Own Button

    private var buildYourOwnButton: some View {
        Button("Build Your Own") {
            showBuildYourOwn = true
        }
        .font(.body)
        .fontWeight(.semibold)
        .fontDesign(.rounded)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(Color(.secondarySystemGroupedBackground))
        .foregroundStyle(VGTheme.textPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel("Build Your Own Challenge")
    }

    // MARK: - Empty State

    private var emptyFeaturedState: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 48))
                .foregroundStyle(VGTheme.textMuted)
            Text("No Challenges Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.textPrimary)
            Text("Featured challenges are coming soon. Check back to find your next goal.")
                .font(.body)
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Actions

    private func joinChallenge(_ template: ChallengeTemplate) {
        viewModel.joinChallenge(template: template, context: modelContext)
    }
}

// MARK: - ChallengeCardView

/// Card row displayed in the Featured Challenges section.
/// Shows template icon, title, description, community size, and a Join/View Progress button.
/// Used exclusively within ChallengeDiscoveryView.
private struct ChallengeCardView: View {
    let template: ChallengeTemplate
    let userChallenge: UserChallenge?
    let onJoin: () -> Void

    private var accentColor: Color {
        Color(hex: template.accentColorHex ?? "#C4673A")
    }

    private var isJoined: Bool { userChallenge != nil }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: template.iconName ?? "flame.fill")
                .font(.system(size: 32))
                .foregroundStyle(accentColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(template.title ?? "Challenge")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.textPrimary)
                Text(template.challengeDescription ?? "")
                    .font(.body)
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.textMuted)
                    .lineLimit(1)
                if template.communitySize > 0 {
                    Text("\(template.communitySize.formatted()) people")
                        .font(.caption)
                        .fontDesign(.rounded)
                        .foregroundStyle(VGTheme.textMuted)
                }
            }
            Spacer()

            if isJoined {
                if let challenge = userChallenge {
                    NavigationLink(value: AppRoute.challengeDetail(challenge)) {
                        Text("View Progress")
                            .font(.body)
                            .fontWeight(.semibold)
                            .fontDesign(.rounded)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(VGTheme.textPrimary)
                    }
                    .accessibilityLabel("View progress for \(template.title ?? "challenge")")
                }
            } else {
                Button {
                    onJoin()
                } label: {
                    Text("Join Challenge")
                        .font(.body)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)
                }
                .frame(minHeight: 44)
                .accessibilityLabel("Join \(template.title ?? "challenge")")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
