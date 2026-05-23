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
