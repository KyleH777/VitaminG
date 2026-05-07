import SwiftUI
import SwiftData

// MARK: - ChallengeCheckInView

/// Type-adaptive check-in modal (CHAL-09, CHAL-07).
/// Adapts UI to template.checkInType — boolean toggle, numeric field, or 2-step wizard.
/// Type branching lives here only — engine (ChallengeViewModel) remains type-blind.
struct ChallengeCheckInView: View {
    let userChallenge: UserChallenge
    var viewModel: ChallengeViewModel

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var boolValue: Bool = false
    @State private var numericText: String = ""
    @State private var multiStepPage: Int = 0
    @State private var multiStepBool: Bool = false
    @State private var multiStepNumericText: String = ""
    @State private var saveError: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch userChallenge.template?.checkInType {
                    case "boolean":
                        booleanCheckInSection
                    case "numeric":
                        numericCheckInSection
                    case "multiStep":
                        multiStepCheckInSection
                    default:
                        booleanCheckInSection
                    }

                    if let error = saveError {
                        Text(error)
                            .font(.caption)
                            .fontDesign(.rounded)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(modalTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .font(.body)
                        .fontDesign(.rounded)
                }
            }
        }
    }

    // MARK: - Boolean Section

    private var booleanCheckInSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Did you complete today's goal?", isOn: $boolValue)
                .font(.body)
                .fontDesign(.rounded)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            saveButton("Save Check-In") {
                save(payload: CheckInPayload.boolean(boolValue))
            }
        }
    }

    // MARK: - Numeric Section

    private var numericCheckInSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount")
                    .font(.body)
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.clay)
                HStack {
                    TextField("0", text: $numericText)
                        .keyboardType(.decimalPad)
                        .font(.body)
                        .fontDesign(.rounded)
                    Text("units")
                        .font(.body)
                        .fontDesign(.rounded)
                        .foregroundStyle(VGTheme.muted)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            saveButton("Save Check-In") {
                save(payload: CheckInPayload.numeric(Double(numericText) ?? 0))
            }
        }
    }

    // MARK: - Multi-Step Section

    private var multiStepCheckInSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if multiStepPage == 0 {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Did you work out today?")
                        .font(.body)
                        .fontDesign(.rounded)
                        .foregroundStyle(VGTheme.clay)
                    Toggle("", isOn: $multiStepBool)
                        .labelsHidden()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Button("Next Step") { multiStepPage = 1 }
                        .font(.body)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text("How many minutes?")
                        .font(.body)
                        .fontDesign(.rounded)
                        .foregroundStyle(VGTheme.clay)
                    TextField("0", text: $multiStepNumericText)
                        .keyboardType(.numberPad)
                        .font(.body)
                        .fontDesign(.rounded)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    saveButton("Save Check-In") {
                        save(payload: CheckInPayload.multiStep(
                            note: "",
                            numericValue: Double(multiStepNumericText)
                        ))
                    }
                }
            }
        }
    }

    // MARK: - Save Button Helper

    @ViewBuilder
    private func saveButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(label, action: action)
            .font(.body)
            .fontWeight(.semibold)
            .fontDesign(.rounded)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Save Logic

    private func save(payload: CheckInPayload) {
        do {
            try viewModel.recordCheckIn(for: userChallenge, payload: payload, context: modelContext)
            dismiss()
        } catch CheckInError.alreadyCheckedInToday {
            saveError = "Already checked in today."
        } catch {
            saveError = "Couldn't save your check-in. Please try again."
        }
    }

    // MARK: - Computed Helpers

    private var accentColor: Color {
        Color(hex: userChallenge.template?.accentColorHex ?? "#C4673A")
    }

    private var modalTitle: String {
        switch userChallenge.template?.checkInType {
        case "multiStep": return multiStepPage == 0 ? "Step 1 of 2" : "Step 2 of 2"
        default: return "Today's Check-In"
        }
    }
}
