import SwiftUI
import SwiftData

// MARK: - ChallengeDetailView

/// Challenge progress screen (CHAL-09, CHAL-11, D-09, D-10).
/// Shows header, check-in CTA, progress section, StreakChainView, reminder picker,
/// description, and abandon flow. MilestoneCelebrationView wired in Plan 06.
struct ChallengeDetailView: View {
    let userChallenge: UserChallenge

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = ChallengeViewModel()
    @State private var showCheckIn = false
    @State private var showAbandonDialog = false
    @State private var showMilestoneCelebration = false
    @State private var currentMilestone: (challengeID: UUID, threshold: Int)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerBlock
                checkInCTA
                    .padding(.top, 16)
                progressSection
                    .padding(.top, 8)
                StreakChainView(
                    checkInDates: (userChallenge.checkIns ?? []).compactMap { $0.date },
                    accentColor: accentColor
                )
                .padding(.top, 12)
                reminderSection
                    .padding(.top, 16)
                descriptionSection
                    .padding(.top, 24)
                abandonButton
                    .padding(.top, 32)
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(VGTheme.sandLight)
        .navigationTitle(userChallenge.template?.title ?? "Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCheckIn) {
            ChallengeCheckInView(userChallenge: userChallenge, viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showMilestoneCelebration) {
            if let milestone = currentMilestone {
                MilestoneCelebrationView(
                    userChallenge: userChallenge,
                    threshold: milestone.threshold,
                    onDismiss: { showMilestoneCelebration = false }
                )
            }
        }
        .onChange(of: viewModel.pendingMilestone?.challengeID) { _, _ in
            if let m = viewModel.pendingMilestone {
                currentMilestone = m
                viewModel.pendingMilestone = nil
                showMilestoneCelebration = true
            }
        }
        .confirmationDialog(
            "Abandon this challenge?",
            isPresented: $showAbandonDialog,
            titleVisibility: .visible
        ) {
            Button("Abandon", role: .destructive) {
                viewModel.abandonChallenge(userChallenge, context: modelContext)
            }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("Your progress will not be deleted, but your streak will end.")
        }
    }

    // MARK: - Header Block

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(userChallenge.template?.title ?? "Challenge")
                .font(.title2)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.clay)
            if let category = userChallenge.template?.category,
               let days = userChallenge.template?.durationDays {
                Text("\(category.capitalized) · \(days) days")
                    .font(.caption)
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.muted)
            }
        }
    }

    // MARK: - Check-in CTA

    private var checkInCTA: some View {
        Group {
            if todayAlreadyCheckedIn {
                Button(action: {}) {
                    Label("Checked In Today", systemImage: "checkmark.circle.fill")
                        .font(.body)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(VGTheme.sage.opacity(0.6))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(true)
                .accessibilityLabel("Already checked in for today")
            } else {
                Button("Log Today's Check-In") { showCheckIn = true }
                    .font(.body)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if userChallenge.template?.goalType == "dateBound" {
                Text("Days Alcohol-Free")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.clay)
                Text("\(userChallenge.totalCheckIns)")
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .foregroundStyle(accentColor)
                    .accessibilityLabel("\(userChallenge.totalCheckIns) days alcohol-free")
            } else {
                Text("Progress Toward Goal")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.clay)
                ProgressView(value: progressValue)
                    .progressViewStyle(.linear)
                    .tint(accentColor)
                    .frame(height: 8)
                    .accessibilityLabel("Progress: \(Int((progressValue * 100).rounded()))% toward goal")
            }
        }
    }

    // MARK: - Reminder Section

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Evening Reminder")
                .font(.title2)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.clay)
            HStack {
                Text(reminderLabel)
                    .font(.body)
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.muted)
                Spacer()
                DatePicker("", selection: reminderBinding, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About This Challenge")
                .font(.title2)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.clay)
            Text(userChallenge.template?.challengeDescription ?? "")
                .font(.body)
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.clay)
        }
    }

    // MARK: - Abandon Button

    private var abandonButton: some View {
        Button("Abandon Challenge") { showAbandonDialog = true }
            .font(.body)
            .fontDesign(.rounded)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, minHeight: 44)
    }

    // MARK: - Computed Helpers

    private var accentColor: Color {
        Color(hex: userChallenge.template?.accentColorHex ?? "#C4673A")
    }

    private var todayAlreadyCheckedIn: Bool {
        viewModel.todayCheckIn(for: userChallenge, context: modelContext) != nil
    }

    private var progressValue: Double {
        let total = userChallenge.template?.durationDays ?? 90
        return min(1.0, Double(userChallenge.totalCheckIns) / Double(total))
    }

    private var reminderLabel: String {
        guard let h = userChallenge.reminderHour, let m = userChallenge.reminderMinute else {
            return "Off"
        }
        return String(format: "%02d:%02d", h, m)
    }

    private var reminderBinding: Binding<Date> {
        Binding<Date>(
            get: {
                var components = DateComponents()
                components.hour = userChallenge.reminderHour ?? 20
                components.minute = userChallenge.reminderMinute ?? 0
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                let h = comps.hour ?? 20
                let m = comps.minute ?? 0
                userChallenge.reminderHour = h
                userChallenge.reminderMinute = m
                Task {
                    await NotificationScheduler.shared.scheduleChallengeReminder(
                        for: userChallenge, hour: h, minute: m
                    )
                }
            }
        )
    }
}
