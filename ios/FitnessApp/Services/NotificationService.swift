import Foundation
import UserNotifications

/// Schedules local water-reminder notifications. No server, no push — all local.
enum NotificationService {

    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Schedule `count` reminders evenly spread between startHour and endHour, daily.
    /// Cancels any previously scheduled water reminders first.
    static func scheduleWaterReminders(count: Int, startHour: Int = 9, endHour: Int = 21) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: pendingIds(max: 12))

        guard count > 0, endHour > startHour else { return }
        guard await requestAuthorization() else { return }

        let span = endHour - startHour
        let step = max(1, span / count)
        var hour = startHour
        var i = 0
        while hour <= endHour && i < count {
            var date = DateComponents()
            date.hour = hour
            date.minute = 0

            let content = UNMutableNotificationContent()
            content.title = "Time to hydrate 💧"
            content.body = "Log a glass of water to stay on track."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            let req = UNNotificationRequest(identifier: "water.\(i)", content: content, trigger: trigger)
            try? await center.add(req)

            hour += step
            i += 1
        }
    }

    static func cancelWaterReminders() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: pendingIds(max: 12))
    }

    private static func pendingIds(max: Int) -> [String] { (0..<max).map { "water.\($0)" } }
}
