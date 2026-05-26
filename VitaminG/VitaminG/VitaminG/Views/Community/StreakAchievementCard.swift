import SwiftUI
import CloudKit

// MARK: - StreakAchievementCard
// Feed card for achievement CKRecords (MILE-05).
//
// Renders a goal milestone achievement post with a trophy icon badge.
// Only shown when record["isAchievementPost"] == 1 (discriminated in GlobalFeedSection).
//
// Security (T-21-05-01): CKRecord fields rendered via SwiftUI Text() — no code execution surface.
// InputSanitizer was applied at write time in CommunityService.createAchievementPost.
// All field reads use safe optional casting (as? String / as? Int) — T-23-04-05 accepted.

struct StreakAchievementCard: View {
    let record: CKRecord

    // MARK: - Field accessors

    private var text: String { record["text"] as? String ?? "" }
    private var authorDisplayName: String { record["authorDisplayName"] as? String ?? "Anonymous" }
    private var authorColorHex: String { record["authorColorHex"] as? String ?? "#A0A0A0" }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Trophy badge circle with author avatar color
            Circle()
                .fill(Color(hex: authorColorHex))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 16))
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(authorDisplayName)
                    .font(.system(size: 14, weight: .semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.clay)
                Text(text)
                    .font(.system(size: 14))
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(authorDisplayName) achieved: \(text)")
    }
}
