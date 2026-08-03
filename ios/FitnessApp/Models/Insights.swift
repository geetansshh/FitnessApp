import Foundation

/// Derived motivational stats: logging streak (#6) and goal ETA (#9).
enum Insights {

    /// Current consecutive-day logging streak, counting back from today.
    /// A day "counts" if it has at least one food entry.
    static func streak(foodDays: Set<String>, today: Date = Date()) -> Int {
        let cal = Calendar.current
        var day = cal.startOfDay(for: today)
        var count = 0
        // Allow the streak to still be "alive" if today isn't logged yet but yesterday was.
        if !foodDays.contains(DayKey.key(for: day)) {
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day
        }
        while foodDays.contains(DayKey.key(for: day)) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    /// Estimated weeks to reach goal weight from the planned daily calorie deficit/surplus.
    /// Uses ~7700 kcal per kg of body mass. Returns nil for maintain or already-reached goals.
    static func weeksToGoal(currentKg: Double, goalKg: Double, tdee: Int, calorieTarget: Int) -> Int? {
        let kcalPerKg = 7700.0
        let dailyDelta = Double(tdee - calorieTarget)   // + = deficit (losing), - = surplus (gaining)
        guard abs(dailyDelta) > 1 else { return nil }

        let kgToChange = currentKg - goalKg              // + = need to lose
        // Direction must match: losing needs a deficit, gaining needs a surplus.
        guard kgToChange * dailyDelta > 0 else { return nil }

        let days = abs(kgToChange) * kcalPerKg / abs(dailyDelta)
        let weeks = Int((days / 7).rounded())
        return max(weeks, 1)
    }
}

#if DEBUG
extension Insights {
    /// ponytail: one runnable check for the streak/ETA math.
    static func selfCheck() {
        let days: Set<String> = [
            DayKey.key(for: Date()),
            DayKey.key(for: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
            DayKey.key(for: Calendar.current.date(byAdding: .day, value: -2, to: Date())!),
        ]
        assert(streak(foodDays: days) == 3, "expected streak 3")
        // 80kg -> 75kg, 500 kcal/day deficit: 5*7700/500 = 77 days ≈ 11 weeks
        assert(weeksToGoal(currentKg: 80, goalKg: 75, tdee: 2500, calorieTarget: 2000) == 11,
               "expected 11 weeks")
        assert(weeksToGoal(currentKg: 80, goalKg: 75, tdee: 2000, calorieTarget: 2000) == nil,
               "maintain -> nil")
    }
}
#endif
