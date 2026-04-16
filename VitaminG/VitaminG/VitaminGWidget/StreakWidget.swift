import WidgetKit
import SwiftUI
import SwiftData

// MARK: - StreakProvider

struct StreakProvider: TimelineProvider {

    func placeholder(in context: Context) -> GoalEntry {
        GoalEntry(date: .now, displayData: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (GoalEntry) -> Void) {
        completion(GoalEntry(date: .now, displayData: .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GoalEntry>) -> Void) {
        do {
            let container = try WidgetContainerCache.shared
            let modelContext = ModelContext(container)

            let goals = try modelContext.fetch(FetchDescriptor<Goal>())
            let events = try modelContext.fetch(FetchDescriptor<CompletionEvent>())

            let displayData = WidgetDataProvider.build(goals: goals, events: events)
            let entry = GoalEntry(date: .now, displayData: displayData)

            let nextRefresh = WidgetDataProvider.nextMorningRefreshDate(
                hour: NotificationPreferences.sharedHour(),
                minute: NotificationPreferences.sharedMinute()
            )
            let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
            completion(timeline)
        } catch {
            let entry = GoalEntry(date: .now, displayData: .empty)
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
            completion(timeline)
        }
    }
}

// MARK: - StreakWidgetView

struct StreakWidgetView: View {
    let entry: GoalEntry

    var body: some View {
        Group {
            if entry.displayData.globalStreak > 0 {
                // State A: streak > 0 — show streak count (D-05)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .widgetAccentable()
                        Text("\(entry.displayData.globalStreak)")
                            .font(.title2.bold().monospacedDigit())
                            .widgetAccentable()
                    }
                    Text("day streak")
                        .font(.caption)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(entry.displayData.globalStreak) day streak")
            } else if let immediateTitle = entry.displayData.tierRows.first(where: { $0.tier == .immediate })?.topGoalTitle {
                // State B: streak == 0, has Immediate goal — show top Immediate goal title (D-05)
                VStack(alignment: .leading, spacing: 2) {
                    Text(immediateTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .widgetAccentable()
                    Text("Immediate goal")
                        .font(.caption)
                }
            } else {
                // State C: streak == 0, no Immediate goals — fallback prompt
                VStack(alignment: .leading, spacing: 2) {
                    Text("Set your first goal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .widgetAccentable()
                    Text("Vitamin G")
                        .font(.caption)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - StreakWidget

struct StreakWidget: Widget {
    let kind = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("Your current streak, or your top immediate goal.")
        .supportedFamilies([.accessoryRectangular])
    }
}
