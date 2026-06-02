import SwiftUI
import SwiftData

// MARK: - GoalAllTimeHeatmapView

/// Full-screen view for a single goal's all-time heatmap and per-goal CSV export.
///
/// Receives pre-computed heatmapData from AnalyticsViewModel (avoids redundant computation).
/// Queries its own CompletionEvent list for accurate per-goal CSV export.
///
/// ANLT-03: All-time heatmap via AllTimeHeatmapView (LazyHStack, scrolls to most recent week).
/// ANLT-04: Per-goal CSV ShareLink using CSVExportService.buildGoalCSV.
struct GoalAllTimeHeatmapView: View {
    let goal: Goal
    /// Pre-built by AnalyticsViewModel.heatmapDataByGoal — keyed by goal.id.uuidString.
    let heatmapData: [Date: Int]
    /// Streak-freeze dates — used for is_frozen column in per-goal CSV export.
    let frozenDates: [Date]

    /// All events — filtered inside buildGoalCSV using goal.id equality.
    @Query private var events: [CompletionEvent]

    // MARK: - Start Date

    /// Earliest date to anchor the heatmap. Mirrors AnalyticsViewModel.heatmapStartDate(for:).
    private var startDate: Date {
        if let creation = goal.creationDate {
            return creation
        }
        if let earliest = goal.completionEvents?
            .compactMap({ $0.completedAt })
            .min() {
            return earliest
        }
        // Safe fallback — if calendar arithmetic fails, use a fixed 90-day offset
        // rather than force-unwrapping and crashing on a corrupted calendar/locale.
        return Calendar.current.date(byAdding: .day, value: -90, to: Date())
            ?? Date(timeIntervalSinceNow: -90 * 86400)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heatmapCard
                perGoalExportButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(goal.title ?? "Goal")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Heatmap Card

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 4)

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))

                VStack(alignment: .leading, spacing: 10) {
                    Text("All time")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    AllTimeHeatmapView(data: heatmapData, startDate: startDate)
                }
                .padding(16)
            }
        }
    }

    // MARK: - Per-Goal Export Button

    private var perGoalExportButton: some View {
        let dateStamp = Date().formatted(.iso8601.year().month().day())
        // Sanitize goal title for use in a filename: replace path-separator characters
        // and strip control characters that are illegal in file names on iOS and Windows.
        // A raw title like "Finance / Budget" would produce a broken path component
        // on many share destinations, silently truncating the filename.
        let safeTitle = (goal.title ?? "goal")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .components(separatedBy: .controlCharacters).joined(separator: "")
            .trimmingCharacters(in: .whitespaces)
        let csvContent = CSVExportService.buildGoalCSV(
            goal: goal,
            events: Array(events),
            frozenDates: frozenDates
        )

        return ShareLink(
            item: csvContent,
            preview: SharePreview(
                "vitamin-g-\(safeTitle)-\(dateStamp).csv",
                image: Image(systemName: "doc.text")
            )
        ) {
            Label("Export CSV", systemImage: "square.and.arrow.up")
                .font(.body.weight(.semibold))
                .fontDesign(.rounded)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(VGTheme.accentTerra)
    }
}
