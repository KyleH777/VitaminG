import SwiftUI

// MARK: - StreakChainView

/// Horizontal 30-day streak chain component used in ChallengeDetailView (CHAL-11, D-09, D-10).
///
/// Renders a scrollable row of 30 day-dot circles:
/// - Filled circle (accent color): day has a check-in
/// - Outlined circle (accent color, 25% opacity): day was missed
/// - Today's circle: additional 2pt stroke at full accent color regardless of check-in status
///
/// Pure display component — no SwiftData dependency. Caller passes pre-fetched dates.
struct StreakChainView: View {
    /// Dates on which the user checked in (any time during that day).
    let checkInDates: [Date]
    /// Template-specific accent color from ChallengeTemplate.accentColorHex.
    let accentColor: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Day Generation

    /// Returns 30 dates (startOfDay), oldest first (29 days ago → today).
    private var days: [Date] {
        let today = Calendar.current.startOfDay(for: Date())
        return (0..<30).compactMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: today)
        }.reversed()
    }

    /// Set of startOfDay values for O(1) lookup.
    private var checkedInDays: Set<Date> {
        Set(checkInDates.map { Calendar.current.startOfDay(for: $0) })
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Streak")
                .font(.title2)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.clay)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(days, id: \.self) { day in
                        dayDot(for: day)
                            .frame(width: 20, height: 20)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.horizontal, 16)
            }
            .accessibilityLabel("Streak chain: \(checkInDates.count) check-ins in the last 30 days")
        }
    }

    // MARK: - Day Dot

    @ViewBuilder
    private func dayDot(for day: Date) -> some View {
        let today = Calendar.current.startOfDay(for: Date())
        let isToday = day == today
        let isCheckedIn = checkedInDays.contains(day)

        ZStack {
            if isCheckedIn {
                // Filled: checked-in day
                Circle()
                    .fill(accentColor)
            } else {
                // Outlined: missed day — faint stroke, clear fill
                Circle()
                    .strokeBorder(accentColor.opacity(0.25), lineWidth: 2)
            }

            // Today overlay: 2pt full-accent stroke ring
            if isToday {
                Circle()
                    .strokeBorder(accentColor, lineWidth: 2)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack(spacing: 24) {
        StreakChainView(
            checkInDates: [
                Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                Date()
            ],
            accentColor: Color(red: 1.0, green: 0.42, blue: 0.29)
        )
        .padding()

        StreakChainView(
            checkInDates: [],
            accentColor: Color(red: 0.478, green: 0.620, blue: 0.494)
        )
        .padding()
    }
    .background(VGTheme.sandLight)
}
#endif
