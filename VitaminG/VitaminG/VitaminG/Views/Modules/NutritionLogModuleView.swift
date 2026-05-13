import SwiftUI
import SwiftData

struct NutritionLogModuleView: View {
    let userChallenge: UserChallenge

    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [NutritionEntry]

    @State private var draft: String = ""
    @State private var showSaved: Bool = false
    @State private var lastSavedNote: String = ""

    private static let maxChars = 300
    private static let placeholder = "What did you eat today?"

    private var accentColor: Color {
        Color(hex: userChallenge.template?.accentColorHex ?? "#C4673A")
    }

    private var todayEntry: NutritionEntry? {
        let challengeID = userChallenge.id
        let cal = Calendar.current
        return allEntries.first { entry in
            guard entry.userChallengeID == challengeID,
                  let date = entry.date else { return false }
            return cal.isDateInToday(date)
        }
    }

    private var hasChanges: Bool {
        draft.trimmingCharacters(in: .whitespacesAndNewlines) != lastSavedNote
            && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "fork.knife")
                    .font(.title3)
                    .foregroundStyle(VGTheme.clay)
                Text("Nutrition Log")
                    .font(.title2.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.clay)
                Spacer()
            }

            VStack(alignment: .trailing, spacing: 4) {
                ZStack(alignment: .topLeading) {
                    if draft.isEmpty {
                        Text(Self.placeholder)
                            .font(.body).fontDesign(.rounded)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $draft)
                        .font(.body).fontDesign(.rounded)
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                        .onChange(of: draft) { _, newValue in
                            if newValue.count > Self.maxChars {
                                draft = String(newValue.prefix(Self.maxChars))
                            }
                        }
                }
                .padding(8)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("\(draft.count)/\(Self.maxChars)")
                    .font(.caption).fontDesign(.rounded)
                    .foregroundStyle(VGTheme.muted)
            }

            if hasChanges {
                Button("Save Note") {
                    saveNote()
                }
                .font(.body.weight(.semibold))
                .fontDesign(.rounded)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if showSaved {
                Text("Saved")
                    .font(.caption.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.sage)
                    .transition(.opacity)
            }
        }
        .onAppear {
            draft = todayEntry?.note ?? ""
            lastSavedNote = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func saveNote() {
        let sanitized = InputSanitizer.sanitize(draft)
        let trimmed = String(sanitized.prefix(Self.maxChars))
        if let entry = todayEntry {
            entry.note = trimmed
            entry.timestamp = Date()
        } else {
            let entry = NutritionEntry()
            entry.id = UUID()
            entry.date = Calendar.current.startOfDay(for: Date())
            entry.userChallengeID = userChallenge.id
            entry.note = trimmed
            entry.timestamp = Date()
            modelContext.insert(entry)
        }
        try? modelContext.save()
        lastSavedNote = trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
        withAnimation(.easeInOut(duration: 0.2)) { showSaved = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) { showSaved = false }
            }
        }
    }
}
