import Foundation

struct MonthEndDividendCalendar {
    enum Kind {
        case lastCumDividendDate
        case exDividendDate

        var title: String { self == .lastCumDividendDate ? "権利付き最終日" : "権利落ち日" }
        var emoji: String { self == .lastCumDividendDate ? "💵" : "💸" }
    }

    let exDividendDate: Date
    let lastCumDividendDate: Date
    private let calendar: Calendar

    init?(monthContaining date: Date, in timeZone: TimeZone) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        // JPX introduced T+2 for trades on and after July 16, 2019.
        guard let firstSupportedMonth = calendar.date(from: DateComponents(year: 2019, month: 7, day: 1)),
              date >= firstSupportedMonth,
              let month = calendar.dateInterval(of: .month, for: date),
              let lastSettlementDate = Self.previousTradingDay(before: month.end, in: calendar),
              let exDate = Self.previousTradingDay(before: lastSettlementDate, in: calendar),
              let lastCumDate = Self.previousTradingDay(before: exDate, in: calendar) else { return nil }

        self.calendar = calendar
        exDividendDate = exDate
        lastCumDividendDate = lastCumDate
    }

    func kind(on date: Date?) -> Kind? {
        guard let date else { return nil }
        if calendar.isDate(date, inSameDayAs: lastCumDividendDate) { return .lastCumDividendDate }
        if calendar.isDate(date, inSameDayAs: exDividendDate) { return .exDividendDate }
        return nil
    }

    private static func previousTradingDay(before date: Date, in calendar: Calendar) -> Date? {
        var date = date
        while let previous = calendar.date(byAdding: .day, value: -1, to: date) {
            if isTradingDay(previous, in: calendar) { return previous }
            date = previous
        }
        return nil
    }

    private static func isTradingDay(_ date: Date, in calendar: Calendar) -> Bool {
        let day = calendar.component(.day, from: date)
        let weekday = calendar.component(.weekday, from: date)
        guard weekday != 1 && weekday != 7 else { return false }

        // Only month-end settlement days are visited. Under current rules the
        // closures in that window are year-end and Showa Day or its substitute.
        switch calendar.component(.month, from: date) {
        case 4: return day != 29 && !(day == 30 && weekday == 2)
        case 12: return day != 31
        default: return true
        }
    }
}
