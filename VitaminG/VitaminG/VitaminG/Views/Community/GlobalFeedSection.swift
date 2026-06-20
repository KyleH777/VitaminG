import SwiftUI
import CloudKit

// MARK: - GlobalFeedSection
// Global community feed section (COMM-06 / COMM-07).
//
// LazyVStack of CommunityPostCard with optimistic mutual-exclusion reaction toggling.
// Reply button opens CommunityReplySheetView (not legacy CommentSheetView — D-08 / COMM-06).
// Compose CTA opens PostComposeSheet for global posts (no challenge category).
//
// Optimistic reaction pattern: localReactionByPostID mirrors CommunityFeedView.handleReact.
// Prior reaction decremented first when switching types to keep server counts consistent.
//
// Security (T-21-05-01): CKRecord fields rendered via SwiftUI Text() — no code execution
// surface. InputSanitizer applied at write time in CommunityService.createPost.

struct GlobalFeedSection: View {

    // MARK: - Properties

    let feedPosts: [CKRecord]
    let isLoading: Bool
    let loadError: String?
    @Bindable var viewModel: CommunityHubViewModel
    let authorDisplayName: String?
    let authorColorHex: String?

    // MARK: - Report helper

    // Stored let initialised exactly once per view instance via a self-executing closure.
    // Using a computed var caused a race: two concurrent accesses in the same render cycle
    // could each read nil from defaults before the first write propagated, generating two
    // distinct reporter IDs for the same installation.
    private let reporterID: String = {
        let key = "com.kyleharrington.VitaminG.reporterID"
        if let stored = UserDefaults.standard.string(forKey: key) { return stored }
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: key)
        return newID
    }()

    // MARK: - State

    @State private var localReactionByPostID: [CKRecord.ID: ReactionType] = [:]
    @State private var showReplySheet: Bool = false
    @State private var activeReplyPostID: String = ""
    @State private var showCompose: Bool = false

    // Local CommunityFeedViewModel for compose sheet (global feed — no challenge category)
    @State private var composeFeedViewModel = CommunityFeedViewModel()

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Compose CTA button (always shown — per UI-SPEC §Interaction States)
            composeButton

            // Feed content
            if isLoading && feedPosts.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 32)
            } else if let errorMsg = loadError, feedPosts.isEmpty {
                Text(errorMsg)
                    .font(.body)
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
            } else if feedPosts.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(feedPosts, id: \.recordID) { post in
                        // MILE-05: Render StreakAchievementCard for achievement posts;
                        // regular CommunityPostCard for all other posts.
                        if (post["isAchievementPost"] as? Int) == 1 {
                            StreakAchievementCard(record: post)
                        } else {
                            CommunityPostCard(
                                post: post,
                                currentUserReaction: localReactionByPostID[post.recordID],
                                accentColor: VGTheme.accentTerra,
                                onReact: { type in handleReact(post: post, type: type) },
                                onReport: {
                                    Task { await handleReport(post: post) }
                                },
                                onComment: {
                                    activeReplyPostID = post.recordID.recordName
                                    showReplySheet = true
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .sheet(isPresented: $showReplySheet) {
            CommunityReplySheetView(
                parentPostID: activeReplyPostID,
                authorDisplayName: authorDisplayName,
                authorColorHex: authorColorHex,
                onWriteReply: { text in
                    await viewModel.writeReply(
                        parentPostID: activeReplyPostID,
                        text: text,
                        authorDisplayName: authorDisplayName,
                        authorColorHex: authorColorHex
                    )
                }
            )
        }
        .sheet(isPresented: $showCompose) {
            PostComposeSheet(
                category: "community",
                accentColor: VGTheme.accentTerra,
                authorDisplayName: authorDisplayName,
                authorColorHex: authorColorHex,
                viewModel: composeFeedViewModel
            )
        }
    }

    // MARK: - Compose CTA (UI-SPEC §Copywriting: "Share a moment")

    private var composeButton: some View {
        Button {
            showCompose = true
        } label: {
            Label("Share a moment", systemImage: "square.and.pencil")
                .font(.body.weight(.semibold))
                .fontDesign(.rounded)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color(.secondarySystemGroupedBackground))
                .foregroundStyle(VGTheme.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .accessibilityLabel("Share a moment")
    }

    // MARK: - Empty state (UI-SPEC §Copywriting)

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("Community is quiet right now")
                .font(.body.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.textPrimary)
            Text("Be the first to share today.")
                .font(.body)
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
    }

    // MARK: - Reaction handler (optimistic + mutual exclusion, mirrors CommunityFeedView)

    private func handleReact(post: CKRecord, type: ReactionType) {
        let prior = localReactionByPostID[post.recordID]
        // Optimistic UI: mutual exclusion — picking one reaction removes the other
        if prior == type {
            localReactionByPostID[post.recordID] = nil
        } else {
            localReactionByPostID[post.recordID] = type
        }
        Task {
            // If switching reaction types, decrement the prior one first to keep
            // server counts consistent — only calling the new type would over-count
            if let prior, prior != type {
                _ = await viewModel.toggleReaction(
                    recordID: post.recordID,
                    reactionType: prior,
                    add: false
                )
            }
            _ = await viewModel.toggleReaction(
                recordID: post.recordID,
                reactionType: type,
                add: localReactionByPostID[post.recordID] == type
            )
        }
    }

    // MARK: - Report handler (silent removal at threshold)

    private func handleReport(post: CKRecord) async {
        let count = await viewModel.reportPost(
            recordID: post.recordID,
            reporterID: reporterID
        )
        guard count >= 0 else {
            // Network failure — do not hide the post; count == -1 signals service error
            return
        }
        // Hide locally — UI-SPEC: silent removal, no success alert
        withAnimation(.easeOut(duration: 0.25)) {
            viewModel.feedPosts.removeAll { $0.recordID == post.recordID }
        }
    }
}
