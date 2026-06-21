import SwiftUI

// MARK: - ActiveTodaySection
// Horizontal scrolling avatar strip for users active in the last 2 hours (COMM-04).
//
// Tapping any avatar calls onTapUser — caller sets router.pendingPublicProfileRecordID
// to navigate to PublicProfileView (D-02 / COMM-04).
// Empty state copy from UI-SPEC §Copywriting.

struct ActiveTodaySection: View {

    // MARK: - Properties

    let activeUsers: [UserPresenceItem]
    let onTapUser: (UserPresenceItem) -> Void

    // MARK: - Body

    var body: some View {
        if activeUsers.isEmpty {
            emptyState
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(activeUsers) { user in
                        Button {
                            onTapUser(user)
                        } label: {
                            VStack(spacing: 6) {
                                AvatarView(
                                    displayName: user.username,
                                    avatarColorHex: user.authorColorHex,
                                    photoData: nil,
                                    size: 44
                                )
                                .accessibilityHidden(true)
                                Text(user.username)
                                    .font(.caption)
                                    .fontDesign(.rounded)
                                    .foregroundStyle(VGTheme.textMuted)
                                    .lineLimit(1)
                                    .frame(maxWidth: 64)
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityLabel("\(user.username), active today. Tap to view profile.")
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Empty state (UI-SPEC §Copywriting)

    private var emptyState: some View {
        Text("Nobody active in the last 2 hours. Be the first — open the app!")
            .font(.callout)
            .fontDesign(.rounded)
            .foregroundStyle(VGTheme.textMuted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
    }
}
