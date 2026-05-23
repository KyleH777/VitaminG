import Foundation

// MARK: - GifterGoal

struct GifterGoal: Identifiable {
    let id = UUID()
    let title: String
    let category: GoalCategory
}

// MARK: - ExploreContent (static pool)

enum ExploreContent {

    // MARK: Gifter pool (20 items, deterministic daily selection)
    static let gifterPool: [GifterGoal] = [
        GifterGoal(title: "Drink 2 litres of water today", category: .wellness),
        GifterGoal(title: "Take a 10-minute walk outside", category: .body),
        GifterGoal(title: "Read 10 pages of any book", category: .mind),
        GifterGoal(title: "Write down 3 things you're grateful for", category: .wellness),
        GifterGoal(title: "Do 5 minutes of deep breathing", category: .wellness),
        GifterGoal(title: "Call or text someone you care about", category: .connection),
        GifterGoal(title: "Put your phone down for 1 hour", category: .habit),
        GifterGoal(title: "Sketch or doodle something — anything", category: .creative),
        GifterGoal(title: "Make your bed first thing", category: .habit),
        GifterGoal(title: "Pack a healthy lunch instead of buying", category: .money),
        GifterGoal(title: "Do 20 bodyweight squats", category: .body),
        GifterGoal(title: "Write a sentence about today's intention", category: .mind),
        GifterGoal(title: "Track one expense you'd normally ignore", category: .money),
        GifterGoal(title: "Send a genuine compliment to someone", category: .connection),
        GifterGoal(title: "Learn one new fact today", category: .mind),
        GifterGoal(title: "Stretch for 5 minutes before bed", category: .body),
        GifterGoal(title: "Cook one meal at home instead of ordering", category: .money),
        GifterGoal(title: "Write one paragraph of anything creative", category: .creative),
        GifterGoal(title: "Go to bed 30 minutes earlier tonight", category: .wellness),
        GifterGoal(title: "Do one thing you've been putting off", category: .habit),
    ]

    // MARK: Deterministic daily selection
    static var todaysGifterGoal: GifterGoal {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % gifterPool.count
        return gifterPool[index]
    }
}

// MARK: - MoodOption

enum MoodOption: String, CaseIterable, Identifiable {
    case amazing = "Amazing"
    case good    = "Good"
    case okay    = "Okay"
    case low     = "Low"
    case push    = "Push"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .amazing: return "🤩"
        case .good:    return "😊"
        case .okay:    return "😐"
        case .low:     return "😔"
        case .push:    return "💪"
        }
    }
}

// MARK: - TrendingGoalItem (local model — mirrors TrendingGoal CKRecord fields)

struct TrendingGoalItem: Identifiable {
    let id: String          // CKRecord.recordID.recordName or stable static ID
    let title: String
    let category: GoalCategory
    let participantCount: Int
    let completedCount: Int

    /// Community completion percentage (0.0–1.0)
    var communityProgress: Double {
        guard participantCount > 0 else { return 0 }
        return min(Double(completedCount) / Double(participantCount), 1.0)
    }
}

// MARK: - StuckDayGift

struct StuckDayGift: Identifiable {
    /// Stable string ID — must never change. Used as UserDefaults hide key suffix.
    let id: String
    let title: String
    let category: GoalCategory
    let emoji: String
    let subtitle: String
}

// MARK: - ExploreContent extensions (Trending + Stuck)

extension ExploreContent {

    // MARK: Static Trending fallback (used if CloudKit fetch fails or schema not yet deployed)
    static let staticTrendingGoals: [TrendingGoalItem] = [
        TrendingGoalItem(id: "trend_water", title: "Drink 2L of water every day",
                         category: .wellness, participantCount: 1420, completedCount: 985),
        TrendingGoalItem(id: "trend_walk", title: "Walk 8,000 steps daily",
                         category: .body, participantCount: 2310, completedCount: 1540),
        TrendingGoalItem(id: "trend_journal", title: "Journal for 5 minutes every morning",
                         category: .mind, participantCount: 870, completedCount: 612),
        TrendingGoalItem(id: "trend_savings", title: "Save $50 every week",
                         category: .money, participantCount: 630, completedCount: 392),
        TrendingGoalItem(id: "trend_reach_out", title: "Text someone you care about daily",
                         category: .connection, participantCount: 550, completedCount: 410),
    ]

    // MARK: Stuck Day Gifts pool (12 items — 3 shown per day by day-of-year offset)
    static let stuckDayGiftsPool: [StuckDayGift] = [
        StuckDayGift(id: "stuck_water", title: "Drink a full glass of water right now",
                     category: .wellness, emoji: "💧", subtitle: "Hydration is a win."),
        StuckDayGift(id: "stuck_walk", title: "Step outside for 5 minutes",
                     category: .body, emoji: "🚶", subtitle: "Fresh air resets everything."),
        StuckDayGift(id: "stuck_gratitude", title: "Write down one thing you're grateful for",
                     category: .wellness, emoji: "🙏", subtitle: "Tiny shift, big impact."),
        StuckDayGift(id: "stuck_stretch", title: "Stretch for 3 minutes",
                     category: .body, emoji: "🧘", subtitle: "Your body will thank you."),
        StuckDayGift(id: "stuck_text", title: "Text someone you haven't spoken to in a while",
                     category: .connection, emoji: "💬", subtitle: "Connection is growth."),
        StuckDayGift(id: "stuck_tidy", title: "Tidy one small area around you",
                     category: .habit, emoji: "✨", subtitle: "Clear space, clear mind."),
        StuckDayGift(id: "stuck_breath", title: "Take 5 deep breaths",
                     category: .wellness, emoji: "🌬️", subtitle: "Reset in under a minute."),
        StuckDayGift(id: "stuck_read", title: "Read 2 pages of any book",
                     category: .mind, emoji: "📖", subtitle: "2 pages is a habit."),
        StuckDayGift(id: "stuck_track", title: "Track one expense from today",
                     category: .money, emoji: "📊", subtitle: "Awareness is the first step."),
        StuckDayGift(id: "stuck_doodle", title: "Sketch or doodle for 2 minutes",
                     category: .creative, emoji: "✏️", subtitle: "Play is productive."),
        StuckDayGift(id: "stuck_compliment", title: "Give someone a genuine compliment",
                     category: .connection, emoji: "❤️", subtitle: "Kindness is a workout too."),
        StuckDayGift(id: "stuck_pushups", title: "Do 10 push-ups or squats",
                     category: .body, emoji: "💪", subtitle: "Momentum starts small."),
    ]

    // MARK: Deterministic today's 3 stuck-day gifts
    static var todaysStuckDayGifts: [StuckDayGift] {
        let pool = stuckDayGiftsPool
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let startIndex = (dayOfYear - 1) % pool.count
        return (0..<3).map { offset in pool[(startIndex + offset) % pool.count] }
    }
}
