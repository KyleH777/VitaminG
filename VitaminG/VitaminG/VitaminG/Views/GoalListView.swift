import SwiftUI
import SwiftData

struct GoalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [Goal]
    @Query private var events: [CompletionEvent]
    @Query private var userChallenges: [UserChallenge]
    @Query private var profiles: [UserProfile]

    @State private var viewModel = GoalViewModel()
    @State private var showingGoalEntryChoice = false
    @State private var showingWizard = false
    @State private var wizardStartStep: Int = 0
    @State private var pendingPremadeGoal: (title: String, category: GoalCategory)? = nil
    @State private var goalToDelete: Goal?
    @State private var showingDeleteConfirmation = false
    @State private var sortOption: SortOption = .byTier
    @State private var pendingMilestone: (goalID: UUID, threshold: Int)? = nil
    @State private var milestoneTask: Task<Void, Never>?

    // MILE-04: Per-goal streak milestone (separate from challenge pendingMilestone)
    @State private var pendingGoalMilestone: (goalID: UUID, threshold: Int)? = nil

    private var hasAnyGoals: Bool { !goals.isEmpty }
    private var sortedGoals: [Goal] { GoalSorter.sort(goals, by: sortOption) }
    private func goals(for tier: GoalTier) -> [Goal] { sortedGoals.filter { $0.tier == tier } }
    private var primaryChallenge: UserChallenge? {
        userChallenges.first(where: { $0.statusRaw == "active" })
    }

    var body: some View {
        Group {
            if hasAnyGoals {
                goalScrollView
            } else {
                EmptyStateView { showingGoalEntryChoice = true }
            }
        }
        .background(VGTheme.background)
        .onDisappear { milestoneTask?.cancel() }
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    Picker("Sort", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Label(option.displayName, systemImage: option.systemImage).tag(option)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "line.3.horizontal.decrease.circle")
                }
                .accessibilityLabel("Sort goals")
            }
        }
        .sheet(isPresented: $showingGoalEntryChoice) {
            GoalEntryChoiceView(
                onSelectWizard: { step in
                    wizardStartStep = step
                    pendingPremadeGoal = nil
                    showingGoalEntryChoice = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showingWizard = true
                    }
                },
                onSelectPremade: { title, category in
                    wizardStartStep = 2
                    pendingPremadeGoal = (title, category)
                    showingGoalEntryChoice = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showingWizard = true
                    }
                }
            )
        }
        .sheet(isPresented: $showingWizard) {
            GoalCreationWizardView(startAtStep: wizardStartStep, premadeGoal: pendingPremadeGoal)
        }
        .confirmationDialog("Delete this goal?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let goal = goalToDelete { viewModel.delete(goal: goal, context: modelContext) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This action cannot be undone.") }
        .onChange(of: viewModel.pendingMilestone?.goalID) { _, _ in
            if let milestone = viewModel.pendingMilestone {
                pendingMilestone = milestone
                viewModel.pendingMilestone = nil
                milestoneTask?.cancel()
                milestoneTask = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(3))
                    guard !Task.isCancelled else { return }
                    pendingMilestone = nil
                }
            }
        }
        // MILE-04: Consume pendingGoalMilestone for per-goal streak celebrations
        .onChange(of: viewModel.pendingGoalMilestone?.goalID) { _, _ in
            if let milestone = viewModel.pendingGoalMilestone {
                pendingGoalMilestone = milestone
                viewModel.pendingGoalMilestone = nil
            }
        }
        // MILE-04: Present GoalStreakMilestoneView when pendingGoalMilestone fires
        .fullScreenCover(
            isPresented: Binding(
                get: { pendingGoalMilestone != nil },
                set: { if !$0 { pendingGoalMilestone = nil } }
            )
        ) {
            if let milestone = pendingGoalMilestone {
                let matchedGoal = goals.first(where: { $0.id == milestone.goalID })
                GoalStreakMilestoneView(
                    goalID: milestone.goalID,
                    threshold: milestone.threshold,
                    goalTitle: matchedGoal?.title ?? "",
                    streakCount: StreakEngine.currentStreak(from: matchedGoal?.completionEvents ?? []),
                    onShareToCommunity: {
                        if let matchedGoal {
                            viewModel.shareGoalMilestone(
                                goalID: milestone.goalID,
                                threshold: milestone.threshold,
                                goalTitle: matchedGoal.title ?? "",
                                username: profiles.first?.username ?? profiles.first?.displayName ?? "",
                                colorHex: profiles.first?.avatarColorHex ?? ""
                            )
                        }
                        pendingGoalMilestone = nil
                    },
                    onDismiss: { pendingGoalMilestone = nil }
                )
            }
        }
    }

    private var goalScrollView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("My Goals")
                        .font(VGTheme.serif(28))
                        .foregroundStyle(VGTheme.clay)
                    Spacer()
                    Button {
                        showingGoalEntryChoice = true
                    } label: {
                        Text("+ New goal")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(VGTheme.background)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(VGTheme.accentTerra)
                            .clipShape(Capsule())
                    }
                    .shadow(color: VGTheme.accentTerra.opacity(0.4), radius: 8)
                    .accessibilityLabel("Add new goal")
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 4)

                if let challenge = primaryChallenge {
                    ChallengeHeroCard(challenge: challenge)
                        .padding(.horizontal, 16)
                }

                if sortOption == .byCompletionStatus {
                    let active    = sortedGoals.filter { !$0.isCompleted }
                    let completed = sortedGoals.filter { $0.isCompleted }
                    if !active.isEmpty {
                        sectionHeader("Active")
                        ForEach(active) { goal in goalCard(for: goal) }
                    }
                    if !completed.isEmpty {
                        sectionHeader("Completed")
                        ForEach(completed) { goal in goalCard(for: goal) }
                    }
                } else {
                    ForEach(GoalTier.ordered, id: \.self) { tier in
                        let tieredGoals = goals(for: tier)
                        sectionHeader(tier.displayName.uppercased())
                        if tieredGoals.isEmpty {
                            EmptyTierView(tier: tier) {
                                viewModel.draftTier = tier
                                showingGoalEntryChoice = true
                            }
                            .padding(.horizontal, 16)
                        } else {
                            ForEach(tieredGoals) { goal in goalCard(for: goal) }
                        }
                    }
                }

                Spacer(minLength: 32)
            }
        }
        .animation(.easeOut(duration: 0.25), value: sortOption)
        .animation(.easeOut(duration: 0.15), value: goals.count)
    }

    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(VGTheme.muted)
            .kerning(1.0)
            .padding(.horizontal, 24)
            .padding(.top, 8)
    }

    @ViewBuilder
    private func goalCard(for goal: Goal) -> some View {
        let milestoneThreshold: Int? = (pendingMilestone?.goalID == goal.id)
            ? pendingMilestone?.threshold : nil
        NavigationLink(value: AppRoute.goalDetail(goal)) {
            GoalCardView(
                goal: goal,
                events: events,
                milestoneThreshold: milestoneThreshold,
                onToggle: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    viewModel.toggleCompletion(goal: goal, context: modelContext)
                    if goal.isCompleted {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
            )
        }
        .buttonStyle(GoalRowButtonStyle())
        .padding(.horizontal, 16)
        .contextMenu {
            Button(role: .destructive) {
                goalToDelete = goal
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - ChallengeHeroCard

private struct ChallengeHeroCard: View {
    let challenge: UserChallenge

    private var challengeName: String { challenge.template?.title ?? "Challenge" }
    private var category: String { challenge.template?.category ?? "" }
    private var dayNumber: Int { challenge.totalCheckIns }
    private var daysRemaining: Int { max(0, (challenge.template?.durationDays ?? 90) - dayNumber) }
    private var progress: Double {
        let total = Double(challenge.template?.durationDays ?? 90)
        return min(1.0, Double(dayNumber) / max(1, total))
    }
    private let weekDays = ["M","T","W","T","F","S","S"]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(VGTheme.terra.opacity(0.15))
                .frame(width: 120, height: 120)
                .offset(x: 30, y: -30)

            VStack(alignment: .leading, spacing: 0) {
                Text(category.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(VGTheme.muted)
                    .kerning(1.2)
                    .padding(.bottom, 12)

                HStack(alignment: .center, spacing: 18) {
                    ProgressRingView(
                        progress: progress,
                        tier: .immediate,
                        isCompleted: false
                    )
                    .frame(width: 80, height: 80)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(challengeName)
                            .font(VGTheme.serif(18))
                            .foregroundStyle(VGTheme.sand)
                            .lineLimit(2)
                        Text("\(daysRemaining) days remaining")
                            .font(.system(size: 12))
                            .foregroundStyle(VGTheme.muted)
                        HStack(spacing: 5) {
                            Circle().fill(VGTheme.sage).frame(width: 8, height: 8)
                            Text("On track")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(VGTheme.sage)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.bottom, 16)

                HStack(spacing: 6) {
                    ForEach(Array(weekDays.enumerated()), id: \.offset) { i, day in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(i < 5 ? VGTheme.terraSoft.opacity(0.7) : VGTheme.separator)
                                .frame(height: 28)
                            Text(day)
                                .font(.system(size: 10))
                                .foregroundStyle(VGTheme.muted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [VGTheme.clay, VGTheme.clayMid],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: VGTheme.clay.opacity(0.3), radius: 12, y: 4)
    }
}

// MARK: - GoalRowButtonStyle

struct GoalRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - GoalCardView

private struct GoalCardView: View {
    let goal: Goal
    let events: [CompletionEvent]
    let milestoneThreshold: Int?
    let onToggle: () -> Void

    @State private var showMilestoneBadge = false
    @State private var badgeOpacity: Double = 0
    @State private var badgeScale: CGFloat = 0.5
    @State private var bounceScale: CGFloat = 1.0
    @State private var bounceTask: Task<Void, Never>?
    @State private var badgeTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 14) {
            ProgressRingView(
                progress: ProgressViewModel().ringProgress(for: goal, events: events),
                tier: goal.tier,
                isCompleted: goal.isCompleted
            )
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(goal.title ?? "")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(goal.isCompleted ? VGTheme.textMuted : VGTheme.textPrimary)
                    .strikethrough(goal.isCompleted, color: VGTheme.textMuted.opacity(0.6))
                    .lineLimit(2)
                if let desc = goal.goalDescription, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 12))
                        .foregroundStyle(VGTheme.muted)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(VGTheme.muted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(VGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(VGTheme.separator, lineWidth: 1))
        .scaleEffect(bounceScale)
        .overlay(alignment: .center) {
            if showMilestoneBadge, let threshold = milestoneThreshold {
                Image(systemName: threshold == 50 ? "trophy.fill" : "star.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(goal.tier.color)
                    .scaleEffect(badgeScale)
                    .opacity(badgeOpacity)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .onChange(of: goal.isCompleted) { _, _ in
            guard !reduceMotion else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { bounceScale = 1.02 }
            bounceTask?.cancel()
            bounceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { bounceScale = 1.0 }
            }
        }
        .onChange(of: milestoneThreshold) { _, newValue in
            guard newValue != nil else { return }
            fireMilestoneBadge(threshold: newValue ?? 0)
        }
        .onDisappear { bounceTask?.cancel(); badgeTask?.cancel() }
    }

    private func fireMilestoneBadge(threshold: Int) {
        showMilestoneBadge = true
        UIAccessibility.post(notification: .announcement, argument: "Milestone reached: \(threshold) completions!")
        badgeTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) { badgeOpacity = 1.0; badgeScale = 1.2 }
        badgeTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { badgeScale = 1.0 }
            try? await Task.sleep(for: .milliseconds(1500))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.3)) { badgeOpacity = 0 }
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            showMilestoneBadge = false; badgeScale = 0.5
        }
    }
}

// MARK: - EmptyStateView

struct EmptyStateView: View {
    let onAddTapped: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                VGTheme.accentTerra.opacity(0.15),
                                VGTheme.accentPurple.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)

                Image(systemName: "star.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                VGTheme.accentTerra,
                                VGTheme.accentPurple
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse, isActive: !reduceMotion)
            }

            VStack(spacing: 12) {
                Text("Time to take your Vitamin G!")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("Start making goals to get your daily dose\nof gratitude and inspiration.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Button(action: onAddTapped) {
                Label("Add Your First Goal", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [
                                VGTheme.accentTerra,
                                VGTheme.accentPurple
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VGTheme.background)
    }
}
