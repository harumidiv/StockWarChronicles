import Foundation
import SwiftData

@Model
final class DayMemo {
    @Attribute(.unique) var id: UUID
    var normalizedDate: Date
    var dateKey: String
    var text: String

    init(id: UUID = UUID(), date: Date, text: String) {
        self.id = id
        self.normalizedDate = DayMemo.normalize(date)
        self.dateKey = DayMemo.key(for: date)
        self.text = text
    }

    static func normalize(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    static func key(for date: Date) -> String {
        let cal = Calendar.current
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)
        return String(format: "%04d-%02d-%02d", y, m, d)
    }
}
