import SwiftUI

// Screen 02 — Today Glance (main app open view)
// WATCH-02: Live snapshot data via @AppStorage backed by Watch App Group UserDefaults.
// The five watchSnapshot_ keys are written by WatchReceiver.processApplicationContext
// when an applicationContext arrives from the paired iPhone.
struct TodayGlanceView: View {
    @State private var checkedIn = false

    // MARK: - Live Snapshot Properties (WATCH-02)

    private static let suite = "group.com.kyleharrington.VitaminGWatch"

    /// Global streak count from the latest WCSession snapshot (D-02).
    @AppStorage("watchSnapshot_globalStreak", store: UserDefaults(suiteName: suite))
    private var globalStreak: Int = 0

    /// Active goal progress ratio 0.0–1.0 from the latest WCSession snapshot (D-01).
    @AppStorage("watchSnapshot_activeGoalProgress", store: UserDefaults(suiteName: suite))
    private var activeGoalProgress: Double = 0.0

    /// Active goal title from the latest WCSession snapshot. Empty string when no active goal.
    @AppStorage("watchSnapshot_activeGoalTitle", store: UserDefaults(suiteName: suite))
    private var activeGoalTitle: String = ""

    /// Whether the user has already checked in today.
    @AppStorage("watchSnapshot_hasCheckedInToday", store: UserDefaults(suiteName: suite))
    private var hasCheckedInToday: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header — "Day {globalStreak}" (D-02)
                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(VGWatch.terraSoft)
                        .tracking(2)
                    HStack(spacing: 0) {
                        Text("Day ")
                            .font(VGWatch.serif(22))
                            .foregroundColor(.white)
                        Text("\(globalStreak)")
                            .font(VGWatch.serif(22, italic: true))
                            .foregroundColor(VGWatch.terraSoft)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.top, 10)

                // Ring with centered % (D-01)
                ZStack {
                    VGRingView(progress: activeGoalProgress, size: 100, lineWidth: 9, color: VGWatch.terraSoft)
                    VStack(spacing: 1) {
                        HStack(alignment: .lastTextBaseline, spacing: 1) {
                            Text("\(Int(activeGoalProgress * 100))")
                                .font(.system(size: 28, weight: .thin))
                                .foregroundColor(.white)
                            Text("%")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Text("OF GOAL")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.white.opacity(0.55))
                            .tracking(1.5)
                    }
                }
                .padding(.top, 8)

                // Active goal title below ring (D-02)
                // When activeGoalTitle is empty, SwiftUI collapses the Text to zero height.
                Text(activeGoalTitle.isEmpty ? "" : activeGoalTitle)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(1)
                    .padding(.top, 4)
                    .padding(.horizontal, 14)

                // Check-in button — behavior wired in Wave 4 (Plan 27-05)
                Button {
                    checkedIn = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: checkedIn ? "checkmark.circle.fill" : "checkmark")
                            .font(.system(size: 13, weight: .semibold))
                        Text(checkedIn ? "Checked in!" : "Check in")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(colors: [VGWatch.terra, Color(red: 0.545, green: 0.267, blue: 0.133)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(99)
                    .shadow(color: VGWatch.terra.opacity(0.55), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.top, 10)

                Spacer()
            }
        }
    }
}

#Preview {
    TodayGlanceView()
}
