import SwiftUI

/// Read-only sheet card displaying a public profile fetched via deep link.
/// Shows avatar + display name only (D-02). Presented as a sheet (D-06).
struct PublicProfileView: View {
    let recordID: String
    @State private var viewModel = PublicProfileViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemGroupedBackground))
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(VGTheme.accentTerra)
                    }
                }
                .interactiveDismissDisabled(viewModel.isLoading)
        }
        .onAppear {
            viewModel.fetchProfile(recordID: recordID)
        }
        .accessibilityHint("Read-only view of a shared profile.")
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            VStack(spacing: 12) {
                ProgressView()
                    .tint(VGTheme.accentTerra)
                    .accessibilityLabel("Loading profile")
                Text("Loading profile...")
                    .font(.body)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }

        case .loaded(let displayName, let avatarColorHex):
            VStack(spacing: 16) {
                Spacer()
                AvatarView(
                    displayName: displayName,
                    avatarColorHex: avatarColorHex,
                    photoData: nil,
                    size: 72
                )
                Text(displayName ?? "Unknown")
                    .font(.title2.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)
                Spacer()
                Text("Shared via Vitamin G")
                    .font(.caption)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)

        case .error(let message):
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "exclamationmark.icloud.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text(message)
                    .font(.body)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .accessibilityLabel("Error: \(message)")
                Spacer()
            }
        }
    }
}
