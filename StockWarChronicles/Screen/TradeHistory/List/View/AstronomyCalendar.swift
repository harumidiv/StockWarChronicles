import Foundation

struct AstronomyCalendar: Decodable {
    struct MoonPhase: Decodable {
        enum Kind: String, Decodable {
            case newMoon
            case fullMoon

            var title: String { self == .newMoon ? "新月" : "満月" }
            var emoji: String { self == .newMoon ? "🌑" : "🌕" }
        }

        let kind: Kind
        let date: Date
    }

    struct Retrograde: Decodable {
        let start: Date
        let end: Date

        func title(on day: DateInterval) -> String {
            if start >= day.start { return "水星逆行の開始" }
            if end < day.end { return "水星逆行の終了" }
            return "水星逆行中"
        }
    }

    struct Day {
        let interval: DateInterval
        let moonPhase: MoonPhase?
        let retrograde: Retrograde?

        var hasEvents: Bool { moonPhase != nil || retrograde != nil }
    }

    let moonPhases: [MoonPhase]
    let mercuryRetrogrades: [Retrograde]

    static let bundled: Self = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let url = Bundle.main.url(forResource: "AstronomyEvents", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let events = try? decoder.decode(Self.self, from: data) else {
            return Self(moonPhases: [], mercuryRetrogrades: [])
        }
        return events
    }()

    func day(
        for date: Date?,
        in calendar: Calendar,
        showsNewMoon: Bool,
        showsFullMoon: Bool,
        showsMercuryRetrograde: Bool
    ) -> Day? {
        guard showsNewMoon || showsFullMoon || showsMercuryRetrograde,
              let date, let interval = calendar.dateInterval(of: .day, for: date) else { return nil }

        let moonPhase = (showsNewMoon || showsFullMoon) ? moonPhases.first {
            $0.date >= interval.start && $0.date < interval.end
        }.flatMap { phase in
            (phase.kind == .newMoon ? showsNewMoon : showsFullMoon) ? phase : nil
        } : nil
        let retrograde = showsMercuryRetrograde ? mercuryRetrogrades.first {
            $0.start < interval.end && $0.end >= interval.start
        } : nil
        return Day(interval: interval, moonPhase: moonPhase, retrograde: retrograde)
    }
}
