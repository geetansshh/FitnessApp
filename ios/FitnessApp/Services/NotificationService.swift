import Foundation
import UserNotifications

/// Schedules local notifications: water reminders, and a heads-up before the
/// signing profile expires. No server, no push — all local.
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
            content.title = "Time to hydrate"
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

    // MARK: - Build expiry

    /// When this build stops launching. A free Apple ID signs for 7 days and the
    /// app then dies silently, so the date comes from the embedded profile itself
    /// rather than a guess about when it was installed.
    static var buildExpiry: Date? {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url) else { return nil }
        return expiryDate(inProfile: data)
    }

    /// The profile is CMS-signed, so the plist is carved out of the middle of it.
    static func expiryDate(inProfile data: Data) -> Date? {
        guard let text = String(data: data, encoding: .isoLatin1),
              let start = text.range(of: "<?xml"),
              let end = text.range(of: "</plist>"),
              let plist = String(text[start.lowerBound..<end.upperBound]).data(using: .isoLatin1),
              let dict = try? PropertyListSerialization.propertyList(from: plist, format: nil)
                as? [String: Any] else { return nil }
        return dict["ExpirationDate"] as? Date
    }

    /// Warn two days out, then again the day before, both at 10am local — enough
    /// runway to re-install before the build stops opening.
    static func scheduleBuildExpiryWarnings() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: expiryIds)
        guard let expiry = buildExpiry, await requestAuthorization() else { return }

        let day = DateFormatter()
        day.dateFormat = "d MMM"
        for (id, daysBefore) in zip(expiryIds, [2, 1]) {
            guard let fire = fireDate(daysBefore: daysBefore, before: expiry), fire > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = daysBefore == 2 ? "Build expires in 2 days ⏳" : "Build expires tomorrow ⏳"
            content.body = "Re-install it before \(day.string(from: expiry)) or the app stops opening."
            content.sound = .default

            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    /// 10am on the day `daysBefore` the expiry, so a 3am expiry doesn't buzz at 3am.
    static func fireDate(daysBefore: Int, before expiry: Date) -> Date? {
        let cal = Calendar.current
        guard let day = cal.date(byAdding: .day, value: -daysBefore, to: expiry) else { return nil }
        return cal.date(bySettingHour: 10, minute: 0, second: 0, of: day)
    }

    private static let expiryIds = ["build.expiry.2d", "build.expiry.1d"]
}
