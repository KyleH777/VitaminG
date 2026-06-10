import SwiftUI
import SwiftData

// MARK: - DeleteAccountSection

/// Settings section providing permanent account deletion (DEL-02).
/// Drop into SettingsView's Form below the Support section:
///
///     Section("Support") { ... }
///     DeleteAccountSection()           // <- add this line
///
/// Flow: red row -> confirmationDialog (first gate) -> alert requiring the user
/// to type DELETE (second gate) -> progress spinner -> route to onboarding on
/// success, or error alert with retry on CloudKit failure (local data intact).
///
/// MVVM note: the two-gate state machine is pure presentation state, so it lives
/// in the View per existing SettingsView conventions. The deletion itself is in
/// AccountDeletionService — no business logic here.
struct DeleteAccountSection: View {
    @Environment(\.modelContext) private var modelContext

    /// Routes back to onboarding on successful deletion.
    /// Key matches the flag used in VitaminGApp (hasCompletedOnboarding).
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true

    @State private var showFirstConfirmation = false
    @State private var showTypedConfirmation = false
    @State private var typedText = ""
    @State private var isDeleting = false
    @State private var deletionError: String?

    private var typedTextMatches: Bool {
        typedText.trimmingCharacters(in: .whitespaces).uppercased() == "DELETE"
    }

    var body: some View {
        Section {
            if isDeleting {
                HStack {
                    ProgressView()
                    Text("Deleting your account…")
                        .foregroundStyle(.secondary)
                        .padding(.leading, 8)
                }
                .accessibilityLabel("Deleting your account, please wait")
            } else {
                Button(role: .destructive) {
                    showFirstConfirmation = true
                } label: {
                    Label("Delete Account", systemImage: "trash")
                }
                .accessibilityLabel("Delete account")
                .accessibilityHint("Permanently deletes your account and all data. Asks for confirmation first.")
            }
        } footer: {
            Text("Permanently deletes your goals, streaks, check-ins, profile, and public posts. This cannot be undone.")
        }
        .confirmationDialog(
            "Delete your account?",
            isPresented: $showFirstConfirmation,
            titleVisibility: .visible
        ) {
            Button("Continue to Delete", role: .destructive) {
                typedText = ""
                showTypedConfirmation = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All goals, streaks, photos, and your public profile will be permanently erased from this device and our servers.")
        }
        .alert("Confirm Deletion", isPresented: $showTypedConfirmation) {
            TextField("Type DELETE to confirm", text: $typedText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
            Button("Delete Forever", role: .destructive) {
                guard typedTextMatches else { return }
                performDeletion()
            }
            Button("Cancel", role: .cancel) { typedText = "" }
        } message: {
            Text("This is permanent. Type DELETE to confirm.")
        }
        .alert("Deletion Failed", isPresented: .init(
            get: { deletionError != nil },
            set: { if !$0 { deletionError = nil } }
        )) {
            Button("Try Again") {
                performDeletion()
            }
            Button("Cancel", role: .cancel) { deletionError = nil }
        } message: {
            Text(deletionError ?? "")
        }
    }

    private func performDeletion() {
        guard !isDeleting else { return }
        isDeleting = true
        deletionError = nil

        Task { @MainActor in
            do {
                try await AccountDeletionService.deleteAccount(context: modelContext)
                // Success: local + remote data gone. Route to onboarding.
                // removePersistentDomain already cleared the @AppStorage backing value,
                // but set it explicitly so the root view switches this frame.
                hasCompletedOnboarding = false
                isDeleting = false
            } catch {
                // CloudKit failed — local data is intact, safe to retry.
                isDeleting = false
                deletionError = error.localizedDescription
            }
        }
    }
}

#Preview {
    Form {
        DeleteAccountSection()
    }
}
