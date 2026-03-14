import Foundation
import SwiftData

@Model
final class DayMemo {
    @Attribute(.unique) var id: UUID
    var normalizedDate: Date
    var text: String

    init(id: UUID = UUID(), date: Date, text: String) {
        self.id = id
        self.normalizedDate = DayMemo.normalize(date)
        self.text = text
    }

    static func normalize(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
}
