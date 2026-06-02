import SwiftUI

// MARK: - AllTimeHeatmapView

/// Horizontally scrolling all-time heatmap for a single goal.
///
/// Pure display component — receives pre-built [Date: Int] from AnalyticsViewModel.
/// Each column represents one week (7 days); cells are 12×12 pt squares.
/// Scrolls to the most recent week on appear.
///
/// ANLT-03: LazyHStack-based horizontal heatmap with frozen-day blue-tint (sentinel -1).
struct AllTimeHeatmapView: View {
    /// Pre-built by AnalyticsViewModel.buildGoalHeatmapData — keyed by Calendar.startOfDay values.
    /// Sentinel -1 marks streak-freeze days.
    let data: [Date: Int]
    /// The first day to render. Should be calendar.startOfDay(for: goal.creationDate).
    let startDate: Date

    // MARK: - Week Column Builder

    /// Builds an array of week-columns from startDate through today.
    /// Each column is an array of up to 7 Date values (Sunday–Saturday or Monday–Sunday
    /// depending on locale; we use weekOfYear interval which respects the device locale).
    private var weeks: [[Date]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Anchor to the start of the week that contains startDate.
        var weekStart = calendar.dateInterval(of: .weekOfYear, for: startDate)?.start ?? startDate
        var result: [[Date]] = []

        while weekStart <= today {
            let column = (0..<7).compactMap {
                calendar.date(byAdding: .day, value: $0, to: weekStart)
            }
            result.append(column)
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { break }
            weekStart = next
        }
        return result
    }

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 3) {
                    ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                        VStack(spacing: 3) {
                            ForEach(week, id: \.self) { day in
                                dayCell(for: day)
                            }
                        }
                        .id(index)
                    }
                }
                .padding(.horizontal, 8)
            }
            .onAppear {
                // Scroll to the last (most recent) week column.
                proxy.scrollTo(weeks.count - 1, anchor: .trailing)
            }
        }
    }

    // MARK: - Day Cell

    @ViewBuilder
    private func dayCell(for day: Date) -> some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if day > today {
            // Future day — render invisible placeholder to preserve grid alignment.
            Color.clear
                .frame(width: 12, height: 12)
        } else {
            let count = data[calendar.startOfDay(for: day)] ?? 0
            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(cellColor(for: count))
                    .frame(width: 12, height: 12)
                if count == -1 {
                    Image(systemName: "snowflake")
                        .font(.system(size: 7))
                        .foregroundStyle(Color.blue)
                        .accessibilityLabel("Streak freeze")
                }
            }
        }
    }

    // MARK: - Color Intensity

    /// Returns the fill color for a heatmap cell.
    /// Verbatim copy from HeatmapView.swift — MILE-03 sentinel -1 = blue tint.
    private func cellColor(for count: Int) -> Color {
        switch count {
        case -1:      return Color.blue.opacity(0.25)
        case 0:       return Color(.systemFill)
        case 1:       return .green.opacity(0.3)
        case 2:       return .green.opacity(0.6)
        default:      return .green
        }
    }
}
