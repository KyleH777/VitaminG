import SwiftUI
import SwiftData

// MARK: - GoalDayGridView
//
// Calendar-month day grid component for GoalDetailView.
// Shows a Monday-first 7-column grid of the current month, with filled circles
// for completed days, today highlight (accentTerra), and empty circles for missed/future days.
// Supports chevron navigation to prior months bounded by goal.startDate.
//
// GOAL2-05 / D-09 / D-10 / D-11 / Phase 18 Plan 05

struct GoalDayGridView: View {

    // MARK: - Properties

    let goal: Goal
    let completionEvents: [CompletionEvent]

    @State private var displayedMonth: Date = Date()

    private let columns = Array(repeating: GridItem(.fixed(36), spacing: 8), count: 7)
    private let dayHeaders = ["M", "T", "W", "T", "F", "S", "S"]

    // MARK: - Computed Members

    /// Set of startOfDay dates for all events that belong to this goal.
    /// Uses compactMap + filter — never force-unwraps.
    private var completedDays: Set<Date> {
        GoalDayGridView.completedDays(for: goal, from: completionEvents, calendar: .current)
    }

    private var daysInMonth: [Date?] {
        GoalDayGridView.daysInMonth(for: displayedMonth, calendar: .current)
    }

    private var canNavigateForward: Bool {
        GoalDayGridView.canNavigateForward(displayedMonth: displayedMonth, calendar: .current)
    }

    private var canNavigateBack: Bool {
        guard let prior = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) else {
            return false
        }
        let cal = Calendar.current
        let boundDate = goal.startDate ?? goal.creationDate ?? Date()
        let boundComponents = cal.dateComponents([.year, .month], from: boundDate)
        let priorComponents = cal.dateComponents([.year, .month], from: prior)

        guard let by = boundComponents.year, let bm = boundComponents.month,
              let py = priorComponents.year, let pm = priorComponents.month else {
            return false
        }

        // prior >= bound
        if py > by { return true }
        if py == by && pm >= bm { return true }
        return false
    }

    // MARK: - Static Helpers (exposed for tests — GOAL2-05)

    /// Returns an array of Date? values for the displayed month, padded with leading nils
    /// to achieve Monday-first alignment. Pitfall 5: cal.firstWeekday = 2 must be set.
    /// - Parameters:
    ///   - displayedMonth: Any date within the target month.
    ///   - calendar: Injectable Calendar for testability. Must have firstWeekday = 2 set by caller if Monday-first is required.
    static func daysInMonth(for displayedMonth: Date, calendar: Calendar) -> [Date?] {
        var cal = calendar
        cal.firstWeekday = 2   // Monday-first — Pitfall 5
        guard let range = cal.range(of: .day, in: .month, for: displayedMonth),
              let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        // weekday offset: how many leading nil pads are needed before the 1st
        let weekdayOffset = (cal.component(.weekday, from: firstDay) - cal.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: weekdayOffset)
        for day in range {
            if let date = cal.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }

    /// Returns true when the displayed month is earlier than the current calendar month,
    /// meaning the user can navigate forward in time.
    static func canNavigateForward(displayedMonth: Date, calendar: Calendar) -> Bool {
        let thisMonth = calendar.dateComponents([.year, .month], from: Date())
        let shown = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let ty = thisMonth.year, let tm = thisMonth.month,
              let sy = shown.year, let sm = shown.month else { return false }
        if sy < ty { return true }
        if sy == ty && sm < tm { return true }
        return false
    }

    /// Returns a Set<Date> of startOfDay values for all CompletionEvents belonging to the goal.
    /// Exported as static for testability.
    static func completedDays(for goal: Goal, from events: [CompletionEvent], calendar: Calendar) -> Set<Date> {
        let goalID = goal.id
        return Set(
            events
                .filter { $0.goal?.id == goalID }
                .compactMap { $0.completedAt }
                .map { calendar.startOfDay(for: $0) }
        )
    }

    // MARK: - Month Navigation

    private func navigateMonth(by months: Int) {
        guard let newMonth = Calendar.current.date(byAdding: .month, value: months, to: displayedMonth) else { return }
        withAnimation(.easeInOut) {
            displayedMonth = newMonth
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: displayedMonth)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Month header with navigation chevrons
            HStack {
                Button {
                    navigateMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(VGTheme.accentTerra)
                        .frame(minWidth: 28, minHeight: 28)
                }
                .disabled(!canNavigateBack)
                .accessibilityLabel("Previous month")

                Spacer()

                Text(monthTitle)
                    .font(VGTheme.serif(20, weight: .semibold))
                    .foregroundStyle(VGTheme.textPrimary)

                Spacer()

                Button {
                    navigateMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(VGTheme.accentTerra)
                        .frame(minWidth: 28, minHeight: 28)
                }
                .disabled(!canNavigateForward)
                .accessibilityLabel("Next month")
            }

            // Column headers: M T W T F S S
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(dayHeaders, id: \.self) { header in
                    Text(header)
                        .font(.system(size: 13, weight: .semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(VGTheme.textMuted)
                        .frame(width: 36, height: 20)
                        .multilineTextAlignment(.center)
                }
            }

            // Day cells
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInMonth.indices, id: \.self) { i in
                    dayCell(date: daysInMonth[i])
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Day Cell

    @ViewBuilder
    private func dayCell(date: Date?) -> some View {
        if let date = date {
            let cal = Calendar.current
            let isCompleted = completedDays.contains(cal.startOfDay(for: date))
            let isToday = cal.isDateInToday(date)
            let isFuture = cal.startOfDay(for: date) > cal.startOfDay(for: Date())

            ZStack {
                if isCompleted && !isFuture {
                    Circle()
                        .fill(VGTheme.accentSage)
                        .frame(width: 32, height: 32)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                } else if isToday && !isCompleted {
                    Circle()
                        .fill(VGTheme.accentTerra.opacity(0.15))
                        .overlay(
                            Circle()
                                .strokeBorder(VGTheme.accentTerra, lineWidth: 2)
                        )
                        .frame(width: 32, height: 32)
                    Text("\(cal.component(.day, from: date))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(VGTheme.accentTerra)
                } else {
                    Circle()
                        .fill(VGTheme.surface)
                        .overlay(
                            Circle()
                                .strokeBorder(VGTheme.separator, lineWidth: 1)
                        )
                        .frame(width: 32, height: 32)
                    Text("\(cal.component(.day, from: date))")
                        .font(.system(size: 13))
                        .foregroundStyle(VGTheme.textMuted)
                }
            }
            .frame(width: 36, height: 36)
            .accessibilityLabel(accessibilityLabel(for: date, isCompleted: isCompleted && !isFuture))
        } else {
            // Leading padding cell — transparent placeholder
            Circle()
                .fill(Color.clear)
                .frame(width: 32, height: 32)
                .frame(width: 36, height: 36)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Accessibility

    private func accessibilityLabel(for date: Date, isCompleted: Bool) -> String {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        let dayName = dayFormatter.string(from: date)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        let dateString = dateFormatter.string(from: date)

        let status = isCompleted ? "completed" : "not completed"
        return "\(dayName), \(dateString), \(status)"
    }
}
