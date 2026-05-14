import Foundation

enum GoalCategory: String, CaseIterable, Identifiable {
    case body       = "Body"
    case mind       = "Mind"
    case wellness   = "Wellness"
    case money      = "Money"
    case connection = "Connection"
    case creative   = "Creative"
    case habit      = "Habit"
    case other      = "Other"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .body:       return "💪"
        case .mind:       return "🧠"
        case .wellness:   return "🌿"
        case .money:      return "💸"
        case .connection: return "❤️"
        case .creative:   return "🎨"
        case .habit:      return "🌱"
        case .other:      return "✨"
        }
    }

    var subtitle: String {
        switch self {
        case .body:       return "Move, lift, stretch"
        case .mind:       return "Read, learn, focus"
        case .wellness:   return "Sleep, hydrate, breathe"
        case .money:      return "Save, invest, budget"
        case .connection: return "Family, friends, love"
        case .creative:   return "Make, write, build"
        case .habit:      return "Quit, change, replace"
        case .other:      return "Something uniquely yours"
        }
    }

    var suggestions: [String] {
        switch self {
        case .body:
            return ["Walk 10,000 steps", "Work out 3×/week", "Run a 5K", "Stretch daily", "No junk food"]
        case .mind:
            return ["Read 20 pages daily", "Learn one new thing", "Meditate 10 min", "No phone first hour", "Journal every night"]
        case .wellness:
            return ["Sleep by 11pm", "Drink 8 glasses of water", "No alcohol this month", "Morning walk", "Breathe before reacting"]
        case .money:
            return ["Save $500 this month", "No impulse buys", "Track every expense", "Build 3-month emergency fund"]
        case .connection:
            return ["Call a friend weekly", "Family dinner every Sunday", "Send a thank-you note", "No phones at dinner"]
        case .creative:
            return ["Write 500 words daily", "Finish one project", "Learn an instrument", "Sketch every day"]
        case .habit:
            return ["Quit social media scrolling", "No snooze button", "Replace coffee with tea", "10 min cleanup daily"]
        case .other:
            return ["Something uniquely yours"]
        }
    }
}
