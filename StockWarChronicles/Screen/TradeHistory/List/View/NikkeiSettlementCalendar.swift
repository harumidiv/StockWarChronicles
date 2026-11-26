import Foundation

enum NikkeiSettlementCalendar {
    enum Kind {
        case monthly
        case major

        var title: String { self == .major ? "メジャーSQ" : "SQ" }
        var badge: String { self == .major ? "MSQ" : "SQ" }
    }

    static func kind(on date: Date, in timeZone: TimeZone) -> Kind? {
        // SQ is a Japanese market date. Match the same civil date in the displayed calendar.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day,
              (8...14).contains(day), year > 1989 || (year == 1989 && month >= 6) else { return nil }

        // Monthly Nikkei 225 option SQ falls on the second Friday or the preceding business day.
        // The holidays that can fall on that Friday are National Foundation Day and Mountain Day.
        guard let secondFriday = calendar.date(from: DateComponents(year: year, month: month, weekday: 6, weekdayOrdinal: 2)) else { return nil }
        let fridayDay = calendar.component(.day, from: secondFriday)
        let observesMountainDayOnAugust11 = year >= 2016 && year != 2020 && year != 2021
        let holiday = month == 2 || (month == 8 && observesMountainDayOnAugust11)
        let settlementDay = fridayDay == 11 && holiday ? 10 : fridayDay
        guard day == settlementDay else { return nil }

        return month.isMultiple(of: 3) ? .major : .monthly
    }
}
