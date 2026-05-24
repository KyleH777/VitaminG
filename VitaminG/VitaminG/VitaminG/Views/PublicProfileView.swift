import SwiftUI
import MessageUI

/// Read-only sheet card displaying a public profile fetched via deep link.
/// Shows avatar + display name only (D-02). Presented as a sheet (D-06).
/// Includes Report/Block context menus and explicit button per PROF-05 (App Store Guideline 1.2).
struct PublicProfileView: View {
    let recordID: String
    @State private var viewModel = PublicProfileViewModel()
    @Environment(\.dismiss) private var dismiss

    // MARK: - Report / Block state (PROF-05)
    @State private var showBlockConfirm: Bool = false
    @State private var showMailCompose: Bool = false
    @State private var reportMailSubject: String = ""
    @State private var reportMailBody: String = ""

    // MARK: - SOC-03: Cheers given counter
    @State private var cheersGivenCount: Int = 0

    @AppStorage("vg_appleUserID") private var myAppleUserID: String = ""

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
        .task {
            cheersGivenCount = (try? await CommunityService.fetchApplauseGivenCount(giverUsername: recordID)) ?? 0
        }
        .accessibilityHint("Read-only view of a shared profile.")
        .alert("Block this user?", isPresented: $showBlockConfirm) {
            Button("Block", role: .destructive) {
                BlockListService.blockUser(appleUserID: recordID)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("They won't appear in your community feed.")
        }
        .sheet(isPresented: $showMailCompose) {
            MailComposeView(
                subject: reportMailSubject,
                body: reportMailBody,
                toRecipients: ["support@vitamingapp.com"]
            ) {
                showMailCompose = false
            }
        }
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
                .contextMenu {
                    Button {
                        reportUser(displayName: displayName)
                    } label: {
                        Label("Report User", systemImage: "flag")
                    }
                    Button(role: .destructive) {
                        showBlockConfirm = true
                    } label: {
                        Label("Block User", systemImage: "slash.circle")
                    }
                }

                Text(displayName ?? "Unknown")
                    .font(.title2.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)
                    .contextMenu {
                        Button {
                            reportUser(displayName: displayName)
                        } label: {
                            Label("Report User", systemImage: "flag")
                        }
                        Button(role: .destructive) {
                            showBlockConfirm = true
                        } label: {
                            Label("Block User", systemImage: "slash.circle")
                        }
                    }

                Spacer()
                Text("Shared via Vitamin G")
                    .font(.caption)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)

                Text("\(cheersGivenCount) cheers given")
                    .font(.system(size: 14))
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.textMuted)
                    .accessibilityLabel("\(cheersGivenCount) cheers given to others")

                Button(action: { showBlockConfirm = true }) {
                    Text("Report or Block")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(VGTheme.terra)
                }
                .padding(.top, 16)
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

    // MARK: - Actions

    /// Constructs the report email and opens MFMailComposeViewController if available;
    /// falls back to a mailto: URL if Mail.app is not configured on device.
    private func reportUser(displayName: String?) {
        let username = displayName ?? "unknown"
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let subject = "[Vitamin G] Report User: @\(username)"
        let body = """
        Reporter Apple ID: \(myAppleUserID)
        Reported username: @\(username)
        Timestamp: \(timestamp)

        ---
        [Please describe the issue below]
        """

        if MFMailComposeViewController.canSendMail() {
            reportMailSubject = subject
            reportMailBody = body
            showMailCompose = true
        } else {
            let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "mailto:support@vitamingapp.com?subject=\(encodedSubject)&body=\(encodedBody)") {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - MailComposeView

/// UIViewControllerRepresentable bridge for MFMailComposeViewController.
/// Used by PublicProfileView to present the report email flow (D-14).
struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let body: String
    let toRecipients: [String]
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients(toRecipients)
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            controller.dismiss(animated: true, completion: onDismiss)
        }
    }
}
