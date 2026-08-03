import Foundation
import SwiftUI

/// The day currently being viewed/logged across Dashboard, Food, and Water.
/// Shared via the environment so all three tabs stay in sync (feature #1).
@Observable
final class DaySelection {
    var date: Date = Calendar.current.startOfDay(for: Date())

    var dayKey: String { DayKey.key(for: date) }
    var isToday: Bool { Calendar.current.isDateInToday(date) }

    func shift(_ days: Int) {
        if let d = Calendar.current.date(byAdding: .day, value: days, to: date) {
            // Never let the user log into the future.
            let today = Calendar.current.startOfDay(for: Date())
            date = min(Calendar.current.startOfDay(for: d), today)
        }
    }

    func goToday() { date = Calendar.current.startOfDay(for: Date()) }

    var canGoForward: Bool { !isToday }

    /// Human label: "Today", "Yesterday", or a medium date.
    var label: String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }
}
