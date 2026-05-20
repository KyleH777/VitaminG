# Phase 18: Home Tab + Goals Flow Enhancements - Pattern Map

**Mapped:** 2026-05-17
**Files analyzed:** 9 (4 new + 5 modified)
**Analogs found:** 9 / 9

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `Views/HomeView.swift` (modify) | view/dashboard | request-response + CRUD | `Views/GoalListView.swift` | exact |
| `Views/GoalDetailView.swift` (modify) | view/detail | CRUD + event-driven | self (existing) | self |
| `Views/GoalListView.swift` (modify) | view/list | CRUD | self (existing) | self |
| `Views/GoalCreation/GoalCreationWizardView.swift` (modify) | view/wizard | request-response | self (existing) | self |
| `Views/GoalCreation/Step3DetailsScreen.swift` (modify) | view/form | request-response | self (existing) | self |
| `Views/GoalCreation/GoalEntryChoiceView.swift` (NEW) | view/sheet | request-response | `Views/GoalListView.swift` EmptyStateView | role-match |
| `Views/GoalCreation/PremadeGoalsListView.swift` (NEW) | view/list | request-response | `Views/GoalListView.swift` goalScrollView | role-match |
| `Views/CheckInCelebrationView.swift` (NEW) | view/fullscreen-cover | event-driven | `Views/MilestoneCelebrationView.swift` | exact |
| `Views/Components/GoalDayGridView.swift` (NEW) | component/grid | CRUD + batch | `Views/GoalListView.swift` ChallengeHeroCard (week strip) | partial-match |
| `ViewModels/GoalCreationWizardViewModel.swift` (modify) | viewmodel | request-response | self (existing) | self |
| `ViewModels/GoalViewModel.swift` (modify) | viewmodel | CRUD | self (existing) | self |

---

## Pattern Assignments

### `Views/HomeView.swift` (modify — dashboard view, request-response)

**Primary analog:** `VitaminG/VitaminG/VitaminG/Views/HomeView.swift` (self)
**Supporting analog for section structure:** `VitaminG/VitaminG/VitaminG/Views/GoalListView.swift`

**Imports pattern** (HomeView.swift lines 1-3):
```swift
import SwiftUI
import SwiftData
import UIKit
```

**State / query pattern** (HomeView.swift lines 6-13):
```swift
@Query private var goals: [Goal]
@Query private var completionEvents: [CompletionEvent]
@Query private var userChallenges: [UserChallenge]
@Environment(\.modelContext) private var modelContext
@Environment(\.colorScheme) private var colorScheme
@AppStorage("vg_onboardingName") private var storedName: String = ""
@State private var goalVM = GoalViewModel()
```

**Streak badge fix — replace currentStreak computed property** (HomeView.swift lines 134-136):
```swift
// REMOVE this (bug — returns max completion count, not streak):
private var currentStreak: Int {
    goals.compactMap { $0.completionEvents?.count }.max() ?? 0
}

// REPLACE WITH (using StreakEngine — see Shared Patterns > Streak):
private var appStreak: Int {
    StreakEngine.currentStreak(from: completionEvents)
}
```

**Header section pattern** (HomeView.swift lines 76-116):
```swift
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
            streakBadge   // <-- shows appStreak + 🔥 inline per D-03
            bellButton
        }
    }
    .padding(.horizontal, 24)
    .padding(.top, 8)
    .padding(.bottom, 4)
}
```

**Quote section pattern** (HomeView.swift lines 139-171):
```swift
// Structure to keep; replace hardcoded quotes array with VGQuoteBank
private var quoteSection: some View {
    // ... (existing left-border card layout)
    VStack(alignment: .leading, spacing: 6) {
        Text("TODAY'S DOSE")
            .font(.system(size: 9, weight: .semibold))
            .kerning(1.4)
            .textCase(.uppercase)
            .foregroundStyle(VGTheme.textMuted)
        Text(quote)
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
```

**Community goal card pattern** — copy primaryGoalCard structure (HomeView.swift lines 175-227):
```swift
// Adapt primaryGoalCard() → communityGoalCard() using UserChallenge data
// Progress bar instead of ProgressRingView; keep .padding(22) / RoundedRectangle(cornerRadius:20) wrapper
private func communityGoalCard(_ challenge: UserChallenge) -> some View {
    VStack(alignment: .leading, spacing: 16) {
        Text("COMMUNITY GOAL")
            .font(.system(size: 10, weight: .bold))
            .kerning(1.2)
            .foregroundStyle(VGTheme.muted)
        // ... title + ProgressView(value: communityProgress) + daysRemaining
    }
    .padding(22)
    .background(Color.white.opacity(0.07))
    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
    .clipShape(RoundedRectangle(cornerRadius: 20))
    .padding(.horizontal, 24)
    .padding(.top, 20)
}
```

**quickStatsRow NavigationLink pattern** (HomeView.swift lines 266-294) — keep as-is, reshape card UI per D-02:
```swift
private var quickStatsRow: some View {
    NavigationLink(value: AppRoute.stats) {
        HStack(spacing: 8) {
            statCell(value: ..., label: "Active Goals")
            statCell(value: ..., label: "Check-ins")
            statCell(value: ..., label: "Badges")
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(VGTheme.textMuted)
                .padding(.leading, 8)
                .accessibilityHidden(true)
        }
    }
    .buttonStyle(.plain)
    .padding(.horizontal, 24)
    .padding(.top, 16)
    .accessibilityLabel("Stats: ...")
    .accessibilityHint("Opens your full statistics")
}
```

**Goal row with flame icon** — extend goalRow() (HomeView.swift lines 437-471):
```swift
// Add flame icon to existing goalRow() HStack before the chevron:
if goalStreak(goal, allEvents: completionEvents) >= 3 {
    Image(systemName: "flame.fill")
        .font(.system(size: 14))
        .foregroundStyle(VGTheme.accentTerra)
        .accessibilityLabel("\(goalStreak(goal, allEvents: completionEvents)) day streak — on fire!")
}
```

**Sections to REMOVE from HomeView.swift:**
- `dailyWinsEntry` (lines 298-318) — D-04 drop
- `primaryGoalCard` and `checkInCTA` — repurposed as communityGoalCard

**State for goal entry choice sheet** — add to HomeView:
```swift
@State private var showingGoalEntryChoice = false
@State private var showingWizard = false
@State private var wizardStartStep: Int = 0
```

---

### `Views/GoalDetailView.swift` (modify — detail view, CRUD + event-driven)

**Primary analog:** self (`VitaminG/VitaminG/VitaminG/Views/GoalDetailView.swift`)

**Imports pattern** (GoalDetailView.swift lines 1-3):
```swift
import SwiftUI
import SwiftData
import Charts
```

**State additions for check-in celebration:**
```swift
@State private var showingCheckInCelebration = false
// existing: @Query private var allEvents: [CompletionEvent]
```

**goalEvents pattern** (GoalDetailView.swift lines 226-228) — reuse for day grid:
```swift
private var goalEvents: [CompletionEvent] {
    allEvents.filter { $0.goal?.id == goal.id }
}
```

**"Check in for today" CTA** — add above actionsSection, same button style as actionsSection:
```swift
// Same .borderedProminent style as existing "Mark as Complete" button
// Disabled state: goal.completionEvents?.contains(where: { Calendar.current.isDateInToday($0.completedAt ?? .distantPast) }) == true
Button {
    viewModel.addCheckIn(for: goal, context: modelContext)
    showingCheckInCelebration = true
} label: {
    Label("Check in for today", systemImage: "checkmark.circle")
        .font(.system(.body, design: .rounded).weight(.semibold))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
}
.buttonStyle(.borderedProminent)
.tint(VGTheme.accentSage)
.disabled(isCheckedInToday)
.fullScreenCover(isPresented: $showingCheckInCelebration) {
    CheckInCelebrationView(streakCount: appStreak, onDismiss: { showingCheckInCelebration = false })
}
```

**Background + scroll pattern** (GoalDetailView.swift lines 25-36) — keep:
```swift
ScrollView {
    VStack(spacing: 16) {
        headerSection
        publicToggleSection
        quoteCardSection
        GoalDayGridView(goal: goal, completionEvents: allEvents)   // NEW — insert before progressSection
        progressSection
        notesSection
        actionsSection
    }
    .padding(.bottom, 32)
}
.background(Color(.systemGroupedBackground))
```

**Existing card section pattern** (GoalDetailView.swift lines 100-125) — reuse padding/background for GoalDayGridView wrapper:
```swift
// Each section card uses:
.padding(16)
.frame(maxWidth: .infinity, alignment: .leading)
.background(Color(.systemBackground))
.clipShape(RoundedRectangle(cornerRadius: 12))
.padding(.horizontal, 16)
```

---

### `Views/GoalListView.swift` (modify — list view, CRUD)

**Primary analog:** self (`VitaminG/VitaminG/VitaminG/Views/GoalListView.swift`)

**Sheet trigger pattern** (GoalListView.swift line 49) — change target:
```swift
// BEFORE:
.sheet(isPresented: $showingAddGoal) { GoalCreationWizardView() }

// AFTER:
.sheet(isPresented: $showingAddGoal) { GoalEntryChoiceView() }
// Note: GoalEntryChoiceView manages its own NavigationStack for PremadeGoalsListView.
// For wizard paths, GoalEntryChoiceView dismisses itself then sets parent @State showingWizard = true.
```

**"+add" button pattern** (GoalListView.swift lines 78-90) — keep unchanged; only destination changes:
```swift
Button {
    showingAddGoal = true
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
```

---

### `Views/GoalCreation/GoalCreationWizardView.swift` (modify — wizard view, request-response)

**Primary analog:** self (`VitaminG/VitaminG/VitaminG/Views/GoalCreation/GoalCreationWizardView.swift`)

**Init pattern** (GoalCreationWizardView.swift lines 16-19) — extend with startAtStep:
```swift
init(isOnboarding: Bool = false,
     editingGoal: Goal? = nil,
     startAtStep: Int = 0,        // NEW param for D-05/D-06/D-08 paths
     onComplete: (() -> Void)? = nil) {
    self.isOnboarding = isOnboarding
    self.editingGoal = editingGoal
    self.startAtStep = startAtStep
    self.onComplete = onComplete
}
```

**onAppear pattern** (GoalCreationWizardView.swift lines 24-26) — extend:
```swift
.onAppear {
    if let goal = editingGoal {
        wizardVM.configure(from: goal)
    } else if startAtStep > 0 {
        wizardVM.currentStep = startAtStep  // "Already have a goal" → step 1; premade → step 2
    }
}
```

**NavigationStack guard** (GoalCreationWizardView.swift lines 39-53) — KEEP unchanged:
```swift
// CRITICAL: Do NOT add another NavigationStack in GoalEntryChoiceView for wizard paths.
// Wizard wraps itself in NavigationStack when isOnboarding = false.
// Paths 2 and 3 from GoalEntryChoiceView must dismiss the sheet and re-present wizard as new sheet.
@ViewBuilder
private var wizardContent: some View {
    if isOnboarding {
        stepView.navigationBarBackButtonHidden(true)
    } else {
        NavigationStack {
            stepView
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { wizardVM.reset(); dismiss() }
                    }
                }
        }
    }
}
```

---

### `Views/GoalCreation/Step3DetailsScreen.swift` (modify — form view, request-response)

**Primary analog:** self (`VitaminG/VitaminG/VitaminG/Views/GoalCreation/Step3DetailsScreen.swift`)

**Background + safeArea pattern** (Step3DetailsScreen.swift lines 21-23) — keep:
```swift
.background(VGTheme.sandLight.ignoresSafeArea())
.safeAreaInset(edge: .bottom) { saveButton }
```

**Step dots pattern** (Step3DetailsScreen.swift lines 35-43) — reuse for any new step indicators:
```swift
private var stepDots: some View {
    HStack(spacing: 5) {
        ForEach(0..<3) { i in
            Capsule()
                .fill(VGTheme.terra)
                .frame(width: i == 2 ? 22 : 8, height: 8)
        }
    }
}
```

**Section label helper** (Step3DetailsScreen.swift lines 177-180):
```swift
private func sectionLabel(_ text: String) -> some View {
    Text(text).font(.caption).fontWeight(.bold).textCase(.uppercase)
        .foregroundStyle(VGTheme.muted).tracking(1)
}
```

**Card container pattern** (Step3DetailsScreen.swift lines 84-90) — reuse for duration field:
```swift
HStack(spacing: 12) {
    Text("📅").font(.title3)
    VStack(alignment: .leading, spacing: 2) {
        // duration label + stepper or picker
    }
    Spacer()
}
.padding(14)
.background(Color.white)
.clipShape(RoundedRectangle(cornerRadius: 12))
.shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)
```

**Save button pattern** (Step3DetailsScreen.swift lines 163-175) — keep unchanged:
```swift
private var saveButton: some View {
    Button(action: onSave) {
        Text(wizardVM.isEditMode ? "Save changes" : "Start this journey ✨")
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(VGTheme.terra)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    .padding(.horizontal, 24)
    .padding(.bottom, 20)
}
```

**Font constraint (ANTI-PATTERN):** Do NOT use `CormorantGaramond-Medium` in new Phase 18 code. Only use `CormorantGaramond-Regular` or `CormorantGaramond-SemiBold` (via `VGTheme.serif(size, weight: .semibold)`).

---

### `Views/GoalCreation/GoalEntryChoiceView.swift` (NEW — sheet, request-response)

**Closest analog:** `Views/GoalListView.swift` EmptyStateView (lines 370-449) for visual card + button pattern

**Sheet structure pattern** (from GoalListView.swift EmptyStateView):
```swift
// Sheet presents a NavigationStack for the PremadeGoalsListView push only.
// Wizard paths (2 and 3) use a binding callback to dismiss self and let parent present wizard.
struct GoalEntryChoiceView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelectWizard: (Int) -> Void   // called with startAtStep: 0 or 1, then dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 3 path cards
            }
            .padding(.horizontal, 24)
            .background(VGTheme.sandLight.ignoresSafeArea())
            .navigationTitle("How would you like to start?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
```

**Path card pattern** — copy stayCloseCard structure (HomeView.swift lines 375-403):
```swift
private func pathCard(icon: String, title: String, subtitle: String) -> some View {
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
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(VGTheme.surface)
    .clipShape(RoundedRectangle(cornerRadius: 18))
    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(VGTheme.separator, lineWidth: 1))
}
```

---

### `Views/GoalCreation/PremadeGoalsListView.swift` (NEW — list view, request-response)

**Closest analog:** `Views/GoalListView.swift` goalScrollView section (lines 70-133)

**GoalCategory.suggestions data source** (GoalCategory.swift lines 41-75):
```swift
// GoalCategory.suggestions is already structured. Build a flat list:
struct PremadeGoal: Identifiable {
    let id = UUID()
    let title: String
    let category: GoalCategory
}

// Inside PremadeGoalsListView:
private let premadeGoals: [(category: GoalCategory, goals: [PremadeGoal])] =
    GoalCategory.allCases
        .filter { !$0.suggestions.isEmpty }   // excludes .other (0 suggestions)
        .map { cat in
            (category: cat, goals: cat.suggestions.map { PremadeGoal(title: $0, category: cat) })
        }
```

**Section header pattern** (GoalListView.swift lines 135-143):
```swift
private func sectionHeader(_ text: String) -> some View {
    Text(text)
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle(VGTheme.muted)
        .kerning(1.0)
        .padding(.horizontal, 24)
        .padding(.top, 8)
}
```

**Goal row card pattern** — copy goalRow pattern (HomeView.swift lines 437-471) simplified:
```swift
private func premadeGoalRow(_ premadeGoal: PremadeGoal) -> some View {
    HStack(spacing: 14) {
        Text(premadeGoal.category.emoji).font(.title2)
        VStack(alignment: .leading, spacing: 3) {
            Text(premadeGoal.title)
                .font(.system(size: 13.5, weight: .medium))
                .foregroundStyle(VGTheme.textPrimary)
                .lineLimit(2)
            Text(premadeGoal.category.subtitle)
                .font(.system(size: 11))
                .foregroundStyle(VGTheme.textMuted)
        }
        Spacer()
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
```

**Tap action → wizard pre-fill:**
```swift
// On tap of premadeGoalRow, call GoalCreationWizardViewModel.configure(fromPremade:category:)
// then navigate to GoalCreationWizardView(startAtStep: 2) from parent.
// Use a binding or onSelect callback rather than direct NavigationLink to wizard
// (avoids nested NavigationStack — see Anti-Patterns).
```

---

### `Views/CheckInCelebrationView.swift` (NEW — fullScreenCover, event-driven)

**Primary analog:** `VitaminG/VitaminG/VitaminG/Views/MilestoneCelebrationView.swift` (lines 1-166) — exact copy pattern

**Struct signature** (adapted from MilestoneCelebrationView.swift lines 16-19):
```swift
struct CheckInCelebrationView: View {
    let streakCount: Int        // overall app streak from StreakEngine.currentStreak(from: allEvents)
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var badgeScale: Double = 0.3
    @State private var badgeOpacity: Double = 0.0
}
```

**Full-screen overlay + confetti structure** (MilestoneCelebrationView.swift lines 54-100) — copy exactly:
```swift
var body: some View {
    ZStack {
        Color.black.opacity(0.92).ignoresSafeArea()      // same opacity as MilestoneCelebrationView

        confettiView
            .ignoresSafeArea()
            .accessibilityHidden(true)

        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(VGTheme.accentSage)
                .scaleEffect(badgeScale)
                .opacity(badgeOpacity)
                .accessibilityLabel("Check-in complete!")

            Text("Day \(streakCount) streak!")
                .font(.title2.weight(.semibold).design(.rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button("Back to Goals") { onDismiss() }
                .font(.body.weight(.semibold).design(.rounded))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(VGTheme.accentSage)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
        }
    }
    .onAppear {
        // Auto-dismiss after 2s (D-13) — same DispatchQueue pattern
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { onDismiss() }
        // Accessibility announcement
        UIAccessibility.post(notification: .announcement,
            argument: "Check-in complete! \(streakCount) day streak")
        // Badge spring animation (same as MilestoneCelebrationView)
        if reduceMotion {
            badgeScale = 1.0; badgeOpacity = 1.0
        } else {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                badgeScale = 1.0; badgeOpacity = 1.0
            }
        }
    }
}
```

**Confetti canvas** (MilestoneCelebrationView.swift lines 123-141) — copy verbatim:
```swift
private var confettiView: some View {
    TimelineView(.animation) { timeline in
        Canvas { context, size in
            let now = timeline.date.timeIntervalSinceReferenceDate
            let count = 60
            for i in 0..<count {
                let seed = Double(i) * 137.5
                let x = (sin(seed + now * 0.8 + Double(i)) * 0.5 + 0.5) * size.width
                let rawY = (now * 80.0 + seed * 3.7).truncatingRemainder(dividingBy: size.height)
                let y = rawY < 0 ? rawY + size.height : rawY
                let hue = (seed / 360.0).truncatingRemainder(dividingBy: 1.0)
                let color = Color(hue: hue, saturation: 0.8, brightness: 0.9)
                let rect = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)
                context.fill(Path(rect), with: .color(color))
            }
        }
    }
}
```

**Key difference from MilestoneCelebrationView:** No `saveBadgeToProfile()` call needed — check-in celebration is per-event, not a one-time milestone badge. Remove lines 143-165.

---

### `Views/Components/GoalDayGridView.swift` (NEW — component/grid, CRUD + batch)

**Closest analog:** `Views/GoalListView.swift` ChallengeHeroCard week strip (lines 188-244) — partial match for day cell visual; `Views/GoalDetailView.swift` progressSection (lines 245-334) for section card layout

**Component signature:**
```swift
struct GoalDayGridView: View {
    let goal: Goal
    let completionEvents: [CompletionEvent]   // pass allEvents from GoalDetailView @Query
    @State private var displayedMonth: Date = Date()

    private let columns = Array(repeating: GridItem(.fixed(36), spacing: 8), count: 7)
    private let dayHeaders = ["M", "T", "W", "T", "F", "S", "S"]
}
```

**completedDays set pattern** (from StreakEngine.swift lines 43-45 logic):
```swift
private var completedDays: Set<Date> {
    Set(completionEvents
        .filter { $0.goal?.id == goal.id }
        .compactMap { $0.completedAt }
        .map { Calendar.current.startOfDay(for: $0) })
}
```

**Calendar month cells builder** (per RESEARCH.md Pattern 4):
```swift
private var daysInMonth: [Date?] {
    var calendar = Calendar.current
    calendar.firstWeekday = 2   // Monday start — MUST override default (Pitfall 5 from RESEARCH.md)
    guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
          let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
    else { return [] }
    let weekdayOffset = (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
    var days: [Date?] = Array(repeating: nil, count: weekdayOffset)
    for day in range {
        if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
            days.append(date)
        }
    }
    return days
}
```

**Day cell visual** — adapt ChallengeHeroCard week bar (GoalListView.swift lines 232-244) into circles:
```swift
// ChallengeHeroCard uses RoundedRectangle bars; GoalDayGridView uses circles
// Copy fill logic: filled = completed, empty = not completed / future
private func dayCell(date: Date?, isCompleted: Bool) -> some View {
    Group {
        if let date {
            let dayNum = Calendar.current.component(.day, from: date)
            ZStack {
                Circle()
                    .fill(isCompleted ? VGTheme.accentSage : VGTheme.separator)
                    .frame(width: 32, height: 32)
                Text("\(dayNum)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isCompleted ? .white : VGTheme.textMuted)
            }
        } else {
            Circle()
                .fill(Color.clear)
                .frame(width: 32, height: 32)
        }
    }
    .frame(width: 36, height: 36)
}
```

**Section card container** — copy progressSection wrapper (GoalDetailView.swift lines 329-334):
```swift
// GoalDayGridView wraps its content with the same card style as other GoalDetailView sections
.padding(16)
.frame(maxWidth: .infinity, alignment: .leading)
.background(Color(.systemBackground))
.clipShape(RoundedRectangle(cornerRadius: 12))
.padding(.horizontal, 16)
```

**Month navigation bounds** (per RESEARCH.md Pattern 4):
```swift
private var canNavigateForward: Bool {
    // Cannot go past current month
    let thisMonth = Calendar.current.dateComponents([.year, .month], from: Date())
    let shownMonth = Calendar.current.dateComponents([.year, .month], from: displayedMonth)
    return shownMonth.year! < thisMonth.year! ||
           (shownMonth.year! == thisMonth.year! && shownMonth.month! < thisMonth.month!)
}

private var canNavigateBack: Bool {
    // Cannot go before goal's start date
    guard let start = goal.startDate ?? goal.creationDate else { return false }
    let startMonth = Calendar.current.dateComponents([.year, .month], from: start)
    let shownMonth = Calendar.current.dateComponents([.year, .month], from: displayedMonth)
    return shownMonth.year! > startMonth.year! ||
           (shownMonth.year! == startMonth.year! && shownMonth.month! > startMonth.month!)
}
```

---

### `ViewModels/GoalCreationWizardViewModel.swift` (modify — viewmodel, request-response)

**Primary analog:** self (`VitaminG/VitaminG/VitaminG/ViewModels/GoalCreationWizardViewModel.swift`)

**configure(from:) pattern** (GoalCreationWizardViewModel.swift lines 64-82) — add sibling method:
```swift
// Add alongside existing configure(from goal: Goal)
func configure(fromPremade title: String, category: GoalCategory) {
    reset()                          // clears all state to defaults
    selectedCategory = category
    draftTitle = title
    currentStep = 2                  // jump directly to Step 3 (details) per D-06
}
```

**@Observable + @MainActor class pattern** (GoalCreationWizardViewModel.swift lines 4-6):
```swift
@MainActor
@Observable
final class GoalCreationWizardViewModel {
```

---

### `ViewModels/GoalViewModel.swift` (modify — viewmodel, CRUD)

**Primary analog:** self (`VitaminG/VitaminG/VitaminG/ViewModels/GoalViewModel.swift`)

**toggleCompletion pattern** (GoalViewModel.swift lines 114-139) — new parallel method addCheckIn:
```swift
// New method — distinct from toggleCompletion (which flips isCompleted permanently)
// Add after toggleCompletion (line 139)
func addCheckIn(for goal: Goal, context: ModelContext) {
    // Guard: prevent duplicate check-in on same calendar day (Pitfall 3 from RESEARCH.md)
    let alreadyCheckedIn = goal.completionEvents?.contains(where: {
        Calendar.current.isDateInToday($0.completedAt ?? .distantPast)
    }) ?? false
    guard !alreadyCheckedIn else { return }

    let event = CompletionEvent()
    event.completedAt = Date()
    event.tierRawValue = goal.tierRawValue
    context.insert(event)
    event.goal = goal
    // NOTE: does NOT set goal.isCompleted — check-in is daily progress, not permanent completion
    rescheduleNotification(context: context)
    reloadWidgetTimelines()
}
```

---

## Shared Patterns

### Streak Computation
**Source:** `VitaminG/VitaminG/VitaminG/Services/StreakEngine.swift` lines 31-78
**Apply to:** HomeView (header badge), CheckInCelebrationView (streak count display), GoalDetailView (flame icon)
```swift
// Overall app streak (HomeView, CheckInCelebrationView):
StreakEngine.currentStreak(from: completionEvents)   // tier: nil → all tiers

// Per-goal streak (flame icon in goal rows):
private func goalStreak(_ goal: Goal, allEvents: [CompletionEvent]) -> Int {
    let goalEvents = allEvents.filter { $0.goal?.id == goal.id }
    return StreakEngine.currentStreak(from: goalEvents)
}
// Flame threshold: >= 3 consecutive days (D-11)
```

### Theme Tokens
**Source:** `VitaminG/VitaminG/VitaminG/VGTheme.swift`
**Apply to:** ALL new and modified files
```swift
// Typography:
VGTheme.serif(size)                        // CormorantGaramond-Regular
VGTheme.serif(size, weight: .semibold)    // CormorantGaramond-SemiBold ONLY
VGTheme.serifItalic(size)                 // CormorantGaramond italic

// Colors (semantic tokens — do NOT use raw hex):
VGTheme.sandLight    // scroll view background: .background(VGTheme.sandLight.ignoresSafeArea())
VGTheme.surface      // card backgrounds (light/dark adaptive)
VGTheme.textPrimary  // primary text
VGTheme.textMuted    // secondary/muted text
VGTheme.accentTerra  // primary accent (buttons, highlights)
VGTheme.accentSage   // check-in / success state (GoalDayGridView filled cells, CTA)
VGTheme.separator    // card borders (strokeBorder)
VGTheme.clay         // serif heading color (wizard screens)
VGTheme.muted        // step labels, captions
```

### SwiftData Query Pattern
**Source:** `Views/GoalListView.swift` lines 6-8, `Views/GoalDetailView.swift` lines 22-23
**Apply to:** All views with live data needs
```swift
@Query private var goals: [Goal]
@Query private var completionEvents: [CompletionEvent]
@Query private var userChallenges: [UserChallenge]
@Environment(\.modelContext) private var modelContext
```

### fullScreenCover + Auto-Dismiss Pattern
**Source:** `Views/GoalListView.swift` lines 56-67 (milestoneTask) + `Views/MilestoneCelebrationView.swift` lines 102-118
**Apply to:** CheckInCelebrationView, GoalDetailView (trigger)
```swift
// Trigger in GoalDetailView:
@State private var showingCheckInCelebration = false

// In GoalDetailView body:
.fullScreenCover(isPresented: $showingCheckInCelebration) {
    CheckInCelebrationView(streakCount: appStreak, onDismiss: {
        showingCheckInCelebration = false
    })
}

// Inside CheckInCelebrationView.onAppear:
DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { onDismiss() }
```

### Sheet + Wizard Presentation Pattern
**Source:** `Views/GoalListView.swift` line 49, `Views/GoalDetailView.swift` lines 48-49
**Apply to:** HomeView, GoalListView (both trigger GoalEntryChoiceView)
```swift
// Parent view holds wizard state:
@State private var showingGoalEntryChoice = false
@State private var showingWizard = false
@State private var wizardStartStep: Int = 0

// Sheet chain:
.sheet(isPresented: $showingGoalEntryChoice) {
    GoalEntryChoiceView(onSelectWizard: { step in
        wizardStartStep = step
        showingGoalEntryChoice = false
        // Slight delay to allow sheet dismissal before presenting wizard
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showingWizard = true
        }
    })
}
.sheet(isPresented: $showingWizard) {
    GoalCreationWizardView(startAtStep: wizardStartStep)
}
```

### Card Container Pattern
**Source:** `Views/GoalDetailView.swift` lines 100-125, `Views/GoalListView.swift` lines 314-319
**Apply to:** All new view sections (GoalDayGridView, GoalEntryChoiceView path cards, community goal card)
```swift
// Standard card container (GoalDetailView style — systemBackground):
.padding(16)
.frame(maxWidth: .infinity, alignment: .leading)
.background(Color(.systemBackground))
.clipShape(RoundedRectangle(cornerRadius: 12))
.padding(.horizontal, 16)

// Standard card container (GoalListView/HomeView style — VGTheme.surface):
.padding(.horizontal, 14)
.padding(.vertical, 14)
.background(VGTheme.surface)
.clipShape(RoundedRectangle(cornerRadius: 14))
.overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(VGTheme.separator, lineWidth: 1))
```

### Accessibility Pattern
**Source:** `Views/MilestoneCelebrationView.swift` lines 113-118, `Views/GoalListView.swift` GoalCardView lines 350-351
**Apply to:** CheckInCelebrationView, GoalDayGridView, GoalEntryChoiceView
```swift
// Announcement on appear:
UIAccessibility.post(notification: .announcement, argument: "Check-in complete! \(streakCount) day streak")

// Reduce motion guard:
@Environment(\.accessibilityReduceMotion) private var reduceMotion
// In animations: if reduceMotion { /* static */ } else { withAnimation(.spring(...)) { ... } }

// accessibilityHidden for decorative elements:
confettiView.accessibilityHidden(true)
```

---

## No Analog Found

All files in Phase 18 have analogs in the codebase. No new patterns are required beyond the existing project conventions.

---

## Anti-Patterns to Avoid

From RESEARCH.md — documented here for planner reference:

| Anti-Pattern | Source of Truth | Correct Alternative |
|---|---|---|
| `goals.compactMap { $0.completionEvents?.count }.max()` for streak | HomeView.swift line 135 (bug) | `StreakEngine.currentStreak(from: completionEvents)` |
| `toggleCompletion()` for daily check-in | GoalViewModel.swift line 114 | New `addCheckIn(for:context:)` method |
| Nested NavigationStack in GoalEntryChoiceView | GoalCreationWizardView.swift lines 39-53 | Dismiss sheet first, then present wizard as new sheet |
| `@Attribute(.unique)` on any model field | CLAUDE.md | No uniqueness attribute; app-level dedup instead |
| Force-unwrapping `goal.completionEvents` | All goal models | `goal.completionEvents ?? []` |
| Raw hex color values | VGTheme.swift | `VGTheme.*` semantic tokens only |
| `CormorantGaramond-Medium` font weight | Step3DetailsScreen.swift line 153 | Regular or SemiBold only in Phase 18 |

---

## Metadata

**Analog search scope:** `VitaminG/VitaminG/VitaminG/` (Views, ViewModels, Services, Models, Components)
**Files scanned:** 11 source files read directly
**Key files read:**
- `Views/HomeView.swift`
- `Views/GoalDetailView.swift`
- `Views/GoalListView.swift`
- `Views/GoalCreation/GoalCreationWizardView.swift`
- `Views/GoalCreation/Step3DetailsScreen.swift`
- `Views/MilestoneCelebrationView.swift`
- `Views/Components/ProgressRingView.swift`
- `ViewModels/GoalCreationWizardViewModel.swift`
- `ViewModels/GoalViewModel.swift`
- `Services/StreakEngine.swift`
- `Models/GoalCategory.swift`

**Pattern extraction date:** 2026-05-17
**Valid until:** 2026-06-17
