import Foundation

// MARK: - VGQuote
// A single motivational quote with attribution.

struct VGQuote {
    let text: String
    let attribution: String

    var fullText: String { "\(text)\n— \(attribution)" }
    var displayText: String { text }
    var displayAttribution: String { "— \(attribution)" }
}

// MARK: - VGQuoteBank
// All quotes from the Global Motivational Bank, organized by psychological category.
// Quotes are used for daily motivational notifications and the home screen quote widget.

enum VGQuoteBank {

    // MARK: - Category 1: Action & Immediate Momentum
    static let action: [VGQuote] = [
        VGQuote(text: "You miss 100% of the shots you don't take.", attribution: "Wayne Gretzky"),
        VGQuote(text: "Do, or do not. There is no try.", attribution: "Yoda"),
        VGQuote(text: "The secret of getting ahead is getting started.", attribution: "Mark Twain"),
        VGQuote(text: "A year from now you may wish you had started today.", attribution: "Karen Lamb"),
        VGQuote(text: "Action is the foundational key to all success.", attribution: "Pablo Picasso"),
        VGQuote(text: "Don't put off until tomorrow what you can do today.", attribution: "Benjamin Franklin"),
        VGQuote(text: "Amateurs sit and wait for inspiration. The rest of us just get up and go to work.", attribution: "Stephen King"),
        VGQuote(text: "Whatever you do, do with all your might.", attribution: "Marcus Tullius Cicero"),
        VGQuote(text: "The way to get started is to quit talking and begin doing.", attribution: "Walt Disney"),
        VGQuote(text: "There's two buttons I never like to hit: panic and snooze.", attribution: "Ted Lasso"),
        VGQuote(text: "You only get one shot, do not miss your chance to blow. This opportunity comes once in a lifetime.", attribution: "Eminem"),
    ]

    // MARK: - Category 2: Resilience, Grit & The Long Game
    static let resilience: [VGQuote] = [
        VGQuote(text: "The greatest glory in living lies not in never falling, but in rising every time we fall.", attribution: "Nelson Mandela"),
        VGQuote(text: "It gets easier. Every day it gets a little easier. But you gotta do it every day. That's the hard part.", attribution: "BoJack Horseman"),
        VGQuote(text: "Fall seven times, stand up eight.", attribution: "Japanese Proverb"),
        VGQuote(text: "In the darkest times, hope is something you give yourself. That is the meaning of inner strength.", attribution: "Uncle Iroh"),
        VGQuote(text: "Success is stumbling from failure to failure with no loss of enthusiasm.", attribution: "Winston Churchill"),
        VGQuote(text: "Just keep swimming.", attribution: "Dory"),
        VGQuote(text: "The past can hurt. But you can either run from it, or learn from it.", attribution: "Rafiki"),
        VGQuote(text: "Failure is only the opportunity to begin again, this time more wisely.", attribution: "Uncle Iroh"),
        VGQuote(text: "A champion is defined not by their wins but by how they can recover when they fall.", attribution: "Serena Williams"),
        VGQuote(text: "I've failed over and over and over again in my life. And that is why I succeed.", attribution: "Michael Jordan"),
        VGQuote(text: "The harder the struggle, the more glorious the triumph.", attribution: "Swami Sivananda"),
        VGQuote(text: "I can do this all day.", attribution: "Captain America"),
        VGQuote(text: "The morning will come again, because no darkness or season can last forever.", attribution: "BTS"),
    ]

    // MARK: - Category 3: Perspective, Mindset & Focus
    static let mindset: [VGQuote] = [
        VGQuote(text: "Life moves pretty fast. If you don't stop and look around once in a while, you could miss it.", attribution: "Ferris Bueller"),
        VGQuote(text: "Carpe diem. Seize the day, boys. Make your lives extraordinary.", attribution: "John Keating"),
        VGQuote(text: "It's not who I am underneath, but what I do that defines me.", attribution: "Batman"),
        VGQuote(text: "Small steps, taken daily, build the life you've been dreaming of.", attribution: "Vitamin G"),
        VGQuote(text: "What you focus on grows. What you think about expands.", attribution: "Wayne Dyer"),
        VGQuote(text: "Your mind is a garden. Your thoughts are the seeds. You can grow flowers or weeds.", attribution: "Unknown"),
        VGQuote(text: "The only way to do great work is to love what you do.", attribution: "Steve Jobs"),
        VGQuote(text: "Comparison is the thief of joy.", attribution: "Theodore Roosevelt"),
        VGQuote(text: "Progress, not perfection.", attribution: "Vitamin G"),
        VGQuote(text: "What you do today can improve all of your tomorrows.", attribution: "Ralph Marston"),
    ]

    // MARK: - Category 4: Self-Worth, Love & Intrinsic Value
    static let selfWorth: [VGQuote] = [
        VGQuote(text: "Stop acting so small. You are the universe in ecstatic motion.", attribution: "Rumi"),
        VGQuote(text: "Nobody built like you, you designed yourself.", attribution: "Jay-Z"),
        VGQuote(text: "Don't let anyone ever make you feel like you don't deserve what you want.", attribution: "Heath Ledger"),
        VGQuote(text: "I am building a future.", attribution: "Daily Affirmation"),
        VGQuote(text: "I am worthy of love just for being who I am.", attribution: "Daily Affirmation"),
        VGQuote(text: "You are enough, and you don't need to change.", attribution: "Daily Affirmation"),
        VGQuote(text: "You have light and peace inside of you. If you let it out, you can change the world around you.", attribution: "Uncle Iroh"),
        VGQuote(text: "My self-worth is not determined by my accomplishments.", attribution: "Daily Affirmation"),
        VGQuote(text: "No matter where life takes me, find me with a smile.", attribution: "Mac Miller"),
        VGQuote(text: "If today I'm here, it's because I never, never stopped believing in me.", attribution: "Bad Bunny"),
        VGQuote(text: "Everything you could possibly ever want, have, or need is right here inside of you.", attribution: "Kristin McGee"),
    ]

    // MARK: - Category 5: Excellence & Professional Mastery
    static let excellence: [VGQuote] = [
        VGQuote(text: "Every second counts.", attribution: "The Bear"),
        VGQuote(text: "Just try to do a little better than the day before. A modicum of effort. It compounds.", attribution: "The Bear"),
        VGQuote(text: "I am confident because I put in the work.", attribution: "Simone Biles"),
        VGQuote(text: "Failure doesn't exist. I always grew from all my experiences.", attribution: "Kobe Bryant"),
        VGQuote(text: "Excellence is not an act, but a habit.", attribution: "Aristotle"),
        VGQuote(text: "Success is the sum of small efforts, repeated day in and day out.", attribution: "Robert Collier"),
        VGQuote(text: "Every day is a Kaizen day. Never stop improving.", attribution: "Masaaki Imai"),
        VGQuote(text: "We cannot become what we want to be by remaining what we are.", attribution: "Max DePree"),
        VGQuote(text: "Discipline is the bridge between goals and accomplishment.", attribution: "Jim Rohn"),
    ]

    // MARK: - All quotes combined
    static let all: [VGQuote] = action + resilience + mindset + selfWorth + excellence

    // MARK: - Daily quote selection
    // Returns the same quote for a given calendar day, cycling through all quotes.
    static func todaysQuote() -> VGQuote {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % all.count
        return all[index]
    }

    // Returns a random quote — for variety in notifications.
    static func randomQuote() -> VGQuote {
        all.randomElement() ?? all[0]
    }

    // Returns a quote by category index (0–4), useful for notification variety.
    static func quote(forCategory categoryIndex: Int) -> VGQuote {
        let categories: [[VGQuote]] = [action, resilience, mindset, selfWorth, excellence]
        let safe = categoryIndex % categories.count
        return categories[safe].randomElement() ?? categories[safe][0]
    }
}
