import Foundation
import WidgetKit

/// Writes a tiny snapshot of *today's* numbers into the shared App Group so the
/// Home/Lock Screen widget can render without touching the app's database (#5).
enum WidgetBridge {
    static let suiteName = "group.com.geetansh.FitnessApp"

    // Keys are shared verbatim with the widget target (see FitnessAppWidget).
    enum Key {
        static let calorieTarget = "w.calorieTarget"
        static let caloriesConsumed = "w.caloriesConsumed"
        static let waterMl = "w.waterMl"
        static let waterGoalMl = "w.waterGoalMl"
        static let day = "w.day"
    }

    static func publish(_ summary: DailySummary, day: String) {
        guard let d = UserDefaults(suiteName: suiteName) else { return }
        d.set(summary.calorieTarget, forKey: Key.calorieTarget)
        d.set(summary.caloriesConsumed, forKey: Key.caloriesConsumed)
        d.set(summary.waterMl, forKey: Key.waterMl)
        d.set(summary.waterGoalMl, forKey: Key.waterGoalMl)
        d.set(day, forKey: Key.day)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
