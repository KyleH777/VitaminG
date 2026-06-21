import SwiftUI

struct Step3DetailsScreen: View {
    @Bindable var wizardVM: GoalCreationWizardViewModel
    let onSave: () -> Void

    // MARK: - Duration picker state

    private enum DurationOption: CaseIterable {
        case week, month, threeMonths, custom

        var label: String {
            switch self {
            case .week:        return "1 week"
            case .month:       return "1 month"
            case .threeMonths: return "3 months"
            case .custom:      return "Custom"
            }
        }

        var days: Int? {
            switch self {
            case .week:        return 7
            case .month:       return 30
            case .threeMonths: return 90
            case .custom:      return nil
            }
        }
    }

    @State private var durationSelection: DurationOption = .month
    @State private var customDurationText: String = ""
    @State private var customDurationError: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerText
                durationSection
                tierSection
                frequencySection
                if wizardVM.selectedFrequency != .onetime { reminderSection }
                privacySection
                legacySection
                encouragementCard
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(VGTheme.sandLight.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { saveButton }
        .onAppear {
            // Sync duration picker from existing draftDurationDays (edit mode or premade pre-fill)
            switch wizardVM.draftDurationDays {
            case 7:  durationSelection = .week
            case 30: durationSelection = .month
            case 90: durationSelection = .threeMonths
            case let d where d != nil:
                durationSelection = .custom
                customDurationText = "\(d!)"
            default:
                durationSelection = .month
                wizardVM.draftDurationDays = 30
            }
        }
    }

    private var headerText: some View {
        VStack(alignment: .leading, spacing: 6) {
            stepDots
            Text("When &\nhow often?")
                .font(.custom("CormorantGaramond-Regular", size: 34))
                .foregroundStyle(VGTheme.clay)
        }
    }

    private var stepDots: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill(VGTheme.terra)
                    .frame(width: i == 2 ? 22 : 8, height: 8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step 3 of 3")
    }

    // MARK: - Duration section

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("HOW LONG?")

            Picker("Duration", selection: $durationSelection) {
                ForEach(DurationOption.allCases, id: \.self) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: durationSelection) { _, newOption in
                customDurationError = nil
                if let days = newOption.days {
                    wizardVM.draftDurationDays = days
                    customDurationText = ""
                } else {
                    // Custom: clear until user enters a value
                    wizardVM.draftDurationDays = nil
                }
            }

            if durationSelection == .custom {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        TextField("e.g. 45", text: $customDurationText)
                            .keyboardType(.numberPad)
                            .font(.system(size: 16))
                            .foregroundStyle(VGTheme.textPrimary)
                            .onChange(of: customDurationText) { _, text in
                                validateAndApplyCustomDuration(text)
                            }
                        Text("days")
                            .font(.system(size: 14))
                            .foregroundStyle(VGTheme.textMuted)
                    }
                    .padding(14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)

                    if let error = customDurationError {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.red)
                            .padding(.leading, 4)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.2), value: durationSelection)
            }
        }
    }

    private func validateAndApplyCustomDuration(_ text: String) {
        guard !text.isEmpty else {
            wizardVM.draftDurationDays = nil
            customDurationError = nil
            return
        }
        if let days = Int(text) {
            if days >= 1 && days <= 365 {
                wizardVM.draftDurationDays = days
                customDurationError = nil
            } else {
                wizardVM.draftDurationDays = nil
                customDurationError = "Enter a value between 1 and 365 days"
            }
        } else {
            wizardVM.draftDurationDays = nil
            customDurationError = "Enter a whole number"
        }
    }

    private var isDurationValid: Bool {
        if durationSelection == .custom {
            return customDurationError == nil && wizardVM.draftDurationDays != nil
        }
        return wizardVM.draftDurationDays != nil
    }

    private var tierSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Tier")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(GoalTier.ordered, id: \.self) { tier in
                    TierOptionCard(tier: tier, isSelected: wizardVM.draftTier == tier) {
                        wizardVM.draftTier = tier
                    }
                }
            }
        }
    }

    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("How often")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(GoalFrequency.allCases) { freq in
                    FrequencyCard(frequency: freq, isSelected: wizardVM.selectedFrequency == freq) {
                        wizardVM.selectedFrequency = freq
                    }
                }
            }
        }
    }

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Daily nudge")
            HStack(spacing: 12) {
                Text("🔔").font(.title2)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    DatePicker("Reminder time", selection: $wizardVM.draftReminderTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .accessibilityLabel("Daily reminder time")
                    Text("A gentle reminder, not a guilt trip")
                        .font(.caption).foregroundStyle(VGTheme.muted)
                }
                Spacer()
                Toggle("Enable daily reminder", isOn: $wizardVM.reminderEnabled)
                    .labelsHidden()
                    .accessibilityLabel("Enable daily reminder")
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)
        }
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Privacy")
            HStack(spacing: 12) {
                Text(wizardVM.isPrivate ? "🔒" : "🌍").font(.title3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(wizardVM.isPrivate ? "Keep this private" : "Share with community")
                        .font(.subheadline).fontWeight(.semibold).foregroundStyle(VGTheme.clay)
                    Text(wizardVM.isPrivate ? "Only you can see this goal" : "Friends can cheer you on")
                        .font(.caption).foregroundStyle(VGTheme.muted)
                }
                Spacer()
                Toggle("Share with community", isOn: Binding(
                    get: { !wizardVM.isPrivate },
                    set: { wizardVM.isPrivate = !$0 }
                ))
                .labelsHidden()
                .accessibilityLabel("Share with community")
                .accessibilityValue(wizardVM.isPrivate ? "Off, goal is private" : "On, goal is shared")
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)
        }
    }

    private var legacySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Already started?")
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Text("📅").font(.title3)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("I've been working on this")
                            .font(.subheadline).fontWeight(.semibold).foregroundStyle(VGTheme.clay)
                        Text("Set the real start date").font(.caption).foregroundStyle(VGTheme.muted)
                    }
                    Spacer()
                    Toggle("I've been working on this", isOn: $wizardVM.isLegacy)
                        .labelsHidden()
                        .accessibilityLabel("I've already started working on this goal")
                .padding(14)
                if wizardVM.isLegacy {
                    Divider().padding(.horizontal, 14)
                    HStack {
                        Text("Start date").font(.caption).foregroundStyle(VGTheme.muted)
                        Spacer()
                        DatePicker("", selection: $wizardVM.draftStartDate, in: ...Date.now, displayedComponents: .date)
                            .labelsHidden()
                    }
                    .padding(14)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)
            .animation(.easeInOut(duration: 0.2), value: wizardVM.isLegacy)
        }
    }

    private var encouragementCard: some View {
        HStack(spacing: 12) {
            Text("🎉").font(.largeTitle)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("You're about to set a goal.")
                    .font(.custom("CormorantGaramond-SemiBold", size: 16)).foregroundStyle(VGTheme.clay)
                Text("That's already further than most people get. We're rooting for you.")
                    .font(.caption).foregroundStyle(VGTheme.muted)
            }
        }
        .padding(16)
        .background(VGTheme.terraLight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(VGTheme.terraSoft, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private var saveButton: some View {
        Button(action: onSave) {
            Text(wizardVM.isEditMode ? "Save changes" : "Start this journey ✨")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isDurationValid ? VGTheme.terra : VGTheme.terra.opacity(0.4))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!isDurationValid)
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.caption).fontWeight(.bold).textCase(.uppercase)
            .foregroundStyle(VGTheme.muted).tracking(1)
    }
}

private struct TierOptionCard: View {
    let tier: GoalTier
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Label(tier.displayName, systemImage: tier.icon)
                    .font(.custom("CormorantGaramond-SemiBold", size: 15))
                    .foregroundStyle(isSelected ? tier.color : VGTheme.clay)
                Text(tier.description)
                    .font(.caption2).foregroundStyle(VGTheme.muted).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 44)
            .padding(12)
            .background(isSelected ? Color.white : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(
                isSelected ? tier.color : VGTheme.sandMid, lineWidth: 2))
            .shadow(color: isSelected ? tier.color.opacity(0.2) : .clear, radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(tier.displayName): \(tier.description)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

private struct FrequencyCard: View {
    let frequency: GoalFrequency
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(frequency.rawValue)
                    .font(.custom("CormorantGaramond-SemiBold", size: 16))
                    .foregroundStyle(isSelected ? VGTheme.terra : VGTheme.clay)
                Text(frequency.subtitle).font(.caption2).foregroundStyle(VGTheme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 44)
            .padding(12)
            .background(isSelected ? Color.white : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(
                isSelected ? VGTheme.terra : VGTheme.sandMid, lineWidth: 2))
            .shadow(color: isSelected ? VGTheme.terra.opacity(0.18) : .clear, radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(frequency.rawValue): \(frequency.subtitle)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
