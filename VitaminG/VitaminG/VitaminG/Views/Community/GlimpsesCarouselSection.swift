import SwiftUI
import Combine

// MARK: - GlimpsesCarouselSection
// Today's Glimpses carousel (COMM-02 / COMM-03).
//
// Auto-advances every 5 seconds using Timer.publish().autoconnect().
// Pauses while isDragging is true — DragGesture.onChanged sets the flag,
// onEnded clears it (T-21-05-03 mitigation: carousel respects user intent).
//
// Tapping the whole card navigates to PublicProfileView via onTapCard(glimpse)
// — caller sets router.pendingPublicProfileRecordID (D-02).
// ApplauseButtonView is embedded in GlimpseCard; its Button tap does NOT
// propagate to the card's navigation tap (uses .buttonStyle(.plain) on the
// outer card wrapper + ApplauseButtonView retains its own Button).

struct GlimpsesCarouselSection: View {

    // MARK: - Properties

    let glimpses: [GoalGlimpseItem]
    let giverUsername: String
    let canApplaud: (String) -> Bool
    let onApplaud: (String) -> Void
    let onTapCard: (GoalGlimpseItem) -> Void

    // MARK: - State

    @State private var currentIndex: Int = 0
    @State private var isDragging: Bool = false

    // MARK: - Timer (5-second auto-advance)

    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    // MARK: - Body

    var body: some View {
        if glimpses.isEmpty {
            emptyState
        } else {
            TabView(selection: $currentIndex) {
                ForEach(Array(glimpses.enumerated()), id: \.offset) { index, glimpse in
                    GlimpseCard(
                        glimpse: glimpse,
                        giverUsername: giverUsername,
                        canApplaud: canApplaud(glimpse.username),
                        onApplaud: { onApplaud(glimpse.username) },
                        onTapCard: { onTapCard(glimpse) }
                    )
                    .tag(index)
                    .padding(.horizontal, 16)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 200)
            .accessibilityLabel("Today's Glimpses. \(glimpses.count) cards.")
            .onReceive(timer) { _ in
                guard !isDragging, !glimpses.isEmpty else { return }
                withAnimation(.easeInOut(duration: 0.4)) {
                    currentIndex = (currentIndex + 1) % glimpses.count
                }
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { _ in isDragging = true }
                    .onEnded { _ in isDragging = false }
            )
        }
    }

    // MARK: - Empty state (UI-SPEC §Copywriting)

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No glimpses yet today")
                .font(.system(size: 17))
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.textPrimary)
            Text("Check in on a goal to appear here.")
                .font(.system(size: 14))
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
    }
}

// MARK: - GlimpseCard
// Individual card inside the carousel. Height 180pt (per UI-SPEC §Component Inventory).
// Uses a Button for the full-card tap (profile navigation) with .buttonStyle(.plain)
// so embedded ApplauseButtonView retains its own Button interaction.

private struct GlimpseCard: View {

    let glimpse: GoalGlimpseItem
    let giverUsername: String
    let canApplaud: Bool
    let onApplaud: () -> Void
    let onTapCard: () -> Void

    var body: some View {
        Button(action: onTapCard) {
            HStack(alignment: .top, spacing: 12) {
                // Left column: avatar + optional photo thumbnail
                VStack(spacing: 8) {
                    AvatarView(
                        displayName: glimpse.username,
                        avatarColorHex: glimpse.authorColorHex,
                        photoData: nil,
                        size: 40
                    )
                    if let photoURL = glimpse.photoFileURL {
                        AsyncImage(url: photoURL) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color(.tertiarySystemGroupedBackground)
                        }
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                // Center column: username, goal title, progress
                VStack(alignment: .leading, spacing: 4) {
                    Text(glimpse.username)
                        .font(.system(size: 14, weight: .semibold))
                        .fontDesign(.rounded)
                        .foregroundStyle(VGTheme.textPrimary)
                        .lineLimit(1)
                    Text(glimpse.goalTitle)
                        .font(.system(size: 14))
                        .fontDesign(.rounded)
                        .foregroundStyle(VGTheme.textSecondary)
                        .lineLimit(2)
                    Text("\(glimpse.progressPercent)%")
                        .font(.system(size: 14))
                        .fontDesign(.rounded)
                        .foregroundStyle(VGTheme.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right column: applause button (not part of card nav tap)
                ApplauseButtonView(
                    recipientUsername: glimpse.username,
                    giverUsername: giverUsername,
                    canApplaud: canApplaud,
                    onApplaud: onApplaud
                )
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(VGTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(glimpse.username)'s goal: \(glimpse.goalTitle), \(glimpse.progressPercent) percent complete")
        .frame(minHeight: 44)
    }
}
