import SwiftUI
import SwiftData

// MARK: - SettingsView

/// Notification settings screen allowing the user to change the daily reminder time (NOTIF-06).
/// Time change triggers immediate reschedule of the notification (NOTIF-06, NOTIF-02).
/// Uses @Query to fetch active goals so the rescheduled notification body stays current (NOTIF-03).
struct SettingsView: View {

    @Query(filter: #Predicate<Goal> { $0.isCompleted == false })
    private var activeGoals: [Goal]

    @Query private var allEvents: [CompletionEvent]

    private var globalStreak: Int {
        StreakEngine.currentStreak(from: allEvents)
    }

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
                .onChange(of: notificationTime) { _, newValue in
                    let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                    let hour = components.hour ?? 8
                    let minute = components.minute ?? 0
                    // Persist user preference (NOTIF-06)
                    UserDefaults.standard.set(hour, forKey: "notificationHour")
                    UserDefaults.standard.set(minute, forKey: "notificationMinute")
                    // Also write to App Group suite so widget can read notification time (D-06, Pitfall 3)
                    let sharedDefaults = UserDefaults(suiteName: "group.com.kyleharrington.VitaminG")
                    sharedDefaults?.set(hour, forKey: "notificationHour")
                    sharedDefaults?.set(minute, forKey: "notificationMinute")
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
        .onAppear {
            // Sync notification time to App Group UserDefaults for widget access (D-06, Pitfall 3)
            let components = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
            let sharedDefaults = UserDefaults(suiteName: "group.com.kyleharrington.VitaminG")
            sharedDefaults?.set(components.hour ?? 8, forKey: "notificationHour")
            sharedDefaults?.set(components.minute ?? 0, forKey: "notificationMinute")
        }
        .task {
            let authorized = await NotificationScheduler.shared.isAuthorized()
            authorizationStatus = authorized ? "Enabled" : "Disabled in System Settings"
        }
    }
}
