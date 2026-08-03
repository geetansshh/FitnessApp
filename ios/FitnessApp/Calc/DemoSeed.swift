#if DEBUG
import Foundation
import SwiftData

/// DEBUG-only demo data, triggered by the `-seedDemo` launch argument.
/// Used to visually verify screens without hand-entering data. Never ships in Release.
enum DemoSeed {
    static func run(_ ctx: ModelContext) {
        // Only seed an empty store.
        let existing = try? ctx.fetch(FetchDescriptor<UserProfile>())
        guard (existing?.isEmpty ?? true) else { return }

        let profile = UserProfile(name: "Geetansh", age: 26, sex: .male,
                                  heightCm: 178, weightKg: 82, goalWeightKg: 75,
                                  activity: .moderate, goal: .lose, waterGoalMl: 2500)
        ctx.insert(profile)

        let cal = Calendar.current
        func dayKey(_ back: Int) -> String {
            DayKey.key(for: cal.date(byAdding: .day, value: -back, to: Date())!)
        }

        // Today's food across meals (feature #15).
        let today = dayKey(0)
        ctx.insert(FoodEntry(day: today, name: "Oats & eggs", calories: 420, protein: 28, carbs: 44, fats: 14, meal: .breakfast))
        ctx.insert(FoodEntry(day: today, name: "Chicken rice bowl", calories: 640, protein: 52, carbs: 70, fats: 16, meal: .lunch))
        ctx.insert(FoodEntry(day: today, name: "Protein shake", calories: 180, protein: 25, carbs: 12, fats: 3, meal: .snack))

        // Prior days -> streak (#6) + calorie history (#7).
        for back in 1...6 {
            ctx.insert(FoodEntry(day: dayKey(back), name: "Meals", calories: 1900 + back * 40,
                                 protein: 130, carbs: 190, fats: 60, meal: .dinner))
        }

        // Water today.
        for _ in 0..<6 { ctx.insert(WaterEntry(day: today, amountMl: 250)) }

        // Weight trend (#weight chart) + ETA (#9).
        let weights: [(Int, Double)] = [(20, 85.0), (13, 84.1), (7, 83.2), (2, 82.4), (0, 82.0)]
        for (back, kg) in weights { ctx.insert(WeightEntry(day: dayKey(back), weightKg: kg)) }

        try? ctx.save()
    }
}
#endif
