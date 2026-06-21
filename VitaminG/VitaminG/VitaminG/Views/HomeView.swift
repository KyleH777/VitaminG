import SwiftUI
import SwiftData
import UIKit

struct HomeView: View {
    @Query private var goals: [Goal]
    @Query private var completionEvents: [CompletionEvent]
    @Query private var userChallenges: [UserChallenge]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("vg_onboardingName") private var storedName: String = ""
    @State private var goalVM = GoalViewModel()
    @State private var aiViewModel = AIViewModel()

    // Goal entry sheet state
    @State private var showingGoalEntryChoice = false
    @State private var showingWizard = false
    @State private var wizardStartStep: Int = 0
    @State private var pendingPremadeGoal: (title: String, category: GoalCategory)? = nil

    private var displayName: String {
        storedName.trimmingCharacters(in: .whitespaces).isEmpty ? "You" : storedName
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    // HOME-01: app streak sourced from StreakEngine — not goal.completionEvents?.count
    private var appStreak: Int {
        StreakEngine.currentStreak(from: completionEvents)
    }

    // HOME-03: active community challenge
    private var primaryChallenge: UserChallenge? {
        userChallenges.first(where: { ($0.statusRaw ?? "") == "active" })
    }

    private var primaryGoal: Goal? {
        goals.first(where: { !$0.isCompleted && $0.tier == .lifeGoal })
            ?? goals.first(where: { !$0.isCompleted && $0.tier == .longTerm })
            ?? goals.first(where: { !$0.isCompleted })
    }

    private var secondaryGoals: [Goal] {
        goals.filter { !$0.isCompleted }.prefix(3).map { $0 }
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
                    AIMotivationSection(aiViewModel: aiViewModel)
                    // HOME-03: community goal card — hidden when no active challenge
                    if let challenge = primaryChallenge {
                        communityGoalCard(challenge)
                    }
                    // HOME-05: reshaped Stats nav row
                    quickStatsRow
                    // HOME-04: My Goals section with inline +add and flame icons
                    secondaryGoalsSection
                    stayCloseSection
                    // HOME-06 dropped per D-04 (no gratitude entry on Home in Phase 18)
                    Spacer(minLength: 32)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await aiViewModel.refreshMotivationIfNeeded(goals: goals, events: completionEvents)
        }
        .sheet(isPresented: $showingGoalEntryChoice) {
            GoalEntryChoiceView(
                onSelectWizard: { step in
                    wizardStartStep = step
                    showingGoalEntryChoice = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showingWizard = true }
                },
                onSelectPremade: { title, category in
                    pendingPremadeGoal = (title: title, category: category)
                    wizardStartStep = 2
                    showingGoalEntryChoice = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showingWizard = true }
                }
            )
        }
        .sheet(isPresented: $showingWizard, onDismiss: { pendingPremadeGoal = nil }) {
            GoalCreationWizardView(startAtStep: wizardStartStep, premadeGoal: pendingPremadeGoal)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(greeting) ☀️")
                    .font(.footnote)
                    .foregroundStyle(VGTheme.textMuted)
                    .kerning(0.5)
                    .accessibilityHidden(true)
                Text(displayName)
                    .font(VGTheme.serif(26))
                    .foregroundStyle(VGTheme.sand)
                    .accessibilityLabel("\(greeting), \(displayName)")
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer()
            HStack(spacing: 10) {
                streakBadge
                bellButton
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var streakBadge: some View {
        HStack(spacing: 5) {
            Text("◉")
                .font(.footnote)
                .foregroundStyle(VGTheme.accentTerra)
                .shadow(color: colorScheme == .dark ? VGTheme.accentTerra.opacity(0.6) : .clear, radius: 4)
            Text("\(appStreak)")
                .font(.system(.footnote, design: .monospaced).weight(.semibold))
                .foregroundStyle(VGTheme.accentTerra)
            Text("day streak")
                .font(.caption2)
                .foregroundStyle(VGTheme.textMuted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(VGTheme.surface)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(VGTheme.separator, lineWidth: 1))
        .accessibilityLabel("\(appStreak) day streak")
    }

    private var bellButton: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "bell.fill")
                .font(.callout)
                .foregroundStyle(VGTheme.textSecondary)
                .frame(width: 44, height: 44)
                .background(VGTheme.surface)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(VGTheme.separator, lineWidth: 1))
            Circle()
                .fill(VGTheme.accentTerra)
                .frame(width: 6, height: 6)
                .offset(x: 1, y: -1)
                .accessibilityHidden(true)
        }
        .accessibilityLabel("Notifications")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Community Goal Card (HOME-03 / D-01)

    private func communityGoalCard(_ challenge: UserChallenge) -> some View {
        let communityProgress: Double = min(
            1.0,
            Double(challenge.totalCheckIns) / Double(max(1, challenge.template?.durationDays ?? 90))
        )
        let percent = Int((communityProgress * 100).rounded())
        let participantCount = challenge.template?.communitySize ?? 0

        return VStack(alignment: .leading, spacing: 12) {
            Text("COMMUNITY GOAL")
                .font(.caption.weight(.semibold))
                .kerning(1.2)
                .textCase(.uppercase)
                .foregroundStyle(VGTheme.muted)
                .accessibilityHidden(true)

            Text(challenge.template?.title ?? "Community Challenge")
                .font(VGTheme.serif(20, weight: .semibold))
                .foregroundStyle(VGTheme.sand)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if participantCount > 0 {
                Text("\(participantCount) people participating")
                    .font(.callout)
                    .foregroundStyle(VGTheme.textMuted)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(VGTheme.surface2)
                        .frame(height: 6)
                    Capsule()
                        .fill(VGTheme.accentTerra)
                        .frame(width: geo.size.width * communityProgress, height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                Spacer()
                Text("\(percent)% complete")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(VGTheme.accentTerra)
            }
        }
        .padding(22)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(challenge.template?.title ?? "Community Challenge") — \(percent)% complete")
    }

    // MARK: - Quick Stats Row (HOME-05 / D-02: single tappable nav card)

    private var quickStatsRow: some View {
        NavigationLink(value: AppRoute.stats) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(VGTheme.accentTerra.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "chart.bar.fill")
                        .font(.title3)
                        .foregroundStyle(VGTheme.accentTerra)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Stats")
                        .font(.callout)
                        .foregroundStyle(VGTheme.textPrimary)
                    Text("Active goals, streaks, badges")
                        .font(.caption)
                        .foregroundStyle(VGTheme.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(VGTheme.textMuted)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(VGTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(VGTheme.separator, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .accessibilityLabel("View your statistics")
        .accessibilityHint("Active goals, streaks, badges")
    }

    // MARK: - Stay Close Section

    private var stayCloseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Stay close")
                    .font(VGTheme.serif(20, weight: .semibold))
                    .foregroundStyle(VGTheme.sand)
                    .accessibilityAddTraits(.isHeader)
                Text("We're a small team and we'd love to hear from you.")
                    .font(.caption)
                    .foregroundStyle(VGTheme.muted)
            }
            .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // About Us card
                    NavigationLink(destination: AboutUsView()) {
                        stayCloseCard(
                            icon: "heart.fill",
                            title: "About Us",
                            subtitle: "Our story"
                        )
                    }
                    .buttonStyle(.plain)

                    // Contact Us card
                    Button {
                        UIApplication.shared.open(URL(string: "mailto:hello@vitamingapp.com")!)
                    } label: {
                        stayCloseCard(
                            icon: "envelope.fill",
                            title: "Contact Us",
                            subtitle: "Say hello"
                        )
                    }
                    .buttonStyle(.plain)

                    // FAQ card
                    NavigationLink(destination: FAQView()) {
                        stayCloseCard(
                            icon: "questionmark.circle.fill",
                            title: "FAQ",
                            subtitle: "Common questions"
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.leading, 24)
                .padding(.trailing, 16)
            }
        }
        .padding(.top, 20)
    }

    private func stayCloseCard(icon: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(VGTheme.accentTerra.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(VGTheme.accentTerra)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(VGTheme.serif(18))
                .foregroundStyle(VGTheme.textPrimary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(VGTheme.textMuted)
            Text("Open →")
                .font(.caption)
                .foregroundStyle(VGTheme.accentTerra)
                .accessibilityHidden(true)
        }
        .padding(16)
        .frame(width: 148)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(VGTheme.separator, lineWidth: 1)
        )
        .accessibilityLabel("\(title): \(subtitle)")
    }

    // MARK: - Secondary Goals (HOME-04 / D-11: +add button + flame icons)

    private var secondaryGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MY GOALS")
                    .font(.caption2.weight(.bold))
                    .kerning(1.2)
                    .foregroundStyle(VGTheme.muted)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button {
                    showingGoalEntryChoice = true
                } label: {
                    Text("+ Add")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(VGTheme.accentTerra)
                }
                .frame(minHeight: 44)
                .accessibilityLabel("Add a new goal")
            }
            .padding(.horizontal, 24)

            if goals.filter({ !$0.isCompleted }).isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Text("Ready to start?")
                        .font(VGTheme.serif(20, weight: .semibold))
                        .foregroundStyle(VGTheme.sand)
                    Text("Tap + Add to set your first goal — small steps, taken daily.")
                        .font(.subheadline)
                        .foregroundStyle(VGTheme.textMuted)
                        .multilineTextAlignment(.center)
                    Button {
                        showingGoalEntryChoice = true
                    } label: {
                        Text("Add a goal")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(VGTheme.accentTerra)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)
                    .accessibilityLabel("Add a goal")
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
            } else {
                ForEach(secondaryGoals) { goal in
                    goalRow(goal)
                        .padding(.horizontal, 24)
                }
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Goal Row Helpers

    private func goalStreak(_ goal: Goal) -> Int {
        let goalEvents = completionEvents.filter { $0.goal?.id == goal.id }
        return StreakEngine.currentStreak(from: goalEvents)
    }

    private func goalRow(_ goal: Goal) -> some View {
        let streak = goalStreak(goal)
        let title = goal.title ?? "Untitled"
        let streakSuffix = streak >= 3 ? ", \(streak) day streak" : ""
        return HStack(spacing: 14) {
            ProgressRingView(
                progress: goalProgress(goal),
                tier: goal.tier,
                isCompleted: goal.isCompleted,
                size: 46,
                strokeWidth: 4,
                glow: true
            )
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(VGTheme.textPrimary)
                    .lineLimit(2)
                HStack(spacing: 4) {
                    Text(goal.tier.displayName)
                        .font(.caption)
                        .foregroundStyle(VGTheme.textMuted)
                    Text("· Today")
                        .font(.caption)
                        .foregroundStyle(VGTheme.accentTerra)
                }
            }
            Spacer()
            // D-11: flame icon on goals with 3+ consecutive day streak
            if streak >= 3 {
                Image(systemName: "flame.fill")
                    .font(.subheadline)
                    .foregroundStyle(VGTheme.accentGold)
                    .accessibilityHidden(true)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.medium))
                .foregroundStyle(VGTheme.textMuted)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(VGTheme.separator, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(goal.tier.displayName)\(streakSuffix)")
        .accessibilityHint("Double tap to view goal details")
    }

    private func goalProgress(_ goal: Goal) -> Double {
        guard let events = goal.completionEvents, !events.isEmpty else { return 0.1 }
        return min(Double(events.count) / 30.0, 1.0)
    }
}
