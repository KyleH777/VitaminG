import SwiftUI

// MARK: - HeatmapView

/// GitHub-style activity heatmap showing completion events over a rolling window of days.
///
/// Pure display component — takes a pre-built [Date: Int] dictionary from StatsViewModel
/// for O(1) per-cell lookup. No data fetching inside the view body.
///
/// T-03-06: O(1) per cell — data is pre-bucketed by StatsViewModel.buildHeatmapData.
struct HeatmapView: View {
    /// Pre-built by StatsViewModel — keyed by Calendar.startOfDay values.
    let data: [Date: Int]

    /// Number of trailing days to show (default: 90 ≈ 13 weeks).
    var windowDays: Int = 90

    private var days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<windowDays).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }.reversed()
    }

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(12), spacing: 3), count: 7),
            spacing: 3
        ) {
            ForEach(days, id: \.self) { day in
                RoundedRectangle(cornerRadius: 2)
                    .fill(cellColor(for: data[day] ?? 0))
                    .frame(width: 12, height: 12)
            }
        }
    }

    // MARK: - Color Intensity

    private func cellColor(for count: Int) -> Color {
        switch count {
        case 0:       return Color(.systemFill)
        case 1:       return .green.opacity(0.3)
        case 2:       return .green.opacity(0.6)
        default:      return .green
        }
    }
}
