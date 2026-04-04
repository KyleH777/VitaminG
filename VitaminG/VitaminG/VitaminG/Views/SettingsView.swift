import SwiftUI
import SwiftData

// MARK: - SettingsView

/// Notification settings screen allowing the user to change the daily reminder time (NOTIF-06).
/// Time change triggers immediate reschedule of the notification (NOTIF-06, NOTIF-02).
/// Uses @Query to fetch active goals so the rescheduled notification body stays current (NOTIF-03).
struct SettingsView: View {

    @Query(filter: #Predicate<Goal> { $0.isCompleted == false })
    private var activeGoals: [Goal]

    @State private var notificationTime: Date = {
        let hour: Int
        let minute: Int

        if UserDefaults.standard.object(forKey: "notificationHour") != nil {
            hour = UserDefaults.standard.integer(forKey: "notificationHour")
        } else {
            hour = 8 // Default: 8:00 AM (NOTIF-02)
        }

        if UserDefaults.standard.object(forKey: "notificationMinute") != nil {
            minute = UserDefaults.standard.integer(forKey: "notificationMinute")
        } else {
            minute = 0 // Default: :00 (NOTIF-02)
        }

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }()

    @State private var authorizationStatus: String = "Checking..."

    var body: some View {
        Form {
            Section("Daily Reminder") {
                DatePicker(
                    "Reminder Time",
                    selection: $notificationTime,
                    displayedComponents: .hourAndMinute
                )
                .onChange(of: notificationTime) { _, newValue in
                    let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                    let hour = components.hour ?? 8
                    let minute = components.minute ?? 0
                    // Persist user preference (NOTIF-06)
                    UserDefaults.standard.set(hour, forKey: "notificationHour")
                    UserDefaults.standard.set(minute, forKey: "notificationMinute")
                    // Reschedule immediately with updated time (NOTIF-06, NOTIF-03)
                    Task {
                        await NotificationScheduler.shared.reschedule(activeGoals: Array(activeGoals))
                    }
                }

                HStack {
                    Text("Status")
                    Spacer()
                    Text(authorizationStatus)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Text("Your notification will include up to 3 of your active goal titles as a daily reminder.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .task {
            let authorized = await NotificationScheduler.shared.isAuthorized()
            authorizationStatus = authorized ? "Enabled" : "Disabled in System Settings"
        }
    }
}
