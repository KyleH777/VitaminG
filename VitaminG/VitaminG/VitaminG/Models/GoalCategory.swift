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
            return ["Work out 4 times this week", "Run a 5K without stopping",
                    "Do 10 push-ups every morning", "Walk 8,000 steps every day",
                    "No junk food for 21 days"]
        case .mind:
            return ["Read 20 pages every night before sleep", "Finish one book this month",
                    "Learn one new word daily", "Journal for 5 minutes every morning",
                    "No social media before noon"]
        case .wellness:
            return ["Be in bed by 10:30 pm", "Drink 3 litres of water daily",
                    "No alcohol this month", "Meditate for 10 minutes daily",
                    "Take a 10-minute walk every day"]
        case .money:
            return ["Save $200 this month", "Track every expense for 30 days",
                    "No unnecessary purchases for 2 weeks", "Pack lunch 4 days a week",
                    "Transfer 10% of every paycheck to savings"]
        case .connection:
            return ["Call a friend or family member once a week",
                    "Plan one meaningful outing this month",
                    "Put the phone away at dinner every night",
                    "Send a genuine compliment once a day"]
        case .creative:
            return ["Write 300 words every day", "Sketch something every evening",
                    "Finish one project you've been putting off",
                    "Learn one chord or one note every day"]
        case .habit:
            return ["No phone in bed", "Make your bed every single morning",
                    "Floss every night", "10-minute tidy before bed",
                    "First thing: drink water, not scroll"]
        case .other:
            return []
        }
    }
}
