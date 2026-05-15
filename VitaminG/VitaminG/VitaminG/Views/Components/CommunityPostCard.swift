import SwiftUI
import CloudKit

struct CommunityPostCard: View {
    let post: CKRecord
    let currentUserReaction: ReactionType?
    let accentColor: Color
    let onReact: (ReactionType) -> Void
    let onReport: () -> Void
    var onComment: (() -> Void)? = nil

    @State private var showReportDialog = false

    // MARK: - CKRecord field accessors
    private var bodyText: String { (post["text"] as? String) ?? "" }
    private var displayName: String { (post["authorDisplayName"] as? String) ?? "Anonymous" }
    private var colorHex: String? {
        (post["authorColorHex"] as? String).flatMap { $0.isEmpty ? nil : $0 }
    }
    private var thumbsUpCount: Int { (post["thumbsUpCount"] as? Int) ?? 0 }
    private var heartCount: Int { (post["heartCount"] as? Int) ?? 0 }
    private var photoAsset: CKAsset? { post["photoAsset"] as? CKAsset }
    private var creationDate: Date { post.creationDate ?? Date() }

    private var relativeTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: creationDate, relativeTo: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 1. Author row + report button
            HStack(spacing: 8) {
                AvatarView(displayName: displayName, avatarColorHex: colorHex, photoData: nil, size: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.body.weight(.semibold))
                        .fontDesign(.rounded)
                        .foregroundStyle(VGTheme.clay)
                    Text(relativeTimestamp)
                        .font(.caption)
                        .fontDesign(.rounded)
                        .foregroundStyle(VGTheme.muted)
                }
                Spacer()
                Button {
                    showReportDialog = true
                } label: {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(VGTheme.muted)
                        .frame(width: 32, height: 32, alignment: .trailing)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Report this post")
            }

            // 2. Post body
            if !bodyText.isEmpty {
                Text(bodyText)
                    .font(.body)
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.clay)
                    .lineLimit(4)
            }

            // 3. Optional photo
            if let asset = photoAsset, let url = asset.fileURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color(.tertiarySystemGroupedBackground)
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // 4. Reactions
            HStack(spacing: 8) {
                ReactionPill(
                    emoji: "👍",
                    count: thumbsUpCount,
                    isActive: currentUserReaction == .thumbsUp,
                    accentColor: accentColor,
                    action: { onReact(.thumbsUp) }
                )
                ReactionPill(
                    emoji: "❤️",
                    count: heartCount,
                    isActive: currentUserReaction == .heart,
                    accentColor: accentColor,
                    action: { onReact(.heart) }
                )
                if let onComment {
                    Button { onComment() } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "bubble.left").font(.system(size: 12))
                            Text("Reply").font(.system(size: 12))
                        }
                        .foregroundStyle(VGTheme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .confirmationDialog(
            "Report this post?",
            isPresented: $showReportDialog,
            titleVisibility: .visible
        ) {
            Button("Report", role: .destructive, action: onReport)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will send a report. The post will be hidden from your feed after 3 reports from different users.")
        }
    }
}
