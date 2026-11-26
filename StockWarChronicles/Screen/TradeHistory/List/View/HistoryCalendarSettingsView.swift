import SwiftUI
import UIKit
import UserNotifications

struct HistoryCalendarSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(CalendarEventCategory.sq.visibilityKey) private var showsSQ = true
    @AppStorage(CalendarEventCategory.dividends.visibilityKey) private var showsDividends = true
    @AppStorage(CalendarEventCategory.moonPhases.visibilityKey) private var showsMoonPhases = true
    @AppStorage(CalendarEventCategory.mercuryRetrograde.visibilityKey) private var showsMercuryRetrograde = true
    @AppStorage(CalendarNotificationPreferences.storageKey) private var notificationRules = Data()

    @ObservedObject private var scheduler = CalendarNotificationScheduler.shared
    @State private var authorizationStatus: UNAuthorizationStatus?
    @State private var isRequestingPermission = false
    @State private var hasPermissionError = false

    private var preferences: CalendarNotificationPreferences {
        CalendarNotificationPreferences.read(data: notificationRules)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("カレンダーに表示") {
                    ForEach(CalendarEventCategory.allCases) { category in
                        Toggle(category.title, isOn: visibility(for: category))
                    }
                }

                Section {
                    ForEach(CalendarNotificationEvent.allCases) { event in
                        NavigationLink {
                            CalendarNotificationRuleView(
                                event: event,
                                rule: notification(for: event),
                                isPermissionDenied: authorizationStatus == .denied,
                                isRequestingPermission: isRequestingPermission,
                                openSystemSettings: openSystemSettings
                            )
                        } label: {
                            LabeledContent(event.title, value: notificationSummary(for: preferences[event]))
                        }
                    }

                    if authorizationStatus == .denied {
                        Button("iOSの通知設定を開く", action: openSystemSettings)
                    } else if preferences.hasEnabledRules && authorizationStatus == .notDetermined && !isRequestingPermission {
                        Button("通知を許可する") {
                            Task { await requestPermissionIfNeeded() }
                        }
                        .disabled(isRequestingPermission)
                    }
                } header: {
                    Text("通知するイベント")
                } footer: {
                    if authorizationStatus == .denied {
                        Text("端末で通知がオフになっています。iOSの設定で通知を許可してください。")
                    } else if hasPermissionError {
                        Text("通知の許可を確認できませんでした。もう一度お試しください。")
                    }
                }

                if scheduler.hasSchedulingError {
                    Section {
                        Button("通知の予約をやり直す") {
                            Task { await scheduler.refresh() }
                        }
                    } footer: {
                        Text("一部の通知を予約できませんでした。")
                    }
                }
            }
            .navigationTitle("カレンダー設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
            .task { await updateAuthorizationStatus() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task { await updateAuthorizationStatus() }
                }
            }
        }
    }

    private func visibility(for category: CalendarEventCategory) -> Binding<Bool> {
        switch category {
        case .sq: $showsSQ
        case .dividends: $showsDividends
        case .moonPhases: $showsMoonPhases
        case .mercuryRetrograde: $showsMercuryRetrograde
        }
    }

    private func notification(for event: CalendarNotificationEvent) -> Binding<CalendarNotificationRule> {
        Binding(
            get: { preferences[event] },
            set: { rule in
                var updated = preferences
                let isNewlyEnabled = !updated[event].isEnabled && rule.isEnabled
                updated[event] = rule
                guard let data = updated.encoded() else { return }
                notificationRules = data
                Task {
                    if isNewlyEnabled {
                        await requestPermissionIfNeeded()
                    } else {
                        await scheduler.refresh()
                    }
                }
            }
        )
    }

    private func notificationSummary(for rule: CalendarNotificationRule) -> String {
        guard rule.isEnabled, let first = rule.timings.first else { return "オフ" }
        return rule.timings.count == 1 ? first.label : "\(rule.timings.count)件"
    }

    private func updateAuthorizationStatus() async {
        authorizationStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    private func requestPermissionIfNeeded() async {
        guard !isRequestingPermission else { return }
        isRequestingPermission = true
        defer { isRequestingPermission = false }

        await updateAuthorizationStatus()
        if authorizationStatus == .notDetermined && preferences.hasEnabledRules {
            do {
                _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                hasPermissionError = false
            } catch {
                hasPermissionError = true
            }
            await updateAuthorizationStatus()
        }
        await scheduler.refresh()
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            openURL(url)
        }
    }
}

private struct CalendarNotificationRuleView: View {
    let event: CalendarNotificationEvent
    @Binding var rule: CalendarNotificationRule
    let isPermissionDenied: Bool
    let isRequestingPermission: Bool
    let openSystemSettings: () -> Void
    @State private var editingTiming: CalendarNotificationTiming?

    var body: some View {
        Form {
            Section {
                Toggle("通知する", isOn: notificationEnabled)
                    .disabled(isRequestingPermission)
                if rule.isEnabled && isPermissionDenied {
                    Button("iOSの通知設定を開く", action: openSystemSettings)
                }
            }

            Section("通知のタイミング") {
                ForEach(rule.timings) { timing in
                    Button(timing.label) { editingTiming = timing }
                        .tint(.primary)
                        .swipeActions {
                            Button("削除", role: .destructive) { remove(timing) }
                        }
                }
                Button("通知を追加", systemImage: "plus") {
                    var timing = CalendarNotificationTiming()
                    let occupied = Set(rule.timings.filter { $0.daysBefore == timing.daysBefore }.map(\.minutes))
                    let defaultTime = timing.minutes
                    timing.minutes = (0..<24).lazy.map { (defaultTime + $0 * 60) % 1_440 }
                        .first { !occupied.contains($0) } ?? defaultTime
                    editingTiming = timing
                }
            }
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingTiming) { timing in
            let existing = rule.timings.contains { $0.id == timing.id }
            CalendarNotificationTimingEditor(
                timing: timing,
                isEditing: existing,
                otherTimings: rule.timings.filter { $0.id != timing.id },
                onSave: save,
                onDelete: { remove(timing) }
            )
        }
    }

    private var notificationEnabled: Binding<Bool> {
        Binding {
            rule.isEnabled
        } set: { enabled in
            var updated = rule
            updated.isEnabled = enabled
            if enabled && updated.timings.isEmpty {
                updated.timings = [.standard]
            }
            rule = updated
        }
    }

    private func save(_ timing: CalendarNotificationTiming) {
        if let index = rule.timings.firstIndex(where: { $0.id == timing.id }) {
            rule.timings[index] = timing
        } else {
            rule.timings.append(timing)
        }
    }

    private func remove(_ timing: CalendarNotificationTiming) {
        rule.timings.removeAll { $0.id == timing.id }
    }
}

private struct CalendarNotificationTimingEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var timing: CalendarNotificationTiming
    let isEditing: Bool
    let otherTimings: [CalendarNotificationTiming]
    let onSave: (CalendarNotificationTiming) -> Void
    let onDelete: () -> Void

    private var isDuplicate: Bool { otherTimings.contains { $0.matchesTime(of: timing) } }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("通知日", selection: $timing.daysBefore) {
                        ForEach(CalendarNotificationTiming.selectableDaysBefore, id: \.self) { daysBefore in
                            Text(CalendarNotificationTiming.dayLabel(for: daysBefore)).tag(daysBefore)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    DatePicker("時刻", selection: notificationTime, displayedComponents: .hourAndMinute)
                } footer: {
                    if isDuplicate {
                        Text("同じ日時の通知が登録されています。")
                    }
                }

                if isEditing {
                    Section {
                        Button("通知を削除", role: .destructive) {
                            onDelete()
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "通知を編集" : "通知を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(timing)
                        dismiss()
                    }
                    .disabled(isDuplicate)
                }
            }
        }
    }

    private var notificationTime: Binding<Date> {
        Binding {
            let calendar = Calendar.current
            let dayStart = calendar.startOfDay(for: .now)
            let time = DateComponents(hour: timing.minutes / 60, minute: timing.minutes % 60, second: 0)
            return calendar.nextDate(after: dayStart.addingTimeInterval(-1), matching: time, matchingPolicy: .strict) ?? dayStart
        } set: { date in
            let calendar = Calendar.current
            timing.minutes = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        }
    }
}
