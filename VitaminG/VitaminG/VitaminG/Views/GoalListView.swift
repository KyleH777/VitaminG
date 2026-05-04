import SwiftUI
import SwiftData

// MARK: - GoalListView

struct GoalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [Goal]   // no sort descriptor — dynamic sort via computed property
    @Query private var events: [CompletionEvent]

    @State private var viewModel = GoalViewModel()
    @State private var showingAddGoal = false
    @State private var goalToDelete: Goal?
    @State private var showingDeleteConfirmation = false
    @State private var sortOption: SortOption = .byTier
    @State private var pendingMilestone: (goalID: UUID, threshold: Int)? = nil

    // MARK: Derived

    private var hasAnyGoals: Bool { !goals.isEmpty }

    /// All goals sorted by the current SortOption.
    private var sortedGoals: [Goal] {
        GoalSorter.sort(goals, by: sortOption)
    }

    /// Goals for a tier section, sourced from sortedGoals.
    /// GoalSorter.byTier already orders active before completed within tier (D-09).
    private func goals(for tier: GoalTier) -> [Goal] {
        sortedGoals.filter { $0.tier == tier }
    }

    // MARK: Body

    var body: some View {
        Group {
            if hasAnyGoals {
                goalList
            } else {
                EmptyStateView {
                    showingAddGoal = true
                }
            }
        }
        .navigationTitle("My Goals")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddGoal = true
                } label: {
                    Label("Add Goal", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    Picker("Sort", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Label(option.displayName, systemImage: option.systemImage)
                                .tag(option)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "line.3.horizontal.decrease.circle")
                }
                .accessibilityLabel("Sort goals")
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalView(viewModel: viewModel)
        }
        .confirmationDialog(
            "Delete this goal?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let goal = goalToDelete {
                    viewModel.delete(goal: goal, context: modelContext)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: Goal List

    private var goalList: some View {
        List {
            if sortOption == .byCompletionStatus {
                // D-08: Two sections — Active (tier-ordered within) + Completed (flat)
                let active    = sortedGoals.filter { !$0.completed }
                let completed = sortedGoals.filter { $0.completed }
                if !active.isEmpty {
                    Section("Active") {
                        ForEach(active) { goal in
                            goalRow(for: goal)
                        }
                    }
                }
                if !completed.isEmpty {
                    Section("Completed") {
                        ForEach(completed) { goal in
                            goalRow(for: goal)
                        }
                    }
                }
            } else {
                // Tier sections (byTier default + byCreationDate)
                ForEach(GoalTier.ordered, id: \.self) { tier in
                    let tieredGoals = goals(for: tier)
                    TierSectionView(tier: tier) {
                        if tieredGoals.isEmpty {
                            EmptyTierView(tier: tier) {
                                viewModel.draftTier = tier
                                showingAddGoal = true
                            }
                        } else {
                            ForEach(tieredGoals) { goal in
                                goalRow(for: goal)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.easeOut(duration: 0.25), value: sortOption)
        .animation(.easeOut(duration: 0.15), value: goals.count)
        .onChange(of: viewModel.pendingMilestone?.goalID) { _, _ in
            // Consume the milestone event from GoalViewModel and route it to the
            // matching row via @State. The row observes its own milestoneThreshold
            // parameter via .onChange(of:) and triggers the overlay.
            if let milestone = viewModel.pendingMilestone {
                pendingMilestone = milestone
                viewModel.pendingMilestone = nil
                // Auto-clear after the animation window so the same threshold can
                // refire on a subsequent goal that hits the same count.
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(3))
                    pendingMilestone = nil
                }
            }
        }
    }

    // MARK: Goal Row Helper

    @ViewBuilder
    private func goalRow(for goal: Goal) -> some View {
        let milestoneThreshold: Int? = (pendingMilestone?.goalID == goal.id)
            ? pendingMilestone?.threshold
            : nil
        NavigationLink(value: AppRoute.goalDetail(goal)) {
            GoalRowView(
                goal: goal,
                events: events,
                milestoneThreshold: milestoneThreshold,
                onToggle: {
                    viewModel.toggleCompletion(goal: goal, context: modelContext)
                }
            )
        }
        .listRowBackground(
            goal.completed
                ? Color(red: 0.063, green: 0.725, blue: 0.506).opacity(0.08)
                : Color(.secondarySystemGroupedBackground)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                goalToDelete = goal
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - TierSectionView

private struct TierSectionView<Content: View>: View {
    let tier: GoalTier
    @ViewBuilder let content: () -> Content

    var body: some View {
        Section {
            content()
        } header: {
            HStack(spacing: 8) {
                Image(systemName: tier.icon)
                    .foregroundStyle(tier.color)
                Text(tier.displayName)
                    .font(.subheadline.weight(tier.typographicWeight))
                    .foregroundStyle(tier.color)
            }
            .textCase(nil)
        }
    }
}

// MARK: - GoalRowView

private struct GoalRowView: View {
    let goal: Goal
    let events: [CompletionEvent]
    let milestoneThreshold: Int?
    let onToggle: () -> Void

    // MARK: - Milestone Badge State (PROG-03)
    @State private var showMilestoneBadge = false
    @State private var badgeOpacity: Double = 0
    @State private var badgeScale: CGFloat = 0.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bounceScale: CGFloat = 1.0
    @State private var bounceTask: Task<Void, Never>?
    @State private var badgeTask: Task<Void, Never>?

    private let completionGreen = Color.completionGreen
    private let progressVM = ProgressViewModel()

    var body: some View {
        HStack(spacing: 14) {
            // Completion toggle — bounce effect on state change (D-10)
            Button(action: onToggle) {
                Image(systemName: goal.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(goal.completed ? completionGreen : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: goal.completed)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel(goal.completed
                ? "Mark \(goal.title ?? "goal") as active"
                : "Mark \(goal.title ?? "goal") as complete")

            VStack(alignment: .leading, spacing: 3) {
                // Title: completionGreen with thin strikethrough when complete (D-10, UI-SPEC)
                Text(goal.title ?? "")
                    .font(.body.weight(goal.tier.typographicWeight)).fontDesign(.rounded)
                    .foregroundStyle(goal.completed ? completionGreen : Color.primary)
                    .strikethrough(goal.completed, pattern: .solid,
                                   color: completionGreen.opacity(0.5))

                if let desc = goal.goalDescription, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // PROG-01 — circular progress ring replaces the prior tier pip (D-01)
            ProgressRingView(
                progress: progressVM.ringProgress(for: goal, events: events),
                tier: goal.tier,
                isCompleted: goal.completed
            )
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .overlay(alignment: .center) {
            if showMilestoneBadge, let threshold = milestoneThreshold {
                Image(systemName: threshold == 50 ? "trophy.fill" : "star.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(goal.tier.color)
                    .scaleEffect(badgeScale)
                    .opacity(badgeOpacity)
                    .zIndex(1)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .scaleEffect(bounceScale)
        .onChange(of: goal.completed) { _, _ in
            guard !reduceMotion else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                bounceScale = 1.02
            }
            bounceTask?.cancel()
            bounceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    bounceScale = 1.0
                }
            }
        }
        .onDisappear {
            bounceTask?.cancel()
            badgeTask?.cancel()
        }
        .onChange(of: milestoneThreshold) { _, newValue in
            guard newValue != nil else { return }
            fireMilestoneBadge(threshold: newValue ?? 0)
        }
    }

    // MARK: - Milestone Badge Animation (PROG-03, D-12, D-14)

    private func fireMilestoneBadge(threshold: Int) {
        showMilestoneBadge = true
        UIAccessibility.post(notification: .announcement,
                             argument: "Milestone reached: \(threshold) completions!")
        badgeTask?.cancel()
        if reduceMotion {
            // Static badge: instant in, hold 0.5s, fade 0.2s
            badgeOpacity = 1.0
            badgeScale = 1.0
            badgeTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                withAnimation(.easeIn(duration: 0.2)) { badgeOpacity = 0 }
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled else { return }
                showMilestoneBadge = false
                badgeScale = 0.5
            }
        } else {
            // Default: scale 0.5→1.2, opacity 0→1 (0.2s) → spring to 1.0 → hold 1.5s → fade 0.3s
            withAnimation(.easeOut(duration: 0.2)) {
                badgeOpacity = 1.0
                badgeScale = 1.2
            }
            badgeTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    badgeScale = 1.0
                }
                try? await Task.sleep(for: .milliseconds(1500))
                guard !Task.isCancelled else { return }
                withAnimation(.easeIn(duration: 0.3)) { badgeOpacity = 0 }
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                showMilestoneBadge = false
                badgeScale = 0.5
            }
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

            // Illustration
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.55, blue: 0.27).opacity(0.15),
                                Color(red: 0.78, green: 0.48, blue: 0.95).opacity(0.15)
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
                                Color(red: 0.98, green: 0.55, blue: 0.27),
                                Color(red: 0.78, green: 0.48, blue: 0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse, isActive: !reduceMotion)
            }

            // Copy
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

            // CTA
            Button(action: onAddTapped) {
                Label("Add Your First Goal", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.55, blue: 0.27),
                                Color(red: 0.78, green: 0.48, blue: 0.95)
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
        .background(Color(.systemGroupedBackground))
    }
}
