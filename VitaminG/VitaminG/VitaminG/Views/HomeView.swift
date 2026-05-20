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

    // HOME-02: daily quote from VGQuoteBank.all rotated by day-of-year
    private var todaysQuote: VGQuote {
        let all = VGQuoteBank.all
        guard !all.isEmpty else {
            return VGQuote(text: "Small steps, taken daily, build the life you've been dreaming of.", attribution: "Vitamin G")
        }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % all.count
        return all[index]
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
                    quoteSection
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
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(VGTheme.textMuted)
                    .kerning(0.5)
                Text(displayName)
                    .font(VGTheme.serif(26))
                    .foregroundStyle(VGTheme.sand)
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
                .font(.system(size: 13))
                .foregroundStyle(VGTheme.accentTerra)
                .shadow(color: colorScheme == .dark ? VGTheme.accentTerra.opacity(0.6) : .clear, radius: 4)
            Text("\(appStreak)")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(VGTheme.accentTerra)
            Text("day streak")
                .font(.system(size: 11))
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
                .font(.system(size: 16))
                .foregroundStyle(VGTheme.textSecondary)
                .frame(width: 36, height: 36)
                .background(VGTheme.surface)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(VGTheme.separator, lineWidth: 1))
            Circle()
                .fill(VGTheme.accentTerra)
                .frame(width: 6, height: 6)
                .offset(x: 1, y: -1)
        }
    }

    // MARK: - Quote (HOME-02: VGQuoteBank.all with day-of-year rotation)

    private var quoteSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TODAY'S DOSE")
                .font(.system(size: 9, weight: .semibold))
                .kerning(1.4)
                .textCase(.uppercase)
                .foregroundStyle(VGTheme.textMuted)
            Text(todaysQuote.text)
                .font(VGTheme.serifItalic(16))
                .foregroundStyle(VGTheme.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(VGTheme.surface)
        .overlay(alignment: .leading) {
            Rectangle().frame(width: 2).foregroundStyle(VGTheme.accentTerra)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 24)
        .padding(.top, 20)
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
                .font(.system(size: 13, weight: .semibold))
                .kerning(1.2)
                .textCase(.uppercase)
                .foregroundStyle(VGTheme.muted)

            Text(challenge.template?.title ?? "Community Challenge")
                .font(VGTheme.serif(20, weight: .semibold))
                .foregroundStyle(VGTheme.sand)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if participantCount > 0 {
                Text("\(participantCount) people participating")
                    .font(.system(size: 13))
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
                    .font(.system(size: 13, weight: .semibold))
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
                        .font(.system(size: 18))
                        .foregroundStyle(VGTheme.accentTerra)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Stats")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(VGTheme.textPrimary)
                    Text("Active goals, streaks, badges")
                        .font(.system(size: 12))
                        .foregroundStyle(VGTheme.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
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
                Text("We're a small team and we'd love to hear from you.")
                    .font(.system(size: 12))
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
                    .font(.system(size: 20))
                    .foregroundStyle(VGTheme.accentTerra)
            }
            Text(title)
                .font(VGTheme.serif(18))
                .foregroundStyle(VGTheme.textPrimary)
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(VGTheme.textMuted)
            Text("Open →")
                .font(.system(size: 12))
                .foregroundStyle(VGTheme.accentTerra)
        }
        .padding(16)
        .frame(width: 148)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(VGTheme.separator, lineWidth: 1)
        )
    }

    // MARK: - Secondary Goals (HOME-04 / D-11: +add button + flame icons)

    private var secondaryGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MY GOALS")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(1.2)
                    .foregroundStyle(VGTheme.muted)
                Spacer()
                Button {
                    showingGoalEntryChoice = true
                } label: {
                    Text("+ Add")
                        .font(.system(size: 13, weight: .semibold))
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
                        .font(.system(size: 14))
                        .foregroundStyle(VGTheme.textMuted)
                        .multilineTextAlignment(.center)
                    Button {
                        showingGoalEntryChoice = true
                    } label: {
                        Text("Add a goal")
                            .font(.system(size: 16, weight: .semibold))
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
        HStack(spacing: 14) {
            ProgressRingView(
                progress: goalProgress(goal),
                tier: goal.tier,
                isCompleted: goal.isCompleted,
                size: 46,
                strokeWidth: 4,
                glow: true
            )
            VStack(alignment: .leading, spacing: 3) {
                Text(goal.title ?? "Untitled")
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(VGTheme.textPrimary)
                    .lineLimit(2)
                HStack(spacing: 4) {
                    Text(goal.tier.displayName)
                        .font(.system(size: 11))
                        .foregroundStyle(VGTheme.textMuted)
                    Text("· Today")
                        .font(.system(size: 11))
                        .foregroundStyle(VGTheme.accentTerra)
                }
            }
            Spacer()
            // D-11: flame icon on goals with 3+ consecutive day streak
            if goalStreak(goal) >= 3 {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(VGTheme.accentGold)
                    .accessibilityLabel("\(goalStreak(goal)) day streak — on fire!")
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(VGTheme.textMuted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(VGTheme.separator, lineWidth: 1))
    }

    private func goalProgress(_ goal: Goal) -> Double {
        guard let events = goal.completionEvents, !events.isEmpty else { return 0.1 }
        return min(Double(events.count) / 30.0, 1.0)
    }
}
