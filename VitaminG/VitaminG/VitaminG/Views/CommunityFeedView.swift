import SwiftUI
import SwiftData
import CloudKit

struct CommunityFeedView: View {
    let userChallenge: UserChallenge

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var viewModel = CommunityFeedViewModel()
    @State private var showCompose = false
    @State private var localReactionByPostID: [CKRecord.ID: ReactionType] = [:]

    // MARK: - Derived inputs
    private var category: String {
        userChallenge.template?.category ?? "general"
    }
    private var accentColor: Color {
        Color(hex: userChallenge.template?.accentColorHex ?? "#C4673A")
    }
    private var currentProfile: UserProfile? { profiles.first }

    private static let reporterIDKey = "com.kyleharrington.VitaminG.reporterID"
    private var reporterID: String {
        // Use the profile's SwiftData UUID as a stable per-user identifier
        if let profileID = currentProfile?.id {
            return profileID.uuidString
        }
        if let stored = UserDefaults.standard.string(forKey: Self.reporterIDKey) {
            return stored
        }
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: Self.reporterIDKey)
        return newID
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 1. Section header
                Text("Community")
                    .font(.title2.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.clay)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // 2. Compose CTA
                Button {
                    showCompose = true
                } label: {
                    Label("Share Your Progress", systemImage: "square.and.pencil")
                        .font(.body.weight(.semibold)).fontDesign(.rounded)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color(.secondarySystemGroupedBackground))
                        .foregroundStyle(VGTheme.clay)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)

                // 3. Posts or empty state
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    ProgressView().padding(.top, 32)
                        .frame(maxWidth: .infinity)
                } else if viewModel.posts.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.posts, id: \.recordID) { post in
                            CommunityPostCard(
                                post: post,
                                currentUserReaction: localReactionByPostID[post.recordID],
                                accentColor: accentColor,
                                onReact: { type in handleReact(post: post, type: type) },
                                onReport: { Task { await handleReport(post: post) } }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 32)
        }
        .background(VGTheme.sandLight)
        .navigationTitle("Community")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Pre-warm ProfanityFilter word list (access from main actor context is fine —
            // it's a static lazy initializer that executes once)
            _ = ProfanityFilter.blockedWords
            await viewModel.loadPosts(category: category)
        }
        .sheet(isPresented: $showCompose) {
            PostComposeSheet(
                category: category,
                accentColor: accentColor,
                authorDisplayName: currentProfile?.displayName,
                authorColorHex: currentProfile?.avatarColorHex,
                viewModel: viewModel
            )
        }
        .alert(CommunityFeedViewModel.reactionSaveFailureMessage,
               isPresented: Binding(
                get: { viewModel.reactionError != nil },
                set: { if !$0 { viewModel.reactionError = nil } }
               )) {
            Button("OK", role: .none) {}
        }
    }

    // MARK: - Empty state (CHAL-25)
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundStyle(VGTheme.muted)
            Text("Be the First to Share")
                .font(.title2.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.clay)
            Text("Be the first to share your progress! Your post can encourage others on the same journey.")
                .font(.body)
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.vertical, 32)
    }

    // MARK: - Reaction handler (optimistic + mutual exclusion)
    private func handleReact(post: CKRecord, type: ReactionType) {
        let prior = localReactionByPostID[post.recordID]
        // Optimistic UI: mutual exclusion — picking one reaction removes the other
        if prior == type {
            localReactionByPostID[post.recordID] = nil
        } else {
            localReactionByPostID[post.recordID] = type
        }
        Task {
            _ = await viewModel.toggleReaction(
                recordID: post.recordID,
                reactionType: type,
                add: localReactionByPostID[post.recordID] == type
            )
        }
    }

    // MARK: - Report handler (silent removal at threshold)
    private func handleReport(post: CKRecord) async {
        let count = await viewModel.reportPost(recordID: post.recordID, reporterID: reporterID)
        // Hide locally — UI-SPEC: silent removal, no success alert
        withAnimation(.easeOut(duration: 0.25)) {
            viewModel.posts.removeAll { $0.recordID == post.recordID }
        }
        #if DEBUG
        print("[CommunityFeedView] reportPost recordID=\(post.recordID.recordName) newCount=\(count)")
        #endif
    }
}
