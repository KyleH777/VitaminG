import SwiftUI
import SwiftData

// MARK: - DiscoverOverlayView
// Shown inside ExploreView when the search bar is active and non-empty.
// Provides a segmented Picker (Goals/People) with result cards below.
// MVVM: all service calls are routed through DiscoverViewModel — this view
// MUST NOT call ProfileSharingService.writeFollow directly (CLAUDE.md MVVM rule).
// Analog: CommunityTabView.swift (top-level view with @State viewModel + section headers).

struct DiscoverOverlayView: View {

    let searchText: String
    @Bindable var viewModel: DiscoverViewModel

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Local State

    /// Goal result for which the tier-picker confirmationDialog is presented.
    @State private var presentingTierPickerFor: DiscoverGoalResult? = nil

    /// Person result for which PublicProfileView is presented as a sheet.
    @State private var presentingProfileFor: DiscoverPersonResult? = nil

    @AppStorage("vg_username") private var myUsername: String = ""

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Segment Picker (UI-SPEC §DiscoverView, D-03)
            Picker("Search type", selection: $viewModel.selectedSegment) {
                Text("Goals").tag(SearchSegment.goals)
                Text("People").tag(SearchSegment.people)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .onChange(of: viewModel.selectedSegment) { _, _ in
                viewModel.setSegment(viewModel.selectedSegment, searchText: searchText)
            }

            // MARK: Results List
            ScrollView {
                LazyVStack(spacing: 8) {
                    if viewModel.isSearching {
                        // Loading state
                        ProgressView()
                            .tint(VGTheme.accentTerra)
                            .padding(.top, 24)
                    } else if let err = viewModel.searchError {
                        // Error state
                        VStack(spacing: 8) {
                            Text(err)
                                .font(.body)
                                .foregroundStyle(VGTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(24)
                        }
                        .accessibilityLiveRegion(.polite)
                    } else if viewModel.selectedSegment == .goals {
                        if viewModel.goalResults.isEmpty {
                            // Goals empty state (UI-SPEC §Empty States)
                            emptyStateView(
                                heading: "No goals found",
                                body: "Try a different keyword."
                            )
                        } else {
                            ForEach(viewModel.goalResults) { result in
                                GoalSearchResultCard(
                                    result: result,
                                    isJoined: viewModel.isJoined(goalID: result.id),
                                    onJoin: { presentingTierPickerFor = result }
                                )
                            }
                        }
                    } else {
                        if viewModel.peopleResults.isEmpty {
                            // People empty state (UI-SPEC §Empty States)
                            emptyStateView(
                                heading: "No people found",
                                body: "Try searching by username."
                            )
                        } else {
                            ForEach(viewModel.peopleResults) { result in
                                PeopleSearchResultCard(
                                    result: result,
                                    // MVP NOTE: per-row follow state freshness deferred to a future
                                    // phase — all rows start .idle. Authoritative state visible when
                                    // user opens PublicProfileView from the card tap (T-22-05-07 accept).
                                    followState: .idle,
                                    onFollow: {
                                        // MVVM seam: never call ProfileSharingService.writeFollow
                                        // directly from a View (CLAUDE.md MVVM rule, T-22-05-07a).
                                        viewModel.onFollowPerson(
                                            followerUsername: myUsername,
                                            followeeUsername: result.username
                                        )
                                    },
                                    onTap: {
                                        presentingProfileFor = result
                                    }
                                )
                            }
                        }
                    }
                }
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.selectedSegment)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .background(VGTheme.background.ignoresSafeArea())

        // MARK: Tier Picker (confirmationDialog — T-22-05-03: closed GoalTier.allCases set)
        .confirmationDialog(
            "Which type of goal is this for you?",
            isPresented: Binding(
                get: { presentingTierPickerFor != nil },
                set: { if !$0 { presentingTierPickerFor = nil } }
            ),
            titleVisibility: .visible
        ) {
            ForEach(GoalTier.allCases, id: \.self) { tier in
                Button(tier.displayName) {
                    if let result = presentingTierPickerFor {
                        viewModel.joinGoal(result, tier: tier, context: modelContext)
                    }
                    presentingTierPickerFor = nil
                }
            }
            Button("Cancel", role: .cancel) {
                presentingTierPickerFor = nil
            }
        }

        // MARK: Profile Sheet (PeopleSearchResultCard tap → PublicProfileView)
        // T-22-05-04: recordID passed is result.id (CKRecord.recordID.recordName — CloudKit identity)
        .sheet(item: $presentingProfileFor) { person in
            PublicProfileView(recordID: person.id)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func emptyStateView(heading: String, body: String) -> some View {
        VStack(spacing: 8) {
            Text(heading)
                .font(.body.weight(.semibold))
                .foregroundStyle(VGTheme.textPrimary)
            Text(body)
                .font(.body)
                .foregroundStyle(VGTheme.textSecondary)
        }
        .padding(24)
    }
}
