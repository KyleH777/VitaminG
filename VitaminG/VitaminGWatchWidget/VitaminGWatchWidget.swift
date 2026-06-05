import WidgetKit
import SwiftUI

// MARK: - WatchEntry

struct WatchEntry: TimelineEntry {
    let date: Date
    let goalTitle: String?
    let progress: Double
    let globalStreak: Int
    let hasCheckedInToday: Bool

    static let placeholder = WatchEntry(
        date: .now,
        goalTitle: "Morning run",
        progress: 0.72,
        globalStreak: 7,
        hasCheckedInToday: false
    )
}

// MARK: - WatchSnapshotProvider

struct WatchSnapshotProvider: TimelineProvider {

    func placeholder(in context: Context) -> WatchEntry {
        WatchEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchEntry) -> Void) {
        // Widget Gallery preview: return placeholder data
        completion(WatchEntry.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchEntry>) -> Void) {
        // T-27-04-03 mitigation: handle nil suite gracefully — fall back to zero defaults
        let defaults = UserDefaults(suiteName: "group.com.kyleharrington.VitaminGWatch")
        let entry = WatchEntry(
            date: .now,
            goalTitle: defaults?.string(forKey: "watchSnapshot_activeGoalTitle"),
            progress: defaults?.double(forKey: "watchSnapshot_activeGoalProgress") ?? 0.0,
            globalStreak: defaults?.integer(forKey: "watchSnapshot_globalStreak") ?? 0,
            hasCheckedInToday: defaults?.bool(forKey: "watchSnapshot_hasCheckedInToday") ?? false
        )
        // Push-only refresh: WatchReceiver calls reloadAllTimelines() on each WCSession update
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - WatchComplicationView

struct WatchComplicationView: View {
    let entry: WatchEntry

    var body: some View {
        Group {
            if entry.hasCheckedInToday {
                // Checked-in state
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(VGWatch.terraGlow)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Checked in")
                            .font(.caption2.bold())
                            .foregroundColor(VGWatch.terraGlow)
                        Text(entry.goalTitle ?? "Vitamin G")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            } else {
                // Active state
                HStack(spacing: 6) {
                    VGRingView(
                        progress: entry.progress,
                        size: 32,
                        lineWidth: 3,
                        color: VGWatch.terraSoft,
                        glow: false
                    )
                    VStack(alignment: .leading, spacing: 1) {
                        Text(entry.goalTitle ?? "No active goal")
                            .font(.caption2.bold())
                            .lineLimit(2)
                        Text("Day \(entry.globalStreak)")
                            .font(.caption2)
                            .foregroundColor(VGWatch.terraSoft)
                    }
                }
            }
        }
        // T-27-04-04 mitigation: containerBackground required for watchOS 10+ WidgetKit views
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - VitaminGWatchWidget

struct VitaminGWatchWidget: Widget {
    let kind = "VitaminGWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchSnapshotProvider()) { entry in
            WatchComplicationView(entry: entry)
        }
        .configurationDisplayName("Vitamin G")
        .description("Your active goal and today's progress.")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - VitaminGWatchWidgetBundle

@main
struct VitaminGWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        VitaminGWatchWidget()
    }
}
