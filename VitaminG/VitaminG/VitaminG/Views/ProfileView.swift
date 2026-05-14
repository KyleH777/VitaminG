import SwiftUI
import SwiftData

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var activeTab: ProfileViewModel.ProfileTab = .goals
    @State private var selectedMood: Int? = nil

    @Query private var goals: [Goal]
    @Query private var completionEvents: [CompletionEvent]
    @Query private var userChallenges: [UserChallenge]

    private var currentStreak: Int {
        StreakEngine.currentStreak(from: completionEvents, tier: nil)
    }
    private var bestStreak: Int {
        StreakEngine.bestStreak(events: completionEvents)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroBanner
                profileTabBar
                tabContent
                    .padding(.bottom, 32)
                shareAndSettings
            }
        }
        .background(VGTheme.sandLight)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.loadOrCreateProfile(context: modelContext)
            Task { await viewModel.loadReactionCount() }
        }
        .sheet(isPresented: $viewModel.showingEditSheet) {
            ProfileEditSheet(viewModel: viewModel)
        }
        .alert("Couldn't share your profile.", isPresented: $viewModel.showingCloudKitError) {
            Button("Got It", role: .cancel) {}
        } message: {
            Text("Check your internet connection and try again.")
        }
    }

    // MARK: - Hero Banner

    private var heroBanner: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [VGTheme.clay, Color(hex: "#5A3A22")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TODAY'S DOSE")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(VGTheme.muted)
                        .kerning(1.0)
                    Text("\u{201C}\(viewModel.todayQuote)\u{201D}")
                        .font(VGTheme.serifItalic(14))
                        .foregroundStyle(VGTheme.sand.opacity(0.85))
                        .lineLimit(3)
                }
                .padding(12)
                .background(Color.white.opacity(0.07))
                .overlay(
                    Rectangle()
                        .fill(VGTheme.terra)
                        .frame(width: 3),
                    alignment: .leading
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.top, 16)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                HStack(alignment: .bottom, spacing: 14) {
                    ZStack(alignment: .bottomTrailing) {
                        AvatarView(
                            displayName: viewModel.profile?.displayName,
                            avatarColorHex: viewModel.profile?.avatarColorHex,
                            photoData: viewModel.profile?.photoData,
                            size: 72
                        )
                        .overlay(Circle().stroke(VGTheme.clay, lineWidth: 3))

                        Circle()
                            .fill(VGTheme.terra)
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.white)
                            )
                            .overlay(Circle().stroke(VGTheme.clay, lineWidth: 2))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        if let name = viewModel.profile?.displayName, !name.isEmpty {
                            Text(name)
                                .font(VGTheme.serif(22))
                                .foregroundStyle(VGTheme.sand)
                        }
                        Text("Vitamin G Member")
                            .font(.system(size: 12))
                            .foregroundStyle(VGTheme.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        viewModel.draftDisplayName = viewModel.profile?.displayName ?? ""
                        viewModel.showingEditSheet = true
                    } label: {
                        Text("Edit")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(VGTheme.sand)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .accessibilityLabel("Edit profile")
                    .padding(.bottom, 4)
                }
                .padding(.horizontal, 20)

                HStack(spacing: 0) {
                    let stats: [(String, String)] = [
                        (String(currentStreak), "Streak"),
                        (String(goals.count),   "Goals"),
                        (String(completionEvents.count), "Check-ins"),
                        (String(viewModel.reactionCount), "Reactions"),
                    ]
                    ForEach(Array(stats.enumerated()), id: \.offset) { i, stat in
                        VStack(spacing: 2) {
                            Text(stat.0)
                                .font(VGTheme.serif(20))
                                .foregroundStyle(VGTheme.sand)
                            Text(stat.1.uppercased())
                                .font(.system(size: 9))
                                .foregroundStyle(VGTheme.muted)
                                .kerning(0.5)
                        }
                        .frame(maxWidth: .infinity)
                        if i < 3 {
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .frame(height: 32)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("HOW ARE YOU FEELING TODAY?")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(VGTheme.muted)
                        .kerning(0.8)

                    let moods: [(String, String)] = [("🌟","Amazing"),("😊","Good"),("😐","Okay"),("😔","Low"),("💪","Push")]
                    HStack(spacing: 8) {
                        ForEach(Array(moods.enumerated()), id: \.offset) { i, mood in
                            Button {
                                selectedMood = i
                            } label: {
                                VStack(spacing: 3) {
                                    Text(mood.0).font(.system(size: 18))
                                    Text(mood.1)
                                        .font(.system(size: 9))
                                        .foregroundStyle(selectedMood == i ? VGTheme.terraSoft : VGTheme.muted)
                                        .kerning(0.4)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selectedMood == i ? VGTheme.terra.opacity(0.25) : Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedMood == i ? VGTheme.terra.opacity(0.4) : Color.clear, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(mood.1)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Color(VGTheme.sandLight)
                    .frame(height: 24)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 20, bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0, topTrailingRadius: 20
                        )
                    )
                    .padding(.top, 20)
            }
        }
    }

    // MARK: - Tab Bar

    private var profileTabBar: some View {
        let tabs: [(String, ProfileViewModel.ProfileTab)] = [
            ("Goals", .goals), ("Badges", .badges), ("Activity", .activity)
        ]
        return HStack(spacing: 0) {
            ForEach(tabs, id: \.0) { label, tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { activeTab = tab }
                } label: {
                    VStack(spacing: 0) {
                        Text(label)
                            .font(.system(size: 13, weight: activeTab == tab ? .semibold : .regular))
                            .foregroundStyle(activeTab == tab ? VGTheme.terra : VGTheme.muted)
                            .padding(.vertical, 10)
                        Rectangle()
                            .fill(activeTab == tab ? VGTheme.terra : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.plain)
                .accessibilityLabel(label)
            }
        }
        .background(VGTheme.sandLight)
        .overlay(Divider().foregroundStyle(VGTheme.sandMid), alignment: .bottom)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch activeTab {
        case .goals:    goalsTab
        case .badges:   badgesTab
        case .activity: activityTab
        }
    }

    private var goalsTab: some View {
        LazyVStack(spacing: 10) {
            ForEach(GoalSorter.sort(goals, by: .byTier)) { goal in
                NavigationLink(value: AppRoute.goalDetail(goal)) {
                    HStack(spacing: 14) {
                        ProgressRingView(progress: 0, tier: goal.tier, isCompleted: goal.isCompleted)
                            .frame(width: 48, height: 48)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(goal.title ?? "")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(goal.isCompleted ? VGTheme.muted : VGTheme.clay)
                                .strikethrough(goal.isCompleted, color: VGTheme.muted.opacity(0.6))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12)).foregroundStyle(VGTheme.muted)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .background(VGTheme.warmWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: VGTheme.clay.opacity(0.07), radius: 8, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var badgesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            let earnedBadges = allEarnedBadges()
            let allBadges    = allKnownBadges()

            if allBadges.isEmpty {
                Text("Complete challenges to earn badges.")
                    .font(.system(size: 14))
                    .foregroundStyle(VGTheme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(allBadges, id: \.label) { badge in
                        let earned = earnedBadges.contains(badge.sfSymbol)
                        ZStack(alignment: .topTrailing) {
                            VStack(spacing: 8) {
                                Text(badge.emoji).font(.system(size: 28))
                                Text(badge.label)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(earned ? VGTheme.clay : VGTheme.muted)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(earned ? VGTheme.warmWhite : VGTheme.sandMid)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: earned ? VGTheme.clay.opacity(0.1) : .clear, radius: 8, y: 2)
                            .opacity(earned ? 1 : 0.5)

                            if earned {
                                Circle().fill(VGTheme.sage).frame(width: 8, height: 8)
                                    .padding(8)
                            }
                        }
                    }
                }

                if let next = nextUnearned(earned: earnedBadges, all: allBadges) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NEXT BADGE")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(VGTheme.muted).kerning(0.8)
                        HStack(spacing: 12) {
                            Text(next.emoji).font(.system(size: 28)).opacity(0.4)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(next.label)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(VGTheme.clay)
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 99).fill(VGTheme.sandMid).frame(height: 4)
                                        RoundedRectangle(cornerRadius: 99).fill(VGTheme.terra)
                                            .frame(width: geo.size.width * min(1.0, Double(currentStreak) / 7.0), height: 4)
                                    }
                                }.frame(height: 4)
                            }
                        }
                        .padding(14)
                        .background(VGTheme.warmWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: VGTheme.clay.opacity(0.07), radius: 8, y: 1)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var activityTab: some View {
        VStack(spacing: 20) {
            HeatmapCard(events: completionEvents)
            summaryCard
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var summaryCard: some View {
        let completionRate = goals.isEmpty ? 0 : Int((Double(completionEvents.count) / Double(max(1, goals.count * 30))) * 100)
        let stats: [(String, String)] = [
            ("\(min(100, completionRate))%", "Completion rate"),
            (String(currentStreak), "Current streak"),
            (String(bestStreak), "Best streak"),
        ]
        return HStack(spacing: 0) {
            ForEach(Array(stats.enumerated()), id: \.offset) { i, stat in
                VStack(spacing: 4) {
                    Text(stat.0).font(VGTheme.serif(22)).foregroundStyle(VGTheme.terra)
                    Text(stat.1).font(.system(size: 10)).foregroundStyle(VGTheme.muted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                if i < 2 { Divider().frame(height: 32) }
            }
        }
        .padding(16)
        .background(VGTheme.warmWhite)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: VGTheme.clay.opacity(0.07), radius: 8, y: 1)
    }

    // MARK: - Share + Settings

    private var shareAndSettings: some View {
        VStack(spacing: 12) {
            if let url = viewModel.shareURL {
                ShareLink(item: url, subject: Text("Vitamin G Profile"),
                          message: Text("Check out my goals on Vitamin G!")) {
                    Label("Share Profile", systemImage: "square.and.arrow.up")
                        .font(.body.weight(.semibold)).fontDesign(.rounded)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(VGTheme.terra)
            }
            NavigationLink(destination: SettingsView()) {
                HStack(spacing: 12) {
                    Image(systemName: "gear").foregroundStyle(VGTheme.terra).frame(width: 28, height: 28)
                    Text("Settings").font(.body).fontDesign(.rounded).foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                }
                .padding(16)
                .background(VGTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel("Open Settings")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Badge helpers

    struct BadgeDefinition {
        let sfSymbol: String; let emoji: String; let label: String
    }
    private let knownBadges: [BadgeDefinition] = [
        BadgeDefinition(sfSymbol: "flame.fill",  emoji: "🔥", label: "7-Day Streak"),
        BadgeDefinition(sfSymbol: "trophy.fill", emoji: "🏆", label: "30-Day Champ"),
        BadgeDefinition(sfSymbol: "medal.fill",  emoji: "🥇", label: "60-Day Grind"),
        BadgeDefinition(sfSymbol: "star.fill",   emoji: "⭐", label: "90-Day Legend"),
    ]

    private func allKnownBadges() -> [BadgeDefinition] { knownBadges }

    private func allEarnedBadges() -> Set<String> {
        var earned = Set<String>()
        for c in userChallenges {
            guard let data = c.earnedBadgeSymbolsJSON?.data(using: .utf8),
                  let symbols = try? JSONDecoder().decode([String].self, from: data) else { continue }
            symbols.forEach { earned.insert($0) }
        }
        return earned
    }

    private func nextUnearned(earned: Set<String>, all: [BadgeDefinition]) -> BadgeDefinition? {
        all.first { !earned.contains($0.sfSymbol) }
    }
}

// MARK: - HeatmapCard

private struct HeatmapCard: View {
    let events: [CompletionEvent]
    private let days = ["M","T","W","T","F","S","S"]
    private let weeks = 10

    private var activeDays: Set<Date> {
        let cal = Calendar.current
        return Set(events.compactMap { $0.completedAt }.map { cal.startOfDay(for: $0) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Check-in activity")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(VGTheme.clay)
                Spacer()
                Text("Last \(weeks) weeks")
                    .font(.system(size: 12)).foregroundStyle(VGTheme.muted)
            }

            HStack(spacing: 3) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, d in
                    Text(d).font(.system(size: 9)).foregroundStyle(VGTheme.muted)
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)

            VStack(spacing: 3) {
                ForEach(0..<weeks, id: \.self) { week in
                    HStack(spacing: 3) {
                        ForEach(0..<7, id: \.self) { dow in
                            let date = dateFor(week: week, dow: dow)
                            let hasActivity = activeDays.contains(date)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(hasActivity ? VGTheme.terra : VGTheme.sandMid)
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
            .accessibilityHidden(true)
        }
        .padding(16)
        .background(VGTheme.warmWhite)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: VGTheme.clay.opacity(0.07), radius: 8, y: 1)
    }

    private func dateFor(week: Int, dow: Int) -> Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let mondayOffset = -(((weekday + 5) % 7))
        let startOfThisWeek = cal.date(byAdding: .day, value: mondayOffset, to: today)!
        let weekStart = cal.date(byAdding: .day, value: -(weeks - 1 - week) * 7, to: startOfThisWeek)!
        return cal.date(byAdding: .day, value: dow, to: weekStart)!
    }
}
