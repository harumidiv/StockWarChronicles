import Foundation

enum CalendarEventCategory: Int, CaseIterable, Identifiable {
    case sq = 0
    case majorSQ = 4
    case lastCumDividend = 1
    case exDividend = 6
    case newMoon = 2
    case fullMoon = 5
    case mercuryRetrograde = 3

    var id: Self { self }
    var bit: Int { 1 << rawValue }

    var visibilityKey: String {
        switch self {
        case .sq: "historyCalendarShowsSQ"
        case .majorSQ: "historyCalendarShowsMajorSQ"
        case .lastCumDividend: "historyCalendarShowsMonthEndDividends"
        case .exDividend: "historyCalendarShowsExDividend"
        case .newMoon: "historyCalendarShowsMoonPhases"
        case .fullMoon: "historyCalendarShowsFullMoon"
        case .mercuryRetrograde: "historyCalendarShowsMercuryRetrograde"
        }
    }

    var title: String {
        switch self {
        case .sq: "SQ"
        case .majorSQ: "メジャーSQ"
        case .lastCumDividend: MonthEndDividendCalendar.Kind.lastCumDividendDate.title
        case .exDividend: MonthEndDividendCalendar.Kind.exDividendDate.title
        case .newMoon: "新月"
        case .fullMoon: "満月"
        case .mercuryRetrograde: "水星逆行"
        }
    }
}

enum CalendarNotificationEvent: String, CaseIterable, Identifiable {
    case sq, majorSQ, lastCumDividend, exDividend, newMoon, fullMoon, mercuryStart, mercuryEnd

    var id: Self { self }

    var category: CalendarEventCategory {
        switch self {
        case .sq: .sq
        case .majorSQ: .majorSQ
        case .lastCumDividend: .lastCumDividend
        case .exDividend: .exDividend
        case .newMoon: .newMoon
        case .fullMoon: .fullMoon
        case .mercuryStart, .mercuryEnd: .mercuryRetrograde
        }
    }

    var title: String {
        switch self {
        case .sq: NikkeiSettlementCalendar.Kind.monthly.title
        case .majorSQ: NikkeiSettlementCalendar.Kind.major.title
        case .lastCumDividend: MonthEndDividendCalendar.Kind.lastCumDividendDate.title
        case .exDividend: MonthEndDividendCalendar.Kind.exDividendDate.title
        case .newMoon: AstronomyCalendar.MoonPhase.Kind.newMoon.title
        case .fullMoon: AstronomyCalendar.MoonPhase.Kind.fullMoon.title
        case .mercuryStart: "水星逆行の開始"
        case .mercuryEnd: "水星逆行の終了"
        }
    }

    var notificationTitle: String {
        switch self {
        case .sq, .majorSQ: "日経225 " + title
        case .lastCumDividend: MonthEndDividendCalendar.Kind.lastCumDividendDate.emoji + " " + title + "（月末基準）"
        case .exDividend: MonthEndDividendCalendar.Kind.exDividendDate.emoji + " " + title + "（月末基準）"
        case .newMoon: AstronomyCalendar.MoonPhase.Kind.newMoon.emoji + " " + title
        case .fullMoon: AstronomyCalendar.MoonPhase.Kind.fullMoon.emoji + " " + title
        case .mercuryStart, .mercuryEnd: title
        }
    }
}

struct CalendarNotificationTiming: Codable, Equatable, Identifiable {
    static let selectableDaysBefore = -1...30
    static let defaultTime = 8 * 60
    static let standard = Self()

    var id = UUID()
    var minutes = defaultTime
    var daysBefore = 0

    var normalized: Self {
        let days = min(max(daysBefore, Self.selectableDaysBefore.lowerBound), Self.selectableDaysBefore.upperBound)
        return Self(id: id, minutes: min(max(minutes, 0), 1_439), daysBefore: days)
    }

    var label: String {
        let time = String(format: "%02d:%02d", minutes / 60, minutes % 60)
        return Self.dayLabel(for: daysBefore) + " " + time
    }

    func matchesTime(of other: Self) -> Bool {
        minutes == other.minutes && daysBefore == other.daysBefore
    }

    static func dayLabel(for daysBefore: Int) -> String {
        switch daysBefore {
        case -1: "翌日"
        case 0: "当日"
        case 1: "前日"
        default: "\(daysBefore)日前"
        }
    }
}

struct CalendarNotificationRule: Codable, Equatable {
    var isEnabled = false
    var timings = [CalendarNotificationTiming.standard]

    var normalized: Self {
        Self(isEnabled: isEnabled && !timings.isEmpty, timings: timings.map(\.normalized))
    }

    private enum CodingKeys: String, CodingKey {
        case isEnabled, timings, minutes, daysBefore
    }

    init(isEnabled: Bool = false, timings: [CalendarNotificationTiming] = [.standard]) {
        self.isEnabled = isEnabled
        self.timings = timings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        if let storedTimings = try container.decodeIfPresent([CalendarNotificationTiming].self, forKey: .timings) {
            timings = storedTimings
        } else {
            var timing = CalendarNotificationTiming.standard
            timing.minutes = try container.decode(Int.self, forKey: .minutes)
            timing.daysBefore = try container.decode(Int.self, forKey: .daysBefore)
            timings = [timing]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(timings, forKey: .timings)
    }
}

struct CalendarNotificationPreferences: Codable, Equatable {
    static let storageKey = "historyCalendarNotificationRules"
    private var rules: [String: CalendarNotificationRule] = [:]

    subscript(event: CalendarNotificationEvent) -> CalendarNotificationRule {
        get { rules[event.rawValue]?.normalized ?? CalendarNotificationRule() }
        set { rules[event.rawValue] = newValue.normalized }
    }

    var hasEnabledRules: Bool { CalendarNotificationEvent.allCases.contains { self[$0].isEnabled } }

    func encoded() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try? encoder.encode(self)
    }

    static func read(from defaults: UserDefaults = .standard, data: Data? = nil) -> Self {
        if let data = data ?? defaults.data(forKey: storageKey), let saved = try? JSONDecoder().decode(Self.self, from: data) {
            return saved
        }

        // Give each event the old category's settings until the user makes an individual change.
        let enabled = defaults.integer(forKey: "historyCalendarNotificationEvents")
        let timeKey = "historyCalendarNotificationMinutes"
        var timing = CalendarNotificationTiming.standard
        timing.minutes = defaults.object(forKey: timeKey) == nil ? CalendarNotificationTiming.defaultTime : defaults.integer(forKey: timeKey)
        timing.daysBefore = defaults.integer(forKey: "historyCalendarNotificationDayOffset")
        var migrated = Self()
        for event in CalendarNotificationEvent.allCases {
            let legacyBit: Int
            switch event {
            case .sq, .majorSQ: legacyBit = 1 << CalendarEventCategory.sq.rawValue
            case .lastCumDividend, .exDividend: legacyBit = 1 << CalendarEventCategory.lastCumDividend.rawValue
            case .newMoon, .fullMoon: legacyBit = 1 << 2
            case .mercuryStart, .mercuryEnd: legacyBit = 1 << CalendarEventCategory.mercuryRetrograde.rawValue
            }
            migrated[event] = CalendarNotificationRule(isEnabled: enabled & legacyBit != 0, timings: [timing])
        }
        return migrated
    }
}

enum CalendarNotificationPlan {
    static let identifierPrefix = "history-calendar."

    struct Reminder {
        let identifier: String
        let date: Date
        let title: String
        let body: String
    }

    private struct Occurrence: Hashable {
        let event: CalendarNotificationEvent
        let eventDay: Date
    }

    static func upcoming(
        for preferences: CalendarNotificationPreferences,
        now: Date,
        timeZone: TimeZone,
        astronomy: AstronomyCalendar = .bundled
    ) -> [Reminder] {
        let enabledEvents = CalendarNotificationEvent.allCases.filter { preferences[$0].isEnabled }
        let daysBefore = enabledEvents.flatMap { preferences[$0].timings.map(\.daysBefore) }
        guard let minDaysBefore = daysBefore.min(), let maxDaysBefore = daysBefore.max() else { return [] }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = calendar.startOfDay(for: now)
        guard let firstEventDay = calendar.date(byAdding: .day, value: minDaysBefore, to: today),
              let notificationEnd = calendar.date(byAdding: .year, value: 1, to: today),
              let eventEnd = calendar.date(byAdding: .day, value: maxDaysBefore, to: notificationEnd) else { return [] }

        var eventsByDelivery: [Date: Set<Occurrence>] = [:]
        func add(_ event: CalendarNotificationEvent, on date: Date) {
            let day = calendar.startOfDay(for: date)
            let rule = preferences[event]
            guard rule.isEnabled, day >= firstEventDay && day < eventEnd else { return }
            for timing in rule.timings {
                guard let notificationDay = calendar.date(byAdding: .day, value: -timing.daysBefore, to: day),
                      let delivery = calendar.date(bySettingHour: timing.minutes / 60, minute: timing.minutes % 60, second: 0, of: notificationDay),
                      calendar.isDate(delivery, inSameDayAs: notificationDay), delivery > now && delivery < notificationEnd else { continue }
                eventsByDelivery[delivery, default: []].insert(Occurrence(event: event, eventDay: day))
            }
        }

        let enabledCategories = Set(enabledEvents.map(\.category))
        if enabledCategories.contains(.newMoon) || enabledCategories.contains(.fullMoon) {
            for phase in astronomy.moonPhases {
                add(phase.kind == .newMoon ? .newMoon : .fullMoon, on: phase.date)
            }
        }
        if enabledCategories.contains(.mercuryRetrograde) {
            for period in astronomy.mercuryRetrogrades {
                add(.mercuryStart, on: period.start)
                add(.mercuryEnd, on: period.end)
            }
        }

        if (enabledCategories.contains(.sq) || enabledCategories.contains(.majorSQ) || enabledCategories.contains(.lastCumDividend) || enabledCategories.contains(.exDividend)),
           var month = calendar.dateInterval(of: .month, for: firstEventDay)?.start {
            while month < eventEnd {
                if enabledCategories.contains(.sq) || enabledCategories.contains(.majorSQ) {
                    for dayOffset in 7...13 {
                        guard let date = calendar.date(byAdding: .day, value: dayOffset, to: month),
                              let kind = NikkeiSettlementCalendar.kind(on: date, in: timeZone) else { continue }
                        add(kind == .major ? .majorSQ : .sq, on: date)
                    }
                }
                if enabledCategories.contains(.lastCumDividend) || enabledCategories.contains(.exDividend),
                   let dates = MonthEndDividendCalendar(monthContaining: month, in: timeZone) {
                    add(.lastCumDividend, on: dates.lastCumDividendDate)
                    add(.exDividend, on: dates.exDividendDate)
                }
                guard let next = calendar.date(byAdding: .month, value: 1, to: month) else { break }
                month = next
            }
        }

        let dateFormat = Date.FormatStyle(date: .omitted, time: .omitted, locale: Locale(identifier: "ja_JP"), calendar: calendar, timeZone: timeZone).month().day()
        return eventsByDelivery.sorted { $0.key < $1.key }.map { date, events in
            let ordered = events.sorted {
                if $0.eventDay == $1.eventDay { return $0.event.rawValue < $1.event.rawValue }
                return $0.eventDay < $1.eventDay
            }
            let eventKeys = ordered.map { "\($0.event.rawValue)-\(Int($0.eventDay.timeIntervalSince1970))" }
            let identifier = identifierPrefix + "v2.\(Int(date.timeIntervalSince1970))." + eventKeys.joined(separator: ".")
            return Reminder(
                identifier: identifier,
                date: date,
                title: "カレンダーの予定",
                body: ordered.map { "\($0.eventDay.formatted(dateFormat)) \($0.event.notificationTitle)" }.joined(separator: "\n")
            )
        }
    }
}
