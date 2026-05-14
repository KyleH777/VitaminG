import Foundation

final class StreakFreezeService {

    private let defaults: UserDefaults
    private let keyLastFreezeDate = "vg.streakFreeze.lastFreezeDate"
    private let keyFrozenDates = "vg.streakFreeze.frozenDates"

    init(defaults: UserDefaults = UserDefaults(suiteName: "group.com.kyleharrington.VitaminG") ?? .standard) {
        self.defaults = defaults
    }

    var canFreeze: Bool {
        guard let lastDate = lastFreezeDate else { return true }
        let cal = Calendar.current
        return !cal.isDate(lastDate, equalTo: .now, toGranularity: .month)
    }

    var frozenDates: [Date] {
        let intervals = defaults.array(forKey: keyFrozenDates) as? [Double] ?? []
        return intervals.map { Date(timeIntervalSince1970: $0) }
    }

    func freeze(on date: Date = .now) {
        guard canFreeze else { return }
        let cal = Calendar.current
        let day = cal.startOfDay(for: date)
        var intervals = defaults.array(forKey: keyFrozenDates) as? [Double] ?? []
        intervals.append(day.timeIntervalSince1970)
        defaults.set(intervals, forKey: keyFrozenDates)
        defaults.set(date.timeIntervalSince1970, forKey: keyLastFreezeDate)
    }

    private var lastFreezeDate: Date? {
        let interval = defaults.double(forKey: keyLastFreezeDate)
        guard interval > 0 else { return nil }
        return Date(timeIntervalSince1970: interval)
    }
}
