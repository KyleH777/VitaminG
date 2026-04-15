import SwiftUI

// MARK: - AvatarView

/// Reusable avatar view. Shows a photo if `photoData` is non-nil,
/// otherwise renders a colored circle with 1-2 character initials.
///
/// Supports configurable size for use in ProfileView (88pt), ProfileEditSheet (64pt),
/// and potential future list rows (40pt).
struct AvatarView: View {
    let displayName: String?
    let avatarColorHex: String?
    let photoData: Data?
    var size: CGFloat = 88

    var body: some View {
        Group {
            if let photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(avatarColor)
                        .frame(width: size, height: size)
                    Text(initials)
                        .font(.system(size: initialsSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
        .shadow(color: .black.opacity(0.10), radius: shadowRadius, y: shadowY)
        .accessibilityLabel("Profile avatar for \(displayName ?? "you")")
    }

    // MARK: - Computed Properties

    /// Parse avatarColorHex to Color, fallback to gray
    private var avatarColor: Color {
        guard let hex = avatarColorHex, !hex.isEmpty else { return .gray }
        return Color(hex: hex)
    }

    /// 1-2 character initials from displayName. "?" if empty.
    private var initials: String {
        guard let name = displayName?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else {
            return "?"
        }
        let words = name.split(separator: " ")
        let chars = words.prefix(2).compactMap { $0.first }
        return String(chars).uppercased()
    }

    /// Scale initials font size proportionally to circle size.
    /// 88pt circle -> 34pt text (UI-SPEC ratio ~38.6%)
    private var initialsSize: CGFloat {
        size * 0.386
    }

    /// Shadow radius scales with size
    private var shadowRadius: CGFloat {
        size >= 64 ? 8 : 4
    }

    /// Shadow Y offset scales with size
    private var shadowY: CGFloat {
        size >= 64 ? 4 : 2
    }
}
