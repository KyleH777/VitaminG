import Foundation

final class StreakFreezeService {

    private let defaults: UserDefaults
    private let keyLastFreezeDate = "vg.streakFreeze.lastFreezeDate"
    private let keyFrozenDates = "vg.streakFreeze.frozenDates"

    init(defaults: UserDefaults = UserDefaults(suiteName: "group.com.kyleharrington.VitaminG") ?? .standard) {
        self.defaults = defaults
    }

    /// Returns true if the user can freeze their streak relative to the given date.
    /// Uses ISO8601 calendar for weekOfYear comparison so the reset boundary is Monday
    /// (not a Gregorian calendar artifact). yearForWeekOfYear is used instead of .year
    /// to correctly handle the week 52 → week 1 year boundary.
    func canFreezeRelativeTo(_ date: Date) -> Bool {
        guard let lastDate = lastFreezeDate else { return true }
        let iso = Calendar(identifier: .iso8601)
        let lastWeek = iso.component(.weekOfYear, from: lastDate)
        let thisWeek = iso.component(.weekOfYear, from: date)
        let lastYear = iso.component(.yearForWeekOfYear, from: lastDate)
        let thisYear = iso.component(.yearForWeekOfYear, from: date)
        return lastWeek != thisWeek || lastYear != thisYear
    }

    /// Returns true if the user can freeze their streak this week (once per ISO8601 week).
    var canFreeze: Bool { canFreezeRelativeTo(.now) }

    var frozenDates: [Date] {
        let intervals = defaults.array(forKey: keyFrozenDates) as? [Double] ?? []
        return intervals.map { Date(timeIntervalSince1970: $0) }
    }

    func freeze(on date: Date = .now) {
        guard canFreezeRelativeTo(date) else { return }
        let cal = Calendar.current
        let day = cal.startOfDay(for: date)
        var intervals = defaults.array(forKey: keyFrozenDates) as? [Double] ?? []
        intervals.append(day.timeIntervalSince1970)
        defaults.set(intervals, forKey: keyFrozenDates)
        defaults.set(day.timeIntervalSince1970, forKey: keyLastFreezeDate)
    }

    private var lastFreezeDate: Date? {
        let interval = defaults.double(forKey: keyLastFreezeDate)
        guard interval > 0 else { return nil }
        return Date(timeIntervalSince1970: interval)
    }
}
