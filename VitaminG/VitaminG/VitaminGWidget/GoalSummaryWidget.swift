import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Shared Widget Container

/// Cached ModelContainer for the widget extension process.
/// Creating a ModelContainer is expensive — reuse a single instance across all timeline refreshes.
/// Both GoalSummaryProvider and StreakProvider share this to avoid redundant allocations.
enum WidgetContainerCache {
    private static var _container: ModelContainer?

    static var shared: ModelContainer {
        get throws {
            if let existing = _container { return existing }
            let container = try ModelContainerFactory.makeWidgetContainer()
            _container = container
            return container
        }
    }
}

// MARK: - GoalSummaryProvider

struct GoalSummaryProvider: TimelineProvider {

    func placeholder(in context: Context) -> GoalEntry {
        // Widget gallery — static data only, no SwiftData fetch (Pitfall 4)
        GoalEntry(date: .now, displayData: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (GoalEntry) -> Void) {
        // Widget gallery snapshot — static data only (Pitfall 4)
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

            // Push-only refresh: app explicitly calls reloadAllTimelines() on mutations (WIDGET-05)
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
        } catch {
            // Fallback: empty data — push-only refresh (WIDGET-05)
            let entry = GoalEntry(date: .now, displayData: .empty)
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
        }
    }
}

// MARK: - GoalSummaryWidgetView

struct GoalSummaryWidgetView: View {
    let entry: GoalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(entry.displayData.tierRows.enumerated()), id: \.offset) { _, row in
                TierRowView(row: row)
            }

            // Footer: streak count when > 0, omitted when 0 (D-04)
            if entry.displayData.globalStreak > 0 {
                Divider()
                    .padding(.top, 8)
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Color(uiColor: UIColor { t in
                            t.userInterfaceStyle == .dark
                                ? UIColor(red: 1.0, green: 0.541, blue: 0.361, alpha: 1)
                                : UIColor(red: 0.769, green: 0.404, blue: 0.227, alpha: 1)
                        }))
                        .font(.caption)
                    Text("\(entry.displayData.globalStreak) day streak")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - TierRowView

private struct TierRowView: View {
    let row: WidgetDisplayData.TierRow

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Tier icon + name header
            HStack(spacing: 8) {
                Image(systemName: row.tier.icon)
                    .font(.caption)
                    .foregroundStyle(row.tier.color)
                Text(row.tier.displayName)
                    .font(.caption)
                    .foregroundStyle(row.tier.color)
                Spacer()
            }

            // Goal title or empty prompt
            if let title = row.topGoalTitle {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(row.tier.typographicWeight)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else {
                Text("No \(row.tier.displayName) goals yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(row.tier.color.opacity(0.10))
        )
    }
}

// MARK: - GoalSummaryWidget

struct GoalSummaryWidget: Widget {
    let kind = "GoalSummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GoalSummaryProvider()) { entry in
            GoalSummaryWidgetView(entry: entry)
        }
        .configurationDisplayName("Goals")
        .description("See your top goal for each tier at a glance.")
        .supportedFamilies([.systemMedium])
    }
}
