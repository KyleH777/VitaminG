import SwiftUI
import SwiftData

// MARK: - CustomChallengeBuilderView (CHAL-23)

/// Two-step NavigationStack sheet that lets the user configure a new ChallengeTemplate
/// using the same data shape as featured challenges.
///
/// Step 1 — "The Basics": name, category, privacy, accent color.
/// Step 2 — "Check-In & Goal": check-in type, goal type, goal-specific inputs, duration.
///
/// On "Create Challenge" a ChallengeTemplate with challengeType="custom" is inserted into
/// the SwiftData context and saved (T-14-34: InputSanitizer on text fields; T-14-36: privacy
/// defaults to "private"; T-14-37: end-date validation at create time).
struct CustomChallengeBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Step State
    @State private var currentStep: Int = 1

    // MARK: - Step 1 State
    @State private var name: String = ""
    @State private var category: String = "fitness"
    @State private var isCommunity: Bool = false
    @State private var accentColorHex: String = "#C4673A"  // terra default (T-14-36)

    // MARK: - Step 2 State
    @State private var checkInType: String = "boolean"
    @State private var goalType: String = "streak"
    @State private var streakDays: Int = 30
    @State private var targetValueText: String = ""
    @State private var targetUnit: String = ""
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
    @State private var durationDays: Int = 30
    @State private var selectedModules: Set<ChallengeTemplate.ModuleIdentifier> = []

    // MARK: - Validation
    @State private var validationError: String? = nil

    // MARK: - Static Data

    private static let categories: [(label: String, value: String)] = [
        ("Fitness",     "fitness"),
        ("Finance",     "finance"),
        ("Sobriety",    "sobriety"),
        ("Mindfulness", "mindfulness"),
        ("Custom",      "custom")
    ]

    /// 5 accent swatches required by UI-SPEC.
    private static let accentSwatches: [(name: String, hex: String)] = [
        ("Terra",  "#C4673A"),
        ("Sage",   "#7A9B76"),
        ("Gold",   "#C9A24F"),
        ("Purple", "#7E5BAA"),
        ("Blue",   "#4A90E2")
    ]

    // MARK: - Computed Validation

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isStep1Valid: Bool { !trimmedName.isEmpty }

    /// Step 2 validity — per-goal-type check (T-14-37).
    private var isStep2Valid: Bool {
        switch goalType {
        case "streak":    return true
        case "target":    return !targetValueText.trimmingCharacters(in: .whitespaces).isEmpty
                              && Double(targetValueText) != nil
        case "dateBound": return endDate > .now
        default:          return false
        }
    }

    private var accentColor: Color { Color(hex: accentColorHex) }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Step indicator
                Section {
                    Text("Step \(currentStep) of 2")
                        .font(.caption.weight(.regular))
                        .fontDesign(.rounded)
                        .foregroundStyle(VGTheme.muted)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                if currentStep == 1 {
                    step1Sections
                } else {
                    step2Sections
                }

                // Inline validation error (displayed below offending content)
                if let error = validationError {
                    Section {
                        Text(error)
                            .font(.caption)
                            .fontDesign(.rounded)
                            .foregroundStyle(.red)
                    }
                }

                // Create Challenge CTA — Step 2 only
                if currentStep == 2 {
                    Section {
                        Button("Create Challenge") { createChallenge() }
                            .font(.body.weight(.semibold))
                            .fontDesign(.rounded)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(isStep1Valid && isStep2Valid ? accentColor : VGTheme.muted)
                            .foregroundStyle(VGTheme.warmWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .disabled(!isStep1Valid || !isStep2Valid)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(VGTheme.sandLight)
            .navigationTitle("Build Your Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Leading: Discard Builder (NOT "Cancel" — UI-SPEC copy contract)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Discard Builder") { dismiss() }
                        .font(.body)
                        .fontDesign(.rounded)
                        .foregroundStyle(VGTheme.clay)
                }

                // Trailing: Next (Step 1) or Back (Step 2)
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentStep == 1 {
                        Button("Next") { advanceToStep2() }
                            .font(.body.weight(.semibold))
                            .fontDesign(.rounded)
                            .disabled(!isStep1Valid)
                    } else {
                        Button("Back") {
                            validationError = nil
                            currentStep = 1
                        }
                        .font(.body)
                        .fontDesign(.rounded)
                    }
                }
            }
        }
    }

    // MARK: - Step 1

    @ViewBuilder
    private var step1Sections: some View {
        Section("The Basics") {
            // Challenge Name — max 60 chars, T-14-34
            TextField("e.g., Daily Meditation, No Sugar Month", text: $name)
                .font(.body)
                .fontDesign(.rounded)
                .onChange(of: name) { _, newValue in
                    if newValue.count > 60 { name = String(newValue.prefix(60)) }
                }

            // Category picker
            Picker("Category", selection: $category) {
                ForEach(Self.categories, id: \.value) { item in
                    Text(item.label).tag(item.value)
                }
            }
            .pickerStyle(.menu)
            .font(.body)
            .fontDesign(.rounded)

            // Privacy toggle — "Just Me" / "Community" per UI-SPEC (NOT "Private/Public")
            Toggle(isOn: $isCommunity) {
                Text(isCommunity ? "Community" : "Just Me")
                    .font(.body)
                    .fontDesign(.rounded)
            }

            // Accent color swatches — 5 × 32pt circles with 2pt VGTheme.clay ring on selected
            HStack(spacing: 12) {
                Text("Accent Color")
                    .font(.body)
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.clay)
                Spacer()
                ForEach(Self.accentSwatches, id: \.hex) { swatch in
                    Button {
                        accentColorHex = swatch.hex
                    } label: {
                        Circle()
                            .fill(Color(hex: swatch.hex))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        accentColorHex == swatch.hex ? VGTheme.clay : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                            .accessibilityLabel(
                                "\(swatch.name)\(accentColorHex == swatch.hex ? ", selected" : "")"
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Step 2

    @ViewBuilder
    private var step2Sections: some View {
        Section("Check-In & Goal") {
            // Check-In Type — "Daily Yes/No" / "Enter a Number" / "Multi-Step"
            Picker("Check-In Type", selection: $checkInType) {
                Text("Daily Yes/No").tag("boolean")
                Text("Enter a Number").tag("numeric")
                Text("Multi-Step").tag("multiStep")
            }
            .pickerStyle(.segmented)

            // Goal Type — "Build a Streak" / "Reach a Target" / "End by a Date"
            Picker("Goal Type", selection: $goalType) {
                Text("Build a Streak").tag("streak")
                Text("Reach a Target").tag("target")
                Text("End by a Date").tag("dateBound")
            }
            .pickerStyle(.segmented)
            .onChange(of: goalType) { _, _ in validationError = nil }

            // Conditional goal-type inputs
            switch goalType {
            case "streak":
                Stepper("Target Days: \(streakDays)", value: $streakDays, in: 7...365)
                    .font(.body)
                    .fontDesign(.rounded)

            case "target":
                TextField("Goal Value", text: $targetValueText)
                    .keyboardType(.decimalPad)
                    .font(.body)
                    .fontDesign(.rounded)
                TextField("Unit (e.g. $, km, lbs)", text: $targetUnit)
                    .font(.body)
                    .fontDesign(.rounded)

            case "dateBound":
                let tomorrow: Date = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
                DatePicker(
                    "End Date",
                    selection: $endDate,
                    in: tomorrow...,
                    displayedComponents: [.date]
                )
                .font(.body)
                .fontDesign(.rounded)

            default:
                EmptyView()
            }

            // Duration (days) — always shown
            Stepper("Duration (days): \(durationDays)", value: $durationDays, in: 7...365)
                .font(.body)
                .fontDesign(.rounded)
        }
    }

    // MARK: - Navigation Helpers

    private func advanceToStep2() {
        guard isStep1Valid else {
            validationError = "Please enter a challenge name."
            return
        }
        validationError = nil
        currentStep = 2
    }

    // MARK: - Create Challenge

    private func createChallenge() {
        // Final validation before insert (T-14-37)
        guard isStep1Valid else {
            validationError = "Please enter a challenge name."
            currentStep = 1
            return
        }
        guard isStep2Valid else {
            switch goalType {
            case "target":
                validationError = Double(targetValueText) == nil
                    ? "Goal value must be a number."
                    : "Please enter a goal value."
            case "dateBound":
                validationError = "End date must be in the future."
            default:
                validationError = "Please complete the goal details."
            }
            return
        }

        let template = ChallengeTemplate()
        template.id = UUID()

        // T-14-34: sanitize free-text inputs
        template.title = InputSanitizer.sanitize(trimmedName)
        template.challengeDescription = nil
        template.category = category
        template.challengeType = "custom"
        template.checkInType = checkInType
        template.goalType = goalType
        template.durationDays = (goalType == "streak") ? streakDays : durationDays
        template.accentColorHex = accentColorHex
        template.iconName = "star.fill"
        template.isFeatured = false

        // T-14-36: privacy defaults to "private"; user must opt in to "community"
        template.privacy = isCommunity ? "community" : "private"

        // dateBound: store end date as activeUntil
        if goalType == "dateBound" {
            template.activeUntil = endDate
        }

        // Encode selected modules (may be empty for a basic custom challenge)
        let moduleArray = Array(selectedModules)
        template.enabledModulesJSON = ChallengeTemplate.encodeModules(moduleArray)

        // For streak goals: generate default milestone thresholds
        template.milestonesJSON = makeDefaultMilestonesJSON()

        modelContext.insert(template)
        do {
            try modelContext.save()
        } catch {
            VGLog.general.error("modelContext.save() failed: \(error.localizedDescription, privacy: .public)")
        }
        dismiss()
    }

    /// Generates default MilestoneConfig milestones for streak challenges.
    /// Mirrors the shape used by ChallengeTemplate+Featured.swift (dayThreshold, message, badgeSymbol).
    private func makeDefaultMilestonesJSON() -> String? {
        guard goalType == "streak" else { return nil }
        let thresholds = [7, 30, 90, streakDays].sorted()
        var seen = Set<Int>()
        let unique = thresholds.filter { seen.insert($0).inserted }
        let configs = unique.map { day in
            MilestoneConfig(
                dayThreshold: day,
                message: "Day \(day) — keep going!",
                badgeSymbol: "star.fill"
            )
        }
        guard let data = try? JSONEncoder().encode(configs),
              let json = String(data: data, encoding: .utf8) else { return nil }
        return json
    }
}
