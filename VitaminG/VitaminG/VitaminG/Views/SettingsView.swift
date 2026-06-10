import SwiftUI
import SwiftData
import UserNotifications

// MARK: - SettingsView

/// Notification settings screen allowing the user to change the daily reminder time (NOTIF-06).
/// Time change triggers immediate reschedule of the notification (NOTIF-06, NOTIF-02).
/// Uses @Query to fetch active goals so the rescheduled notification body stays current (NOTIF-03).
/// Plan 19-04: Adds Appearance (dark mode picker), Privacy (public profile toggle),
/// and Support (contact mailto + About navigation) sections (SET-03, SET-04, SET-05).
///
/// Authorization flow:
/// - .notDetermined → "Enable Notifications" button that triggers system permission dialog.
/// - .denied        → "Open Settings" button that deep-links to the system Settings app.
/// - .authorized    → DatePicker active; shows "Enabled" status row.
struct SettingsView: View {

    // MARK: - Static Constants

    /// T-19-04-01: mailto URL string extracted as static let so tests can reference it without
    /// instantiating the view. The URL is always guarded with `if let` before use — no force-unwrap.
    static let supportMailtoURLString = "mailto:VitaminG.info@gmail.com?subject=Vitamin%20G%20Support"

    // MARK: - Queries and Environment

    @Query(filter: #Predicate<Goal> { $0.isCompleted == false })
    private var activeGoals: [Goal]

    @Query private var allEvents: [CompletionEvent]

    private var globalStreak: Int {
        StreakEngine.currentStreak(from: allEvents)
    }

    // MARK: - State

    @State private var notificationTime: Date = {
        var components = DateComponents()
        components.hour = NotificationPreferences.hour
        components.minute = NotificationPreferences.minute
        return Calendar.current.date(from: components) ?? Date()
    }()

    @State private var winNotificationTime: Date = {
        var components = DateComponents()
        components.hour = NotificationPreferences.winHour
        components.minute = NotificationPreferences.winMinute
        return Calendar.current.date(from: components) ?? Date()
    }()

    /// Full authorization status so the UI can distinguish notDetermined / denied / authorized.
    @State private var authStatus: UNAuthorizationStatus = .notDetermined

    /// NOTIF-03: true when modalCheckInHour differs from current hour by >= 2 and not yet dismissed.
    @State private var showNudgeSuggestion: Bool = false
    @State private var suggestedHour: Int = 0

    /// ProfileViewModel for Privacy toggle — loads/creates profile in .onAppear (Pitfall 7).
    @State private var profileVM = ProfileViewModel()

    // MARK: - App Storage and Environment

    /// SET-04: appearance preference bound to segmented picker; applied app-wide by VitaminGApp.
    @AppStorage("vg_colorScheme") private var colorSchemePref: ColorSchemePreference = .system

    /// SwiftUI environment URL opener — avoids importing UIKit for openSettingsURLString.
    @Environment(\.openURL) private var openURL

    /// SwiftData model context for ProfileViewModel calls.
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Form {
            if globalStreak > 0 {
                Section {
                    VStack(spacing: 8) {
                        Text("\(globalStreak)")
                            .font(.largeTitle.bold().monospacedDigit())
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        VGTheme.accentTerra,
                                        VGTheme.accentPurple
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text(globalStreak == 1 ? "day streak" : "days streak")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(globalStreak) \(globalStreak == 1 ? "day" : "days") streak")
                }
            } else {
                Section {
                    Text("Start completing goals to build your streak")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }

            Section("Daily Reminder") {
                // NOTIF-03: suggestion banner — shown when modal check-in hour differs from
                // current reminder hour by >= 2 and the user has not yet dismissed it.
                if showNudgeSuggestion {
                    nudgeSuggestionBanner
                }

                DatePicker(
                    "Reminder Time",
                    selection: $notificationTime,
                    displayedComponents: .hourAndMinute
                )
                .disabled(!isAuthorized)
                .onChange(of: notificationTime) { _, newValue in
                    let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                    let hour = components.hour ?? NotificationPreferences.defaultHour
                    let minute = components.minute ?? NotificationPreferences.defaultMinute
                    NotificationPreferences.save(hour: hour, minute: minute)
                    Task {
                        await NotificationScheduler.shared.reschedule(activeGoals: Array(activeGoals), completionEvents: Array(allEvents))
                    }
                }

                authorizationRow
            }

            Section {
                Text("Your notification will include up to 2 of your active goal titles as a daily reminder.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Win Reminder") {
                DatePicker(
                    "Reminder Time",
                    selection: $winNotificationTime,
                    displayedComponents: .hourAndMinute
                )
                .disabled(!isAuthorized)
                .onChange(of: winNotificationTime) { _, newValue in
                    let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                    let hour = components.hour ?? NotificationPreferences.defaultWinHour
                    let minute = components.minute ?? NotificationPreferences.defaultWinMinute
                    NotificationPreferences.saveWinTime(hour: hour, minute: minute)
                    Task { await NotificationScheduler.shared.rescheduleWinReminder() }
                }

                // WR-05: authorizationRow lives only in the Daily Reminder section above —
                // it covers BOTH notifications since UNAuthorizationStatus is per-app, not
                // per-notification-identifier. Duplicating it here meant two simultaneous
                // "Enable Notifications" buttons could race the system permission dialog.
            }

            Section {
                Text("A daily reminder to reflect on your wins.")
                    .font(.footnote).fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }

            // SET-04: Appearance section — segmented picker bound to vg_colorScheme @AppStorage.
            // Picker change applies immediately app-wide via VitaminGApp.preferredColorScheme.
            Section("Appearance") {
                Picker("Appearance", selection: $colorSchemePref) {
                    ForEach(ColorSchemePreference.allCases, id: \.self) { pref in
                        Text(pref.displayName).tag(pref)
                    }
                }
                .pickerStyle(.segmented)
            }

            // SET-03: Privacy section — toggles profile.isPublic via ProfileViewModel.
            // If profile is nil (still loading), renders a disabled placeholder row.
            Section("Privacy") {
                if let profile = profileVM.profile {
                    Toggle("Public Profile", isOn: Binding(
                        get: { profile.isPublic },
                        set: { _ in
                            profileVM.toggleProfilePublic(context: modelContext)
                        }
                    ))
                } else {
                    Toggle("Public Profile", isOn: .constant(false))
                        .disabled(true)
                }

                let bioService = BiometricLockService.shared
                @Bindable var bindableBioService = bioService
                Toggle("Require Face ID / Touch ID", isOn: $bindableBioService.isEnabled)
            }

            // SET-05: Support section — contact mailto (T-19-04-01: guarded if let)
            // and NavigationLink to AboutView (D-01, D-12).
            Section("Support") {
                Button("Contact Support") {
                    // T-19-04-01: never force-unwrap the mailto URL — always use if let
                    if let url = URL(string: Self.supportMailtoURLString) {
                        openURL(url)
                    }
                }
                .foregroundStyle(VGTheme.accentTerra)

                NavigationLink("About Vitamin G") {
                    AboutView()
                }
            }

            DeleteAccountSection()
        }
        .navigationTitle("Settings")
        .onAppear {
            // Sync notification time to App Group UserDefaults for widget access (D-06, Pitfall 3)
            let components = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
            NotificationPreferences.save(
                hour: components.hour ?? NotificationPreferences.defaultHour,
                minute: components.minute ?? NotificationPreferences.defaultMinute
            )
            // Load or create the user profile for the Privacy toggle (Pitfall 7)
            profileVM.loadOrCreateProfile(context: modelContext)
            // NOTIF-03: compute modal check-in hour and show suggestion banner if warranted.
            // Requires >= 14 history entries (D-10) to ensure the modal is statistically meaningful.
            if NotificationPreferences.checkInHourHistory().count >= 14,
               !NotificationPreferences.nudgeSuggestionDismissed,
               let modal = NotificationPreferences.modalCheckInHour() {
                let currentHour = NotificationPreferences.hour
                let diff = abs(modal - currentHour)
                let circularDiff = min(diff, 24 - diff)
                if circularDiff >= 2 {
                    suggestedHour = modal
                    showNudgeSuggestion = true
                }
            }
        }
        .task {
            await refreshAuthStatus()
        }
    }

    // MARK: - Authorization Row

    /// Renders the appropriate status row based on the current UNAuthorizationStatus.
    @ViewBuilder
    private var authorizationRow: some View {
        switch authStatus {
        case .notDetermined:
            Button("Enable Notifications") {
                Task {
                    let granted = await NotificationScheduler.shared.requestAuthorization()
                    authStatus = granted ? .authorized : .denied
                    if granted {
                        await NotificationScheduler.shared.reschedule(activeGoals: Array(activeGoals), completionEvents: Array(allEvents))
                    }
                }
            }
        case .denied:
            HStack {
                Text("Notifications Disabled")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Open Settings") {
                    // UIApplication.openSettingsURLString = "app-settings:"
                    if let url = URL(string: "app-settings:") {
                        openURL(url)
                    }
                }
                .font(.callout)
                .foregroundStyle(.orange)
            }
        default:
            // .authorized, .provisional, .ephemeral
            HStack {
                Text("Status")
                Spacer()
                Text("Enabled")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Nudge Suggestion Banner

    /// NOTIF-03: inline banner prompting the user to shift their reminder to their modal check-in hour.
    @ViewBuilder
    private var nudgeSuggestionBanner: some View {
        let formattedHour: String = {
            var components = DateComponents()
            components.hour = suggestedHour
            components.minute = 0
            let date = Calendar.current.date(from: components) ?? Date()
            return date.formatted(date: .omitted, time: .shortened)
        }()

        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Suggested Time")
                    .font(.subheadline.bold())
                Text("You usually check in around \(formattedHour). Switch your reminder to match?")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(spacing: 6) {
                Button("Apply") {
                    // Write the new hour (minute stays 0), update the picker, reschedule, dismiss.
                    NotificationPreferences.save(hour: suggestedHour, minute: 0)
                    var comps = DateComponents()
                    comps.hour = suggestedHour
                    comps.minute = 0
                    notificationTime = Calendar.current.date(from: comps) ?? notificationTime
                    NotificationPreferences.markNudgeSuggestionDismissed()
                    showNudgeSuggestion = false
                    Task {
                        await NotificationScheduler.shared.reschedule(activeGoals: Array(activeGoals), completionEvents: Array(allEvents))
                    }
                }
                .font(.footnote.bold())
                .buttonStyle(.borderedProminent)
                .tint(VGTheme.accentTerra)

                Button {
                    NotificationPreferences.markNudgeSuggestionDismissed()
                    showNudgeSuggestion = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private var isAuthorized: Bool {
        switch authStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    /// Fetches the current authorization status from the system and updates `authStatus`.
    private func refreshAuthStatus() async {
        authStatus = await NotificationScheduler.shared.authorizationStatus()
    }
}
