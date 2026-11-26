import Combine
import UIKit
import UserNotifications

@MainActor
final class CalendarNotificationScheduler: ObservableObject {
    static let shared = CalendarNotificationScheduler()

    @Published private(set) var hasSchedulingError = false

    private let center = UNUserNotificationCenter.current()
    private var isRefreshing = false
    private var needsRefresh = false

    private init() { }

    func refresh() async {
        needsRefresh = true
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        while needsRefresh {
            needsRefresh = false
            await reconcilePendingNotifications()
        }
    }

    private func reconcilePendingNotifications() async {
        let status = await center.notificationSettings().authorizationStatus
        let pending = await center.pendingNotificationRequests()
        let calendarIDs = Set(pending.map(\.identifier).filter { $0.hasPrefix(CalendarNotificationPlan.identifierPrefix) })
        let preferences = CalendarNotificationPreferences.read()

        let allowed = status == .authorized || status == .provisional || status == .ephemeral
        guard allowed && preferences.hasEnabledRules else {
            center.removePendingNotificationRequests(withIdentifiers: Array(calendarIDs))
            hasSchedulingError = false
            return
        }

        // Keep within the system's pending notification limit and leave other requests alone.
        let capacity = max(0, 64 - (pending.count - calendarIDs.count))
        let reminders = CalendarNotificationPlan.upcoming(for: preferences, now: Date(), timeZone: .current).prefix(capacity)
        let desiredIDs = Set(reminders.map(\.identifier))
        let obsoleteIDs = calendarIDs.subtracting(desiredIDs)
        center.removePendingNotificationRequests(withIdentifiers: Array(obsoleteIDs))

        var failed = capacity == 0
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!

        for reminder in reminders where !calendarIDs.contains(reminder.identifier) {
            if needsRefresh { return }
            guard reminder.date > Date() else { continue }
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default
            let components = utcCalendar.dateComponents(in: utcCalendar.timeZone, from: reminder.date)
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: DateComponents(
                    calendar: utcCalendar, timeZone: utcCalendar.timeZone,
                    year: components.year, month: components.month, day: components.day,
                    hour: components.hour, minute: components.minute, second: components.second
                ),
                repeats: false
            )
            do {
                try await center.add(UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger))
            } catch {
                failed = true
            }
        }
        hasSchedulingError = failed
    }
}

final class CalendarNotificationAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
