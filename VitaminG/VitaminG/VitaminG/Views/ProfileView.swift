import SwiftUI
import SwiftData
import UIKit

// MARK: - ProfileView

/// 4th tab: Personal profile with avatar, display name, privacy toggle, public goals, and share button.
/// Per D-11, D-12. Business logic lives in ProfileViewModel — this view is purely declarative.
struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @Environment(\.modelContext) private var modelContext

    /// Live query of goals the user has explicitly made public (D-09, T-07-05).
    /// Only title and tier are displayed — no descriptions, no inspiration text (acceptable exposure).
    @Query(filter: #Predicate<Goal> { $0.isPublic == true }) private var publicGoals: [Goal]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    avatarSection
                    displayNameRow
                    privacyToggleSection
                    publicGoalsSection
                    shareProfileButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 32)
                .padding(.bottom, 32)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("My Profile")
            .onAppear {
                viewModel.loadOrCreateProfile(context: modelContext)
            }
            .sheet(isPresented: $viewModel.showingEditSheet) {
                ProfileEditSheet(viewModel: viewModel)
            }
            .alert("Couldn't share your profile.", isPresented: $viewModel.showingCloudKitError) {
                Button("Got It", role: .cancel) {}
            } message: {
                Text("Check your internet connection and try again.")
            }
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        ZStack {
            Circle()
                .fill(viewModel.avatarColor)
                .frame(width: 88, height: 88)
                .shadow(color: .black.opacity(0.10), radius: 8, y: 4)

            Text(viewModel.initials)
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .accessibilityLabel("Profile avatar for \(viewModel.profile?.displayName ?? "you")")
    }

    // MARK: - Display Name Row

    private var displayNameRow: some View {
        HStack(spacing: 8) {
            if let name = viewModel.profile?.displayName, !name.isEmpty {
                Text(name)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            } else {
                Text("Add your name")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Button {
                viewModel.draftDisplayName = viewModel.profile?.displayName ?? ""
                viewModel.showingEditSheet = true
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(red: 0.98, green: 0.55, blue: 0.27))
            }
            .accessibilityLabel("Edit display name")
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Privacy Toggle Section

    private var privacyToggleSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Toggle(
                    "Public Profile",
                    isOn: Binding(
                        get: { viewModel.profile?.isPublic ?? false },
                        set: { _ in viewModel.toggleProfilePublic(context: modelContext) }
                    )
                )
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .accessibilityLabel("Public profile")
                .accessibilityValue(viewModel.profile?.isPublic == true ? "On" : "Off")
            }
            .padding(16)

            Divider().padding(.horizontal, 16)

            Text(
                viewModel.profile?.isPublic == true
                    ? "When public, anyone with your share link can view your goals that you've marked as public."
                    : "Your profile is private by default. Only you can see it."
            )
            .font(.system(size: 12, weight: .regular, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Public Goals Section

    private var publicGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Public Goals")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)

            if publicGoals.isEmpty {
                // Empty state (per UI-SPEC copywriting and specifics)
                VStack(spacing: 8) {
                    Text("Your goals are private.")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Mark any goal public from its detail screen to share it on your profile.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(publicGoals) { goal in
                        HStack(spacing: 12) {
                            // Tier color pip
                            RoundedRectangle(cornerRadius: 2)
                                .fill(goal.tier.color)
                                .frame(width: 4, height: 36)

                            Text(goal.title ?? "Untitled")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundStyle(.primary)
                                .lineLimit(2)

                            Spacer()

                            Image(systemName: goal.tier.icon)
                                .font(.system(size: 12))
                                .foregroundStyle(goal.tier.color)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .animation(.easeOut(duration: 0.25), value: publicGoals.count)
            }
        }
    }

    // MARK: - Share Profile Button

    private var shareProfileButton: some View {
        Group {
            if let url = viewModel.shareURL {
                ShareLink(
                    item: url,
                    subject: Text("Vitamin G Profile"),
                    message: Text("Check out my goals on Vitamin G!")
                ) {
                    Label("Share Profile", systemImage: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.98, green: 0.55, blue: 0.27))
                .padding(.horizontal, 16)
            } else {
                Button {
                    // No action — URL not yet available (profile private or CloudKit record pending)
                } label: {
                    Label("Share Profile", systemImage: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.98, green: 0.55, blue: 0.27))
                .disabled(true)
                .padding(.horizontal, 16)
                .accessibilityHint("Set your profile to public to enable sharing")
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.shareURL != nil)
    }
}
