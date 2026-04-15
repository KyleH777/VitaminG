import SwiftUI
import SwiftData

// MARK: - ProfileEditSheet

/// Sheet for editing the user's display name with 50-char enforcement and character count.
/// Presented from ProfileView when user taps the pencil button.
/// Accepts ProfileViewModel by reference — not @State — so changes propagate back to ProfileView.
struct ProfileEditSheet: View {
    @Bindable var viewModel: ProfileViewModel

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Your name", text: $viewModel.draftDisplayName)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .onChange(of: viewModel.draftDisplayName) { _, newValue in
                                // Enforce 50-char max inline (T-07-04)
                                if newValue.count > ProfileViewModel.maxDisplayNameLength {
                                    viewModel.draftDisplayName = String(
                                        newValue.prefix(ProfileViewModel.maxDisplayNameLength)
                                    )
                                }
                            }

                        HStack {
                            Spacer()
                            Text("\(viewModel.draftDisplayName.count)/\(ProfileViewModel.maxDisplayNameLength)")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Display Name")
                } footer: {
                    Text("This name appears on your profile and is visible to anyone you share your profile with.")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard Changes") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update Name") {
                        if viewModel.validateAndSaveDisplayName(context: modelContext) {
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(
                        viewModel.draftDisplayName
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                    )
                }
            }
            .alert("", isPresented: $viewModel.showingValidationAlert) {
                Button("OK") {}
            } message: {
                Text(viewModel.validationErrorMessage)
            }
        }
    }
}
