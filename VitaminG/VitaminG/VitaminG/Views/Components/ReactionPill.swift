import SwiftUI

struct ReactionPill: View {
    let emoji: String          // "👍" or "❤️"
    let count: Int
    let isActive: Bool
    let accentColor: Color
    let action: () -> Void

    private var accessibilityLabel: String {
        let prefix: String
        switch emoji {
        case "👍": prefix = "Thumbs up"
        case "❤️": prefix = "Heart"
        default:   prefix = "Reaction"
        }
        return "\(prefix), \(count) reactions"
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(emoji).font(.body)
                Text("\(count)")
                    .font(.caption)
                    .fontDesign(.rounded)
                    .foregroundStyle(isActive ? accentColor : VGTheme.clay)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(minHeight: 44)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isActive ? accentColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }
}
