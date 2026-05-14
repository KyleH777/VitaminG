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
    @Query private var templates: [ChallengeTemplate]
    @Query private var userChallenges: [UserChallenge]
    @State private var showBuildYourOwn = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                featuredSection
                categorySection
                buildYourOwnButton
            }
            .padding(.horizontal, 16)
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

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse by Category")
                .font(.title2)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(["Fitness", "Finance", "Sobriety"], id: \.self) { category in
                        Text(category)
                            .font(.body)
                            .fontDesign(.rounded)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(Capsule())
                            .foregroundStyle(VGTheme.textPrimary)
                    }
                }
                .padding(.horizontal, 2)
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
