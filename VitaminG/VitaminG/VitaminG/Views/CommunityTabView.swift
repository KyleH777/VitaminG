import SwiftUI
import SwiftData

// MARK: - CommunityTabView
// 5-section social hub for Phase 21 (COMM-01 through COMM-07, SOC-01 through SOC-03).
//
// Section order per UI-SPEC §Section Layout Order:
// 1. "Community" heading
// 2. COMM-01 goal card (enrolled → CommunityGoalsLandingView; none → "Join a community goal" fallback)
// 3. "TODAY'S GLIMPSES" label + GlimpsesCarouselSection
// 4. "ACTIVE TODAY" label + ActiveTodaySection
// 5. GlowingSpotlightSection (self-labeled "GLOWING THIS WEEK" inside the card)
// 6. "COMMUNITY FEED" label + GlobalFeedSection
//
// CommunitySegment enum and Feed/Ideas Picker removed per D-06.
// ChallengeDiscoveryView and IdeaBoardView are now in ExploreView (D-06).
//
// Security: writeUserPresence writes sanitized username + colorHex only (T-21-06-05).
// InputSanitizer applied at the CommunityService write layer.

struct CommunityTabView: View {

    // MARK: - Properties

    @Binding var selectedTab: AppTab

    // MARK: - State / Environment

    @State private var viewModel = CommunityHubViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router

    // MARK: - Queries

    @Query(filter: #Predicate<UserChallenge> { $0.statusRaw == "active" })
    private var activeChallenges: [UserChallenge]

    @Query private var profiles: [UserProfile]

    // MARK: - Computed

    private var currentUsername: String { profiles.first?.displayName ?? "" }
    private var currentColorHex: String { profiles.first?.avatarColorHex ?? "" }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                communityHeading
                goalCard
                glimpsesSection
                activeTodaySection
                glowingSection
                feedSection
            }
            .padding(.bottom, 24)
        }
        .background(VGTheme.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarHidden(true)
        .task {
            await viewModel.loadAll(username: currentUsername)
        }
        .onAppear {
            Task {
                await CommunityService.writeUserPresence(
                    username: currentUsername,
                    authorColorHex: currentColorHex
                )
            }
        }
        .refreshable {
            await viewModel.loadAll(username: currentUsername)
        }
    }

    // MARK: - Community Heading

    private var communityHeading: some View {
        Text("Community")
            .font(VGTheme.serif(28))
            .foregroundStyle(VGTheme.textPrimary)
            .padding(.top, 20)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: - COMM-01 Goal Card

    private var goalCard: some View {
        Group {
            if let challenge = activeChallenges.first {
                enrolledGoalCard(challenge: challenge)
            } else {
                fallbackGoalCard
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    /// Card shown when the user is enrolled in an active community challenge.
    private func enrolledGoalCard(challenge: UserChallenge) -> some View {
        let progress: Double = {
            let checkIns = Double(challenge.totalCheckIns)
            let duration = Double(max(1, challenge.template?.durationDays ?? 90))
            return min(1.0, checkIns / duration)
        }()
        let participants = challenge.template?.communitySize ?? 0
        let daysLeft: Int = {
            let start = challenge.startDate ?? Date()
            let currentDay = (Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0) + 1
            return max(0, (challenge.template?.durationDays ?? 90) - currentDay)
        }()

        return NavigationLink(destination: CommunityGoalsLandingView(userChallenge: challenge)) {
            HStack(spacing: 16) {
                ProgressRingView(
                    progress: progress,
                    tier: .longTerm,
                    isCompleted: false,
                    size: 56,
                    strokeWidth: 4,
                    glow: false
                )
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.template?.title ?? "Community Goal")
                        .font(.callout.weight(.semibold))
                        .fontDesign(.rounded)
                        .foregroundStyle(VGTheme.textPrimary)
                        .lineLimit(1)
                    Text("\(participants) members · \(daysLeft) days left")
                        .font(.callout)
                        .fontDesign(.rounded)
                        .foregroundStyle(VGTheme.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.callout)
                    .foregroundStyle(VGTheme.textMuted)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .background(VGTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Community goal: \(challenge.template?.title ?? ""). \(participants) members, \(daysLeft) days left. Tap to view.")
    }

    /// Fallback card shown when the user has no active community challenge.
    private var fallbackGoalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Join a community goal")
                .font(.body.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.textPrimary)
            Text("Check in with thousands of others working toward something meaningful.")
                .font(.callout)
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.textMuted)
            Button {
                selectedTab = .explore
            } label: {
                Text("Explore Goals")
                    .font(.callout.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(VGTheme.terra)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel("No active community goal. Tap Explore Goals to find one.")
    }

    // MARK: - TODAY'S GLIMPSES Section

    private var glimpsesSection: some View {
        @Bindable var router = router
        return VStack(alignment: .leading, spacing: 0) {
            Text("TODAY'S GLIMPSES")
                .font(.title3.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 8)
                .accessibilityAddTraits(.isHeader)

            GlimpsesCarouselSection(
                glimpses: viewModel.glimpses,
                giverUsername: currentUsername,
                canApplaud: { viewModel.canApplaud(recipientUsername: $0) },
                onApplaud: { recipient in
                    Task {
                        await viewModel.writeApplauseForUser(
                            recipientUsername: recipient,
                            giverUsername: currentUsername
                        )
                    }
                },
                onTapCard: { glimpse in
                    router.pendingPublicProfileRecordID = glimpse.username
                }
            )
        }
    }

    // MARK: - ACTIVE TODAY Section

    private var activeTodaySection: some View {
        @Bindable var router = router
        return VStack(alignment: .leading, spacing: 0) {
            Text("ACTIVE TODAY")
                .font(.title3.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 8)
                .accessibilityAddTraits(.isHeader)

            ActiveTodaySection(
                activeUsers: viewModel.activeUsers,
                onTapUser: { user in
                    router.pendingPublicProfileRecordID = user.username
                }
            )
        }
    }

    // MARK: - Glowing Spotlight Section (self-labeled inside card)

    private var glowingSection: some View {
        @Bindable var router = router
        return GlowingSpotlightSection(
            glowingUser: viewModel.glowingUser,
            giverUsername: currentUsername,
            canApplaud: { viewModel.canApplaud(recipientUsername: $0) },
            onApplaud: { recipient in
                Task {
                    await viewModel.writeApplauseForUser(
                        recipientUsername: recipient,
                        giverUsername: currentUsername
                    )
                }
            },
            onTapUser: { glimpse in
                router.pendingPublicProfileRecordID = glimpse.username
            }
        )
        .padding(.top, 24)
    }

    // MARK: - COMMUNITY FEED Section

    private var feedSection: some View {
        @Bindable var viewModel = viewModel
        return VStack(alignment: .leading, spacing: 0) {
            Text("COMMUNITY FEED")
                .font(.title3.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 8)
                .accessibilityAddTraits(.isHeader)

            GlobalFeedSection(
                feedPosts: viewModel.feedPosts,
                isLoading: viewModel.isLoading,
                loadError: viewModel.loadError,
                viewModel: viewModel,
                authorDisplayName: currentUsername.isEmpty ? nil : currentUsername,
                authorColorHex: currentColorHex.isEmpty ? nil : currentColorHex
            )
        }
    }
}
