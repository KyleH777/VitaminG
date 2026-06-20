import SwiftUI
import MessageUI

/// Read-only sheet card displaying a public profile fetched via deep link or Discover tap.
/// Redesigned in Phase 22 to show the full UI-SPEC §PublicProfileView card:
///   hero (avatar 80pt + display name + @username + motto)
///   stats row (streak / goals / cheers given)
///   action row (FollowButton + CheerButton)
///   MY PUBLIC GOALS list (PublicGoalCard × N, empty state if none)
///   Report/Block footer
/// Existing shell preserved verbatim: NavigationStack, .navigationTitle("Profile"),
/// Done toolbar, .alert("Block this user?"), .sheet for MFMailComposeView.
struct PublicProfileView: View {
    let recordID: String
    @State private var viewModel = PublicProfileViewModel()
    @Environment(\.dismiss) private var dismiss

    // MARK: - Report / Block state (PROF-05 — carry forward from Phase 17 unchanged)
    @State private var showBlockConfirm: Bool = false
    @State private var showMailCompose: Bool = false
    @State private var reportMailSubject: String = ""
    @State private var reportMailBody: String = ""

    @AppStorage("vg_appleUserID") private var myAppleUserID: String = ""
    @AppStorage("vg_username") private var myUsername: String = ""

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(VGTheme.background.ignoresSafeArea())
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

    // MARK: - Content Switch

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

        case .loaded(let profile):
            loadedContent(profile: profile)

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

    // MARK: - Loaded Content (UI-SPEC §PublicProfileView)

    @ViewBuilder
    private func loadedContent(profile: PublicProfileData) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Hero Header (padding top: 24pt)
                VStack(spacing: 8) {
                    AvatarView(
                        displayName: profile.displayName,
                        avatarColorHex: profile.avatarColorHex,
                        photoData: nil,
                        size: 80
                    )

                    Text(profile.displayName ?? "Unknown")
                        .font(VGTheme.serif(28))
                        .foregroundStyle(VGTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("@\(profile.username ?? "user")")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(VGTheme.textMuted)

                    if let motto = profile.motto, !motto.isEmpty {
                        Text(motto)
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(VGTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal, 24)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 24)

                // MARK: Stats Row (padding H: 24, V: 16)
                HStack(spacing: 0) {
                    statCell(value: "\(profile.streakLength)", label: "day streak")
                    Divider()
                        .frame(height: 36)
                        .background(VGTheme.separator)
                    statCell(value: "\(profile.goalCount)", label: "goals")
                    Divider()
                        .frame(height: 36)
                        .background(VGTheme.separator)
                    statCell(value: "\(profile.cheersGivenCount)", label: "cheers given")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                // MARK: Action Row (padding H: 24, top: 16, bottom: 24)
                HStack(spacing: 16) {
                    FollowButton(
                        state: viewModel.followState,
                        onFollow: {
                            viewModel.onFollow(
                                followerUsername: myUsername,
                                followeeUsername: profile.username ?? ""
                            )
                        },
                        username: profile.username ?? ""
                    )

                    CheerButton(
                        isAvailable: viewModel.canCheerToday(recipientUsername: profile.username ?? ""),
                        recipientUsername: profile.username ?? "",
                        onCheer: {
                            viewModel.onCheer(
                                recipientUsername: profile.username ?? "",
                                giverUsername: myUsername
                            )
                        }
                    )

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)

                // Follow error banner (UI-SPEC §2 — auto-clears after 3s in VM)
                if let followError = viewModel.followError {
                    Text(followError)
                        .font(.system(size: 13))
                        .foregroundStyle(VGTheme.accentTerra)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }

                // MARK: Separator
                Divider()
                    .background(VGTheme.separator)
                    .padding(.horizontal, 16)

                // MARK: MY PUBLIC GOALS section (padding H: 16, top: 20)
                sectionLabel("MY PUBLIC GOALS")
                    .padding(.top, 20)

                if viewModel.publicGoals.isEmpty {
                    // Empty state (UI-SPEC §Empty States)
                    VStack(spacing: 8) {
                        Text("No public goals yet")
                            .font(.callout.weight(.semibold).fontDesign(.rounded))
                            .foregroundStyle(VGTheme.textPrimary)
                        Text("This user hasn't shared any goals.")
                            .font(.callout.fontDesign(.rounded))
                            .foregroundStyle(VGTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.publicGoals) { goal in
                            PublicGoalCard(goal: goal)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }

                // MARK: Separator
                Divider()
                    .background(VGTheme.separator)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // MARK: Footer (padding H: 16, top: 16, bottom: 24)
                VStack(spacing: 8) {
                    Button(action: { showBlockConfirm = true }) {
                        Text("Report or Block")
                            .font(.caption.fontDesign(.rounded))
                            .foregroundStyle(VGTheme.accentTerra)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)

                    Text("Shared via Vitamin G")
                        .font(.caption.fontDesign(.rounded))
                        .foregroundStyle(VGTheme.textFaint)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            // Resolve follow state once the profile username is known
            viewModel.resolveFollowState(
                followerUsername: myUsername,
                followeeUsername: profile.username ?? ""
            )
        }
    }

    // MARK: - Section Label Helper
    // Matches ExploreView.sectionLabel pattern (13pt semibold, kerning 0.4, textMuted, padding H: 16).

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .kerning(0.4)
            .foregroundStyle(VGTheme.textMuted)
            .padding(.horizontal, 16)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Stat Cell Helper

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(VGTheme.serif(20))
                .foregroundStyle(VGTheme.textPrimary)
            Text(label)
                .font(.caption.fontDesign(.rounded))
                .foregroundStyle(VGTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
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
