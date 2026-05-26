import SwiftUI

// MARK: - FollowButton
// Three-state follow pill button consumed by PublicProfileView and PeopleSearchResultCard.
// Pure presentation — state is owned by the caller (PublicProfileViewModel.followState).
// UI-SPEC §2: idle→terra, loading→terra 70%, followed→sage. Spring animation on transition.
// T-22-03-02 mitigation: button is disabled while .loading (prevents double-tap at UI layer).

struct FollowButton: View {

    /// Current follow state. Drives appearance and disabled logic.
    let state: FollowState
    /// Closure called when the user taps the button (only fires when .idle).
    let onFollow: () -> Void

    /// Optional username for the accessibility label. Defaults to empty string.
    var username: String = ""

    var body: some View {
        Button(action: onFollow) {
            HStack(spacing: 6) {
                if state == .loading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.75)
                }
                Text(labelText)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(backgroundTint)
            .clipShape(Capsule())
            // HIG minimum touch target (UI-SPEC §2)
            .frame(minWidth: 44, minHeight: 44)
        }
        .disabled(state == .loading || state == .followed)
        .buttonStyle(.plain)
        // Spring animation on background + label transition (UI-SPEC §2)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: state)
        .accessibilityLabel(
            state == .followed
                ? (username.isEmpty ? "Following" : "Following \(username)")
                : (username.isEmpty ? "Follow" : "Follow \(username)")
        )
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Computed

    private var labelText: String {
        switch state {
        case .idle:     return "Follow"
        case .loading:  return "Follow"
        case .followed: return "Following"
        }
    }

    private var backgroundTint: Color {
        switch state {
        case .idle:    return VGTheme.accentTerra
        case .loading: return VGTheme.accentTerra.opacity(0.7)
        case .followed: return VGTheme.accentSage
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        FollowButton(state: .idle, onFollow: {}, username: "alice")
        FollowButton(state: .loading, onFollow: {}, username: "alice")
        FollowButton(state: .followed, onFollow: {}, username: "alice")
    }
    .padding()
    .background(VGTheme.background)
}
