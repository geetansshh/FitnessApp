import Foundation

/// Aggregated view of one day. Built from the day's entries + the profile.
/// Pure value type so it's trivially testable and keeps views thin (pragmatic MVVM).
struct DailySummary {
    var calorieTarget: Int
    var caloriesConsumed: Int
    var protein: Double
    var carbs: Double
    var fats: Double
    var proteinTarget: Int
    var carbsTarget: Int
    var fatsTarget: Int
    var waterMl: Int
    var waterGoalMl: Int

    var caloriesRemaining: Int { calorieTarget - caloriesConsumed }
    var calorieProgress: Double { calorieTarget > 0 ? min(Double(caloriesConsumed) / Double(calorieTarget), 1) : 0 }
    var waterProgress: Double { waterGoalMl > 0 ? min(Double(waterMl) / Double(waterGoalMl), 1) : 0 }

    static func build(profile: UserProfile, foods: [FoodEntry], waters: [WaterEntry]) -> DailySummary {
        DailySummary(
            calorieTarget: profile.calorieTarget,
            caloriesConsumed: foods.reduce(0) { $0 + $1.calories },
            protein: foods.reduce(0) { $0 + $1.protein },
            carbs: foods.reduce(0) { $0 + $1.carbs },
            fats: foods.reduce(0) { $0 + $1.fats },
            proteinTarget: profile.proteinTarget,
            carbsTarget: profile.carbsTarget,
            fatsTarget: profile.fatsTarget,
            waterMl: waters.reduce(0) { $0 + $1.amountMl },
            waterGoalMl: profile.waterGoalMl
        )
    }
}
