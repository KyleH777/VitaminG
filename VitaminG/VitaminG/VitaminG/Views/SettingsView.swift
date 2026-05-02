import SwiftUI
import SwiftData
import UserNotifications

// MARK: - SettingsView

/// Notification settings screen allowing the user to change the daily reminder time (NOTIF-06).
/// Time change triggers immediate reschedule of the notification (NOTIF-06, NOTIF-02).
/// Uses @Query to fetch active goals so the rescheduled notification body stays current (NOTIF-03).
///
/// Authorization flow:
/// - .notDetermined → "Enable Notifications" button that triggers system permission dialog.
/// - .denied        → "Open Settings" button that deep-links to the system Settings app.
/// - .authorized    → DatePicker active; shows "Enabled" status row.
struct SettingsView: View {

    @Query(filter: #Predicate<Goal> { $0.isCompleted == false })
    private var activeGoals: [Goal]

    @Query private var allEvents: [CompletionEvent]

    private var globalStreak: Int {
        StreakEngine.currentStreak(from: allEvents)
    }

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

    /// SwiftUI environment URL opener — avoids importing UIKit for openSettingsURLString.
    @Environment(\.openURL) private var openURL

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
                                        Color(red: 0.98, green: 0.55, blue: 0.27),
                                        Color(red: 0.78, green: 0.48, blue: 0.95)
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
                    // Persist to both standard and App Group UserDefaults (NOTIF-06, D-06)
                    NotificationPreferences.save(hour: hour, minute: minute)
                    // Reschedule immediately with updated time (NOTIF-06, NOTIF-03)
                    Task {
                        await NotificationScheduler.shared.reschedule(activeGoals: Array(activeGoals))
                    }
                }

                authorizationRow
            }

            Section {
                Text("Your notification will include up to 3 of your active goal titles as a daily reminder.")
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

                authorizationRow
            }

            Section {
                Text("A daily reminder to reflect on your wins.")
                    .font(.footnote).fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            // Sync notification time to App Group UserDefaults for widget access (D-06, Pitfall 3)
            let components = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
            NotificationPreferences.save(
                hour: components.hour ?? NotificationPreferences.defaultHour,
                minute: components.minute ?? NotificationPreferences.defaultMinute
            )
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
                        await NotificationScheduler.shared.reschedule(activeGoals: Array(activeGoals))
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
