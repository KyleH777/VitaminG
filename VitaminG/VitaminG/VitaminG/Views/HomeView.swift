import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var goals: [Goal]
    @Environment(\.modelContext) private var modelContext

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    private var primaryGoal: Goal? {
        goals.first(where: { !$0.isCompleted && $0.tier == .lifeGoal })
            ?? goals.first(where: { !$0.isCompleted && $0.tier == .longTerm })
            ?? goals.first(where: { !$0.isCompleted })
    }

    private var secondaryGoals: [Goal] {
        goals.filter { !$0.isCompleted && $0.id != primaryGoal?.id }.prefix(3).map { $0 }
    }

    var body: some View {
        ZStack {
            VGTheme.heroBackground.ignoresSafeArea()
            RadialGradient(
                colors: [VGTheme.heroBackgroundSecondary, Color.clear],
                center: .top, startRadius: 0, endRadius: 400
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    quoteSection
                    if let goal = primaryGoal {
                        primaryGoalCard(goal)
                    }
                    secondaryGoalsSection
                    Spacer(minLength: 32)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(VGTheme.muted)
                    .kerning(0.5)
                Text("Vitamin G")
                    .font(VGTheme.serif(26))
                    .foregroundStyle(VGTheme.sand)
            }
            Spacer()
            streakBadge
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var streakBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame.fill")
                .font(.system(size: 13))
                .foregroundStyle(VGTheme.terraSoft)
            Text("\(currentStreak)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(VGTheme.terraSoft)
            Text("day streak")
                .font(.system(size: 11))
                .foregroundStyle(VGTheme.muted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1))
        .clipShape(Capsule())
    }

    private var currentStreak: Int {
        goals.compactMap { $0.completionEvents?.count }.max() ?? 0
    }

    // MARK: - Quote

    private var quoteSection: some View {
        let quotes = [
            "Small steps, taken daily, build the life you've been dreaming of.",
            "Progress, not perfection.",
            "Every day is a chance to be better than yesterday.",
            "You don't have to be great to start, but you have to start to be great.",
        ]
        let quote = quotes[Calendar.current.component(.day, from: Date()) % quotes.count]

        return Text(quote)
            .font(VGTheme.serifItalic(15))
            .foregroundStyle(VGTheme.sand.opacity(0.85))
            .lineSpacing(4)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.06))
            .overlay(
                Rectangle().frame(width: 3).foregroundStyle(VGTheme.terra),
                alignment: .leading
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 24)
            .padding(.top, 20)
    }

    // MARK: - Primary Goal Card

    private func primaryGoalCard(_ goal: Goal) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PRIMARY GOAL")
                .font(.system(size: 10, weight: .bold))
                .kerning(1.2)
                .foregroundStyle(VGTheme.muted)

            HStack(spacing: 20) {
                ProgressRingView(
                    progress: goalProgress(goal),
                    tier: goal.tier,
                    isCompleted: goal.isCompleted
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(goal.title ?? "Untitled")
                        .font(VGTheme.serif(20, weight: .medium))
                        .foregroundStyle(VGTheme.sand)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(goal.tier.displayName)
                        .font(.system(size: 12))
                        .foregroundStyle(VGTheme.muted)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(VGTheme.sage)
                            .frame(width: 6, height: 6)
                        Text("In progress")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(VGTheme.sage)
                    }
                }
                Spacer()
            }

            HStack(spacing: 10) {
                statCell(value: "\(goal.completionEvents?.count ?? 0)", label: "Check-ins")
                statCell(value: goal.tier.displayName, label: "Tier")
                statCell(value: goal.isPublic ? "Public" : "Private", label: "Visibility")
            }
        }
        .padding(22)
        .background(Color.white.opacity(0.07))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(VGTheme.serif(18))
                .foregroundStyle(VGTheme.sand)
            Text(label)
                .font(.system(size: 10))
                .kerning(0.5)
                .foregroundStyle(VGTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Secondary Goals

    private var secondaryGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MY GOALS")
                    .font(.system(size: 13, weight: .semibold))
                    .kerning(0.6)
                    .foregroundStyle(VGTheme.muted)
                Spacer()
                NavigationLink(value: "goals") {
                    Text("See all")
                        .font(.system(size: 13))
                        .foregroundStyle(VGTheme.terra)
                }
            }

            if secondaryGoals.isEmpty && primaryGoal == nil {
                Text("No active goals yet. Add one to get started.")
                    .font(.system(size: 14))
                    .foregroundStyle(VGTheme.muted)
                    .padding(.vertical, 8)
            } else {
                ForEach(secondaryGoals) { goal in
                    goalRow(goal)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    private func goalRow(_ goal: Goal) -> some View {
        HStack(spacing: 14) {
            ProgressRingView(
                progress: goalProgress(goal),
                tier: goal.tier,
                isCompleted: goal.isCompleted
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(goal.title ?? "Untitled")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(VGTheme.sand)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(goal.tier.displayName)
                        .font(.system(size: 11))
                        .foregroundStyle(VGTheme.muted)
                    Text("·")
                        .foregroundStyle(VGTheme.muted)
                    Text(goal.isCompleted ? "Done" : "Active")
                        .font(.system(size: 11))
                        .foregroundStyle(goal.tier.color)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundStyle(VGTheme.muted)
        }
        .padding(14)
        .background(Color.white.opacity(0.07))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func goalProgress(_ goal: Goal) -> Double {
        guard let events = goal.completionEvents, !events.isEmpty else { return 0.1 }
        return min(Double(events.count) / 30.0, 1.0)
    }
}
