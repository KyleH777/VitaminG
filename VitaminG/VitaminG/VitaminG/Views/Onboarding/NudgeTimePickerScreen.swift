import SwiftUI

// MARK: - NudgeTimePickerScreen
// Onboarding Screen 6 (conditional — shown only when notification permission granted, D-13).
// 5 quick-select AM chips (6-10), optional custom DatePicker, Skip link.
// D-14: Skip advances without saving. D-15: 8 AM pre-selected (NotificationPreferences.defaultHour).

struct NudgeTimePickerScreen: View {

    @Binding var path: [OnboardingStep]
    let onSkip: () -> Void

    @State private var selectedHour: Int = NotificationPreferences.defaultHour
    @State private var showCustomPicker: Bool = false
    @State private var customTime: Date = {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()

    private let quickHours = [6, 7, 8, 9, 10]

    var body: some View {
        VGTheme.sandLight.ignoresSafeArea()
            .overlay(
                VStack(alignment: .leading, spacing: 0) {
                    // Step bar
                    StepBarView(current: 6, total: 8)
                        .padding(.top, 16)
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 32)

                    // Heading
                    Text("Pick your morning nudge time")
                        .font(VGTheme.serif(34))
                        .foregroundStyle(VGTheme.textPrimary)
                        .padding(.horizontal, 24)
                        .accessibilityAddTraits(.isHeader)

                    Spacer().frame(height: 17)

                    // Subheading
                    Text("When should we check in with you each day?")
                        .font(.callout)
                        .foregroundStyle(VGTheme.textMuted)
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 32)

                    // Hour chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(quickHours, id: \.self) { hour in
                                let isSelected = !showCustomPicker && selectedHour == hour
                                Button {
                                    selectedHour = hour
                                    showCustomPicker = false
                                } label: {
                                    Text("\(hour) AM")
                                        .font(.callout.weight(.medium))
                                        .foregroundStyle(isSelected ? VGTheme.warmWhite : VGTheme.textPrimary)
                                        .padding(.horizontal, 16)
                                        .frame(minHeight: 44)
                                        .background(isSelected ? VGTheme.accentTerra : VGTheme.surface)
                                        .clipShape(Capsule())
                                }
                                .accessibilityLabel("\(hour) AM")
                                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer().frame(height: 24)

                    // Custom time toggle
                    Toggle("Custom time", isOn: $showCustomPicker)
                        .font(.body)
                        .foregroundStyle(VGTheme.textPrimary)
                        .padding(.horizontal, 24)

                    if showCustomPicker {
                        DatePicker("", selection: $customTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .padding(.horizontal, 24)
                    }

                    Spacer()
                }
            )
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    Button(action: save) {
                        Text("Set my nudge time")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(VGTheme.accentTerra)
                            .foregroundStyle(VGTheme.warmWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button(action: skip) {
                        Text("Skip for now")
                            .font(.callout)
                            .foregroundStyle(VGTheme.textMuted)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
                .background(VGTheme.sandLight)
            }
            .navigationBarHidden(true)
    }

    // MARK: - Actions

    private func save() {
        let finalHour: Int
        let finalMinute: Int

        if showCustomPicker {
            let components = Calendar.current.dateComponents([.hour, .minute], from: customTime)
            finalHour = components.hour ?? NotificationPreferences.defaultHour
            finalMinute = components.minute ?? NotificationPreferences.defaultMinute
        } else {
            finalHour = selectedHour
            finalMinute = 0
        }

        NotificationPreferences.save(hour: finalHour, minute: finalMinute)
        Task { await NotificationScheduler.shared.reschedule(activeGoals: [], completionEvents: []) } // Plan 03: wire real completionEvents
        path.append(.cameraPermission)
    }

    /// D-14: Skip does NOT save — keeps the existing default.
    private func skip() {
        path.append(.cameraPermission)
    }
}
