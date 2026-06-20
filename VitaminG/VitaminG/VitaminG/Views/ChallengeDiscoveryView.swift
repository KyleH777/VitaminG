import SwiftUI
import SwiftData

// MARK: - ChallengeDiscoveryView

/// Root view for the Challenges tab (CHAL-08, D-04, CHAL-23).
///
/// Phase 15-06: Redesigned with Dispenser → MoodScanner → buildYourOwn → Trending → VitaminShelf layout.
/// Phase 15 — Plan 08 replaces localNavigationPath with real ContentView binding
struct ChallengeDiscoveryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ChallengeViewModel()
    @State private var goalVM = GoalViewModel()
    @Query private var templates: [ChallengeTemplate]
    @Query private var userChallenges: [UserChallenge]
    @State private var showBuildYourOwn = false
    @State private var selectedMood: String = "All"
    @State private var localNavigationPath: NavigationPath = NavigationPath()
    @Binding var navigationPath: NavigationPath

    init(navigationPath: Binding<NavigationPath> = .constant(NavigationPath())) {
        self._navigationPath = navigationPath
    }

    private let catalogue = ChallengeLibrary.categories

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VitaminDispenserView(selectedMood: $selectedMood, navigationPath: $localNavigationPath, goalVM: goalVM)
                MoodScannerView(selectedMood: $selectedMood)
                buildYourOwnButton
                if !templates.filter({ $0.isFeatured }).isEmpty {
                    TrendingChallengesRow(
                        templates: templates.filter { $0.isFeatured },
                        userChallenges: userChallenges,
                        onJoin: joinChallenge
                    )
                }
                VitaminShelfGrid(navigationPath: $localNavigationPath, goalVM: goalVM)
                if selectedMood != "All" {
                    moodFilteredList
                }
            }
            .padding(.top, 8)
        }
        .background(VGTheme.background)
        .navigationTitle("Challenges")
        .onAppear {
            viewModel.seedFeaturedTemplates(context: modelContext)
        }
        .sheet(isPresented: $showBuildYourOwn) {
            CustomChallengeBuilderView()
        }
    }

    // MARK: - Mood-Filtered List

    private var moodFilteredList: some View {
        LazyVStack(spacing: 8) {
            let filtered = ChallengeLibrary.categories.flatMap { $0.goals }.filter {
                $0.title.localizedCaseInsensitiveContains(selectedMood)
            }
            ForEach(filtered) { goal in
                HStack {
                    Text(goal.title)
                        .font(.callout)
                        .fontDesign(.rounded)
                        .foregroundStyle(VGTheme.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(VGTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Build Your Own Button

    private var buildYourOwnButton: some View {
        Button("Build Your Own") {
            showBuildYourOwn = true
        }
        .font(.body)
        .fontWeight(.semibold)
        .fontDesign(.rounded)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(Color(.secondarySystemGroupedBackground))
        .foregroundStyle(VGTheme.textPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel("Build Your Own Challenge")
        .padding(.horizontal, 16)
    }

    // MARK: - Empty State

    private var emptyFeaturedState: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 48))
                .foregroundStyle(VGTheme.textMuted)
                .accessibilityHidden(true)
            Text("No Challenges Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.textPrimary)
            Text("Featured challenges are coming soon. Check back to find your next goal.")
                .font(.body)
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Actions

    private func joinChallenge(_ template: ChallengeTemplate) {
        viewModel.joinChallenge(template: template, context: modelContext)
    }
}

// MARK: - ChallengeCardView

/// Card row displayed in the Featured Challenges section.
/// Shows template icon, title, description, community size, and a Join/View Progress button.
/// Used exclusively within ChallengeDiscoveryView.
private struct ChallengeCardView: View {
    let template: ChallengeTemplate
    let userChallenge: UserChallenge?
    let onJoin: () -> Void

    private var accentColor: Color {
        Color(hex: template.accentColorHex ?? "#C4673A")
    }

    private var isJoined: Bool { userChallenge != nil }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: template.iconName ?? "flame.fill")
                .font(.largeTitle)
                .foregroundStyle(accentColor)
                .frame(width: 40)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(template.title ?? "Challenge")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.textPrimary)
                Text(template.challengeDescription ?? "")
                    .font(.body)
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.textMuted)
                    .lineLimit(1)
                if template.communitySize > 0 {
                    Text("\(template.communitySize.formatted()) people")
                        .font(.caption)
                        .fontDesign(.rounded)
                        .foregroundStyle(VGTheme.textMuted)
                }
            }
            Spacer()

            if isJoined {
                if let challenge = userChallenge {
                    NavigationLink(value: AppRoute.challengeDetail(challenge)) {
                        Text("View Progress")
                            .font(.body)
                            .fontWeight(.semibold)
                            .fontDesign(.rounded)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(VGTheme.textPrimary)
                    }
                    .accessibilityLabel("View progress for \(template.title ?? "challenge")")
                }
            } else {
                Button {
                    onJoin()
                } label: {
                    Text("Join Challenge")
                        .font(.body)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)
                }
                .frame(minHeight: 44)
                .accessibilityLabel("Join \(template.title ?? "challenge")")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - MoodScannerView

private struct MoodScannerView: View {
    @Binding var selectedMood: String
    private let moods = ["All", "Tired", "Stuck", "Hopeful", "Fired up", "Soft"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(moods, id: \.self) { mood in
                    let isActive = selectedMood == mood
                    Button { selectedMood = mood } label: {
                        Text(mood)
                            .font(.callout.weight(isActive ? .semibold : .regular))
                            .fontDesign(.rounded)
                            .foregroundStyle(isActive ? Color.white : VGTheme.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isActive ? VGTheme.accentTerra : VGTheme.surface)
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(isActive ? Color.clear : VGTheme.separator, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                    .accessibilityLabel(mood)
                    .accessibilityAddTraits(isActive ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - TrendingChallengesRow

private struct TrendingChallengesRow: View {
    let templates: [ChallengeTemplate]
    let userChallenges: [UserChallenge]
    let onJoin: (ChallengeTemplate) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Trending")
                .font(.caption.weight(.semibold))
                .kerning(0.4)
                .foregroundStyle(VGTheme.textMuted)
                .padding(.horizontal, 16)
                .accessibilityAddTraits(.isHeader)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(templates, id: \.id) { template in
                        let accentColor = Color(hex: template.accentColorHex ?? "#C4673A")
                        let isJoined = userChallenges.first(where: { $0.template?.id == template.id }) != nil
                        Button {
                            if !isJoined { onJoin(template) }
                        } label: {
                            ZStack(alignment: .bottomLeading) {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(LinearGradient(
                                        colors: [accentColor, accentColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 180, height: 120)
                                VStack(alignment: .leading, spacing: 6) {
                                    Image(systemName: template.iconName ?? "flame.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .accessibilityHidden(true)
                                    Text(template.title ?? "")
                                        .font(.callout.weight(.semibold))
                                        .fontDesign(.rounded)
                                        .foregroundStyle(.white)
                                        .lineLimit(2)
                                    if template.communitySize > 0 {
                                        Text("\(template.communitySize.formatted()) joined")
                                            .font(.caption2)
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                }
                                .padding(12)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isJoined
                            ? "\(template.title ?? "Challenge"), already joined"
                            : "Join \(template.title ?? "Challenge"). \(template.communitySize) members joined.")
                        .accessibilityAddTraits(.isButton)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - VitaminShelfGrid

private struct VitaminShelfGrid: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var navigationPath: NavigationPath
    let goalVM: GoalViewModel
    @State private var expandedCategory: String? = nil
    private let catalogue = ChallengeLibrary.categories

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vitamin Shelf")
                .font(.caption.weight(.semibold))
                .kerning(0.4)
                .foregroundStyle(VGTheme.textMuted)
                .padding(.horizontal, 16)
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(catalogue) { section in
                    VStack(alignment: .leading, spacing: 0) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                expandedCategory = expandedCategory == section.name ? nil : section.name
                            }
                        } label: {
                            HStack {
                                Text(section.icon)
                                    .font(.title3)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(section.name)
                                        .font(.caption.weight(.semibold))
                                        .fontDesign(.rounded)
                                        .foregroundStyle(VGTheme.textPrimary)
                                        .lineLimit(1)
                                    Text("\(section.goals.count) goals")
                                        .font(.caption2)
                                        .foregroundStyle(VGTheme.textMuted)
                                }
                                Spacer()
                                Image(systemName: expandedCategory == section.name ? "chevron.up" : "chevron.down")
                                    .font(.caption2)
                                    .foregroundStyle(VGTheme.textMuted)
                                    .accessibilityHidden(true)
                            }
                            .padding(14)
                            .background(VGTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(VGTheme.separator, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(section.name), \(section.goals.count) goals, \(expandedCategory == section.name ? "expanded" : "collapsed")")
                        .accessibilityHint(expandedCategory == section.name ? "Tap to collapse" : "Tap to expand")
                    }
                    .gridCellColumns(expandedCategory == section.name ? 2 : 1)

                    if expandedCategory == section.name {
                        ForEach(section.goals.prefix(3)) { goal in
                            HStack {
                                Text(goal.title)
                                    .font(.callout)
                                    .fontDesign(.rounded)
                                    .foregroundStyle(VGTheme.textPrimary)
                                    .lineLimit(2)
                                Spacer()
                                Button("Add") {
                                    let input = GoalInput(
                                        title: goal.title,
                                        tier: .shortTerm,
                                        category: .habit,
                                        frequency: .daily,
                                        reminderTime: nil,
                                        isPrivate: false,
                                        startDate: nil
                                    )
                                    if let newGoal = try? goalVM.addGoal(input: input, context: modelContext) {
                                        navigationPath.append(AppRoute.goalDetail(newGoal))
                                    }
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(VGTheme.accentTerra)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(VGTheme.accentTerra.opacity(0.12))
                                .clipShape(Capsule())
                                .frame(minHeight: 44)
                                .accessibilityLabel("Add \(goal.title) to my goals")
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(VGTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .gridCellColumns(2)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - VitaminDispenserView

private struct VitaminDispenserView: View {
    @Binding var selectedMood: String
    @Binding var navigationPath: NavigationPath
    let goalVM: GoalViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var dispensedGoal: GoalTemplate? = nil
    @State private var isShaking: Bool = false

    private var moodFiltered: [GoalTemplate] {
        let all = ChallengeLibrary.categories.flatMap { $0.goals }
        return selectedMood == "All" ? all : all.filter {
            $0.title.localizedCaseInsensitiveContains(selectedMood)
        }
    }

    private func dispense() {
        guard !moodFiltered.isEmpty else { return }
        dispensedGoal = moodFiltered.randomElement()
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
            isShaking = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isShaking = false
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(LinearGradient(
                        colors: [VGTheme.accentTerra.opacity(0.15), VGTheme.accentTerra.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(height: 160)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .strokeBorder(VGTheme.accentTerra.opacity(0.2), lineWidth: 1)
                    )
                VStack(spacing: 8) {
                    VGCapsule(size: 48, color1: VGTheme.terraSoft, color2: VGTheme.terra)
                        .rotationEffect(.degrees(isShaking ? 15 : 0))
                    Text("Vitamin Dispenser")
                        .font(.callout.weight(.semibold))
                        .fontDesign(.rounded)
                        .foregroundStyle(VGTheme.textPrimary)
                    Text("Shake for a goal")
                        .font(.caption)
                        .foregroundStyle(VGTheme.textMuted)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 10).onEnded { _ in dispense() }
            )
            .accessibilityLabel("Vitamin Dispenser. Swipe to get a random goal suggestion.")

            Button("Give it a shake") { dispense() }
                .font(.callout.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.accentTerra)

            if let goal = dispensedGoal {
                VStack(alignment: .leading, spacing: 12) {
                    Text(goal.title)
                        .font(.callout.weight(.medium))
                        .fontDesign(.rounded)
                        .foregroundStyle(VGTheme.textPrimary)
                    HStack(spacing: 10) {
                        Button("Shake again") { dispense() }
                            .font(.callout)
                            .foregroundStyle(VGTheme.textMuted)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(VGTheme.surface)
                            .clipShape(Capsule())
                            .frame(minHeight: 44)
                        Spacer()
                        Button("Add to my goals") {
                            let input = GoalInput(
                                title: goal.title,
                                tier: .shortTerm,
                                category: .habit,
                                frequency: .daily,
                                reminderTime: nil,
                                isPrivate: false,
                                startDate: nil
                            )
                            if let newGoal = try? goalVM.addGoal(input: input, context: modelContext) {
                                dispensedGoal = nil
                                navigationPath.append(AppRoute.goalDetail(newGoal))
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(VGTheme.accentTerra)
                        .clipShape(Capsule())
                        .frame(minHeight: 44)
                        .accessibilityLabel("Add \(goal.title) to my goals")
                    }
                }
                .padding(16)
                .background(VGTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(VGTheme.separator, lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}
