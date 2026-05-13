import SwiftUI
import SwiftData

struct SpendingFreezeModuleView: View {
    let userChallenge: UserChallenge

    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [SpendingFreezeEntry]

    private var todayEntry: SpendingFreezeEntry? {
        let challengeID = userChallenge.id
        let cal = Calendar.current
        return allEntries.first { entry in
            guard entry.userChallengeID == challengeID,
                  let date = entry.date else { return false }
            return cal.isDateInToday(date)
        }
    }

    private var isFreeze: Bool { todayEntry?.isFreeze ?? false }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "snowflake")
                    .font(.title3)
                    .foregroundStyle(VGTheme.clay)
                Text("Spending Freeze")
                    .font(.title2.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.clay)
                Spacer()
            }

            Toggle(isOn: Binding(
                get: { isFreeze },
                set: { newValue in updateFreeze(to: newValue) }
            )) {
                Text("Stayed spending-free today?")
                    .font(.body)
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.clay)
            }
            .accessibilityLabel("Stayed spending-free today, \(isFreeze ? "on" : "off")")
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if isFreeze {
                Label("Freeze Active", systemImage: "snowflake.fill")
                    .font(.caption.weight(.semibold))
                    .fontDesign(.rounded)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(VGTheme.sage.opacity(0.2))
                    .foregroundStyle(VGTheme.sage)
                    .clipShape(Capsule())
            }
        }
    }

    private func updateFreeze(to newValue: Bool) {
        if let entry = todayEntry {
            entry.isFreeze = newValue
            entry.timestamp = Date()
        } else {
            let entry = SpendingFreezeEntry()
            entry.id = UUID()
            entry.date = Calendar.current.startOfDay(for: Date())
            entry.userChallengeID = userChallenge.id
            entry.isFreeze = newValue
            entry.timestamp = Date()
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }
}
