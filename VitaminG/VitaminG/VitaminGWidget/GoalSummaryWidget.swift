import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Widget Color Tokens
// VGTheme is in the main app module and is not accessible from the widget extension.
// These local color definitions mirror VGTheme.accentTerra exactly so the widget can
// use the same adaptive terra / terraGlow palette without an import boundary violation.

private extension Color {
    /// Mirrors `VGTheme.accentTerra`: terra #C4673A (light) / terraGlow #FF8A5C (dark).
    static let accentTerra = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 1.000, green: 0.541, blue: 0.361, alpha: 1)  // terraGlow #FF8A5C
            : UIColor(red: 0.769, green: 0.404, blue: 0.227, alpha: 1)  // terra #C4673A
    })
}

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
        VStack(alignment: .leading, spacing: 8) {
            streakRow
            if let title = entry.displayData.activeGoalTitle {
                activeGoalRow(title: title, progress: entry.displayData.activeGoalProgress)
            } else {
                Text("Add your first goal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Add your first goal")
            }
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Streak Row

    private var streakRow: some View {
        HStack(spacing: 4) {
            if entry.displayData.globalStreak > 0 {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Color.accentTerra)
                    .font(.caption)
                Text("\(entry.displayData.globalStreak)")
                    .font(.title2.bold().monospacedDigit())
                Text("day streak")
                    .font(.caption)
                    .fontWeight(.semibold)
            } else {
                Text("Start your streak")
                    .font(.caption)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            entry.displayData.globalStreak > 0
                ? "\(entry.displayData.globalStreak) day streak"
                : "Start your streak"
        )
    }

    // MARK: - Active Goal Row

    private func activeGoalRow(title: String, progress: Double?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .truncationMode(.tail)
            if let p = progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.accentTerra.opacity(0.20))
                            .frame(height: 4)
                        Capsule()
                            .fill(Color.accentTerra)
                            .frame(width: geo.size.width * p, height: 4)
                    }
                }
                .frame(height: 4)   // CRITICAL: fixes GeometryReader height (Pitfall 6)
                .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            progress != nil
                ? "\(title), \(Int((progress ?? 0) * 100))% complete"
                : title
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
        .description("Your active goal and current streak at a glance.")
        .supportedFamilies([.systemMedium])
    }
}
