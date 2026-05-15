import Foundation

// MARK: - ChallengeLibrary
// Static catalogue — no network, no SwiftData. Read-only at runtime.

struct GoalTemplate: Identifiable {
    let id = UUID()
    let title: String
    let duration: String
    let level: String          // "Easy" | "Medium" | "Hard"
}

struct GoalCategorySection: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let colorToken: String     // matches VGTheme accent name
    let goals: [GoalTemplate]
}

enum ChallengeLibrary {
    static let categories: [GoalCategorySection] = [
        .init(name: "Morning Habits", icon: "◐", colorToken: "terra", goals: [
            .init(title: "No phone for the first 30 minutes", duration: "Daily habit", level: "Medium"),
            .init(title: "Make your bed before leaving your room", duration: "Daily habit", level: "Easy"),
            .init(title: "Drink a full glass of water before coffee", duration: "Daily habit", level: "Easy"),
            .init(title: "5-minute morning journal", duration: "Daily habit", level: "Easy"),
            .init(title: "Cold shower every morning", duration: "Daily habit", level: "Hard"),
        ]),
        .init(name: "Movement", icon: "◎", colorToken: "sage", goals: [
            .init(title: "10-minute walk after every meal", duration: "Daily habit", level: "Easy"),
            .init(title: "3 full workouts per week", duration: "Weekly", level: "Medium"),
            .init(title: "Stretch for 5 minutes before bed", duration: "Daily habit", level: "Easy"),
            .init(title: "Take the stairs every time", duration: "Daily habit", level: "Easy"),
            .init(title: "Stand up every hour at work", duration: "Daily habit", level: "Easy"),
        ]),
        .init(name: "Mindfulness", icon: "◇", colorToken: "purple", goals: [
            .init(title: "Meditate for 10 minutes daily", duration: "Daily habit", level: "Easy"),
            .init(title: "3 deep breaths before any hard conversation", duration: "Daily habit", level: "Easy"),
            .init(title: "One hour of phone-free time per day", duration: "Daily habit", level: "Medium"),
            .init(title: "Gratitude — write 3 things every night", duration: "Daily habit", level: "Easy"),
        ]),
        .init(name: "Nutrition", icon: "◑", colorToken: "gold", goals: [
            .init(title: "Drink 8 glasses of water daily", duration: "Daily habit", level: "Easy"),
            .init(title: "No added sugar for 30 days", duration: "30 days", level: "Hard"),
            .init(title: "Cook at home at least 5 nights a week", duration: "Weekly", level: "Medium"),
            .init(title: "Eat a vegetable with every meal", duration: "Daily habit", level: "Easy"),
        ]),
        .init(name: "Sleep", icon: "☽", colorToken: "purple", goals: [
            .init(title: "In bed by 10:30 pm every night", duration: "Daily habit", level: "Medium"),
            .init(title: "No screens 30 minutes before sleep", duration: "Daily habit", level: "Medium"),
            .init(title: "Same wake time every day including weekends", duration: "Daily habit", level: "Hard"),
        ]),
        .init(name: "Career & Learning", icon: "△", colorToken: "gold", goals: [
            .init(title: "Read 20 pages every night before sleep", duration: "Daily habit", level: "Easy"),
            .init(title: "Finish one book this month", duration: "Monthly", level: "Medium"),
            .init(title: "Learn one new word daily", duration: "Daily habit", level: "Easy"),
            .init(title: "No social media before noon", duration: "Daily habit", level: "Medium"),
        ]),
        .init(name: "Relationships", icon: "◈", colorToken: "terra", goals: [
            .init(title: "Call a friend or family member once a week", duration: "Weekly", level: "Easy"),
            .init(title: "Put the phone away at dinner every night", duration: "Daily habit", level: "Easy"),
            .init(title: "Send a genuine compliment once a day", duration: "Daily habit", level: "Easy"),
            .init(title: "Plan one meaningful outing this month", duration: "Monthly", level: "Medium"),
        ]),
        .init(name: "Creativity", icon: "◐", colorToken: "sage", goals: [
            .init(title: "Write 300 words every day", duration: "Daily habit", level: "Medium"),
            .init(title: "Sketch something every evening", duration: "Daily habit", level: "Easy"),
            .init(title: "Finish one project you've been putting off", duration: "One-time", level: "Medium"),
            .init(title: "Learn one chord or one new note every day", duration: "Daily habit", level: "Easy"),
        ]),
        .init(name: "Finance", icon: "◉", colorToken: "gold", goals: [
            .init(title: "Log every purchase the day it happens", duration: "Daily habit", level: "Easy"),
            .init(title: "No impulse buys — 48-hour wait rule", duration: "Daily habit", level: "Medium"),
            .init(title: "Save $100 per week automatically", duration: "Weekly", level: "Medium"),
            .init(title: "Pack lunch instead of eating out", duration: "Daily habit", level: "Easy"),
        ]),
        .init(name: "Sobriety & Recovery", icon: "◎", colorToken: "sage", goals: [
            .init(title: "30 days alcohol-free", duration: "30 days", level: "Hard"),
            .init(title: "Replace the craving with a walk", duration: "Daily habit", level: "Medium"),
            .init(title: "Call your accountability partner weekly", duration: "Weekly", level: "Easy"),
        ]),
        .init(name: "Productivity", icon: "△", colorToken: "terra", goals: [
            .init(title: "Plan tomorrow's top 3 tasks each evening", duration: "Daily habit", level: "Easy"),
            .init(title: "Single-task — one thing at a time", duration: "Daily habit", level: "Medium"),
            .init(title: "Inbox zero every Friday", duration: "Weekly", level: "Medium"),
        ]),
        .init(name: "Gratitude", icon: "♡", colorToken: "terra", goals: [
            .init(title: "Send one thank-you message per day", duration: "Daily habit", level: "Easy"),
            .init(title: "End each day listing one win", duration: "Daily habit", level: "Easy"),
            .init(title: "Tell someone you appreciate them weekly", duration: "Weekly", level: "Easy"),
        ]),
    ]
}
