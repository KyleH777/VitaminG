import SwiftUI
import SwiftData
import Charts

// MARK: - AnalyticsView

/// Analytics dashboard — completion rate bar chart, per-goal heatmap navigation, and CSV export.
///
/// ANLT-02: BarMark chart with Weekly/Monthly segmented picker (D-03, D-04, D-05).
/// ANLT-03: Scrollable goal list — tapping any goal navigates to GoalAllTimeHeatmapView.
/// ANLT-04: Global CSV ShareLink via CSVExportService.buildGlobalCSV.
@MainActor
struct AnalyticsView: View {

    // MARK: - Data

    @Query private var events: [CompletionEvent]
    @Query private var goals: [Goal]

    // MARK: - State

    @State private var viewModel = AnalyticsViewModel()
    @State private var freezeService = StreakFreezeService()
    @State private var granularity: ChartGranularity = .weekly

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                chartSection
                goalListSection
                globalExportButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.refresh(events: events, goals: goals, frozenDates: freezeService.frozenDates)
        }
        .onChange(of: events.count) {
            viewModel.refresh(events: events, goals: goals, frozenDates: freezeService.frozenDates)
        }
        .onChange(of: goals.count) {
            viewModel.refresh(events: events, goals: goals, frozenDates: freezeService.frozenDates)
        }
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completion Rate")
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 4)

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))

                VStack(alignment: .leading, spacing: 12) {
                    Picker("Granularity", selection: $granularity) {
                        Text("Weekly").tag(ChartGranularity.weekly)
                        Text("Monthly").tag(ChartGranularity.monthly)
                    }
                    .pickerStyle(.segmented)

                    let buckets = granularity == .weekly
                        ? viewModel.weeklyBuckets
                        : viewModel.monthlyBuckets

                    let calendarUnit: Calendar.Component = granularity == .weekly ? .weekOfYear : .month

                    Chart(buckets) { item in
                        BarMark(
                            x: .value("Period", item.periodStart, unit: calendarUnit),
                            y: .value("Rate", item.completionRate)
                        )
                        .foregroundStyle(VGTheme.accentTerra)
                    }
                    .chartYAxis {
                        AxisMarks(format: FloatingPointFormatStyle<Double>.Percent())
                    }
                    .frame(height: 180)
                    .accessibilityLabel("Completion rate trends bar chart")
                }
                .padding(16)
            }
        }
    }

    // MARK: - Goal List Section

    private var goalListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goals")
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 4)

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(viewModel.allGoals.enumerated()), id: \.element.id) { index, goal in
                        NavigationLink(destination: GoalAllTimeHeatmapView(
                            goal: goal,
                            heatmapData: viewModel.heatmapDataByGoal[goal.id.uuidString] ?? [:],
                            frozenDates: freezeService.frozenDates
                        )) {
                            HStack {
                                Text(goal.title ?? "Untitled")
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        }
                        .buttonStyle(.plain)

                        if index < viewModel.allGoals.count - 1 {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Global Export Button

    private var globalExportButton: some View {
        let dateStamp = Date().formatted(.iso8601.year().month().day())
        let csvContent = CSVExportService.buildGlobalCSV(
            events: Array(events),
            goals: Array(goals),
            frozenDates: freezeService.frozenDates
        )

        return ShareLink(
            item: csvContent,
            preview: SharePreview(
                "vitamin-g-history-\(dateStamp).csv",
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
