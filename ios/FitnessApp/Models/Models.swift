import Foundation
import SwiftData

/// The single user profile. Body stats are stored in metric (kg / cm / ml).
/// Calorie & macro targets are derived by `CalorieCalculator` whenever stats change.
@Model
final class UserProfile {
    var name: String
    var age: Int
    var sexRaw: String
    var heightCm: Double
    var weightKg: Double
    var goalWeightKg: Double
    var startWeightKg: Double
    var activityRaw: String
    var goalRaw: String

    var calorieTarget: Int
    var proteinTarget: Int
    var carbsTarget: Int
    var fatsTarget: Int
    var waterGoalMl: Int

    var createdAt: Date

    init(name: String = "", age: Int = 30, sex: Sex = .male,
         heightCm: Double = 175, weightKg: Double = 75, goalWeightKg: Double = 70,
         activity: ActivityLevel = .moderate, goal: GoalType = .lose,
         waterGoalMl: Int = 2500) {
        self.name = name
        self.age = age
        self.sexRaw = sex.rawValue
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.goalWeightKg = goalWeightKg
        self.startWeightKg = weightKg
        self.activityRaw = activity.rawValue
        self.goalRaw = goal.rawValue
        self.calorieTarget = 0
        self.proteinTarget = 0
        self.carbsTarget = 0
        self.fatsTarget = 0
        self.waterGoalMl = waterGoalMl
        self.createdAt = Date()
        recomputeTargets()
    }

    var sex: Sex {
        get { Sex(rawValue: sexRaw) ?? .male }
        set { sexRaw = newValue.rawValue }
    }
    var activity: ActivityLevel {
        get { ActivityLevel(rawValue: activityRaw) ?? .moderate }
        set { activityRaw = newValue.rawValue }
    }
    var goal: GoalType {
        get { GoalType(rawValue: goalRaw) ?? .maintain }
        set { goalRaw = newValue.rawValue }
    }

    /// Recompute calorie + macro targets from current body stats. Call after any edit.
    func recomputeTargets() {
        let r = CalorieCalculator.plan(age: age, sex: sex, heightCm: heightCm,
                                       weightKg: weightKg, activity: activity, goal: goal)
        calorieTarget = r.calorieTarget
        proteinTarget = r.protein
        carbsTarget = r.carbs
        fatsTarget = r.fats
    }
}

/// A logged food/meal for a day. Macros in grams.
@Model
final class FoodEntry {
    var id: String
    var day: String          // YYYY-MM-DD, local day key
    var name: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fats: Double
    var mealRaw: String = MealType.snack.rawValue  // default = lightweight migration for old rows
    var createdAt: Date

    init(day: String, name: String, calories: Int, protein: Double, carbs: Double, fats: Double,
         meal: MealType = .snack) {
        self.id = UUID().uuidString
        self.day = day
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.mealRaw = meal.rawValue
        self.createdAt = Date()
    }

    var meal: MealType {
        get { MealType(rawValue: mealRaw) ?? .snack }
        set { mealRaw = newValue.rawValue }
    }
}

/// A water log entry, always stored in millilitres.
@Model
final class WaterEntry {
    var id: String
    var day: String
    var amountMl: Int
    var createdAt: Date

    init(day: String, amountMl: Int) {
        self.id = UUID().uuidString
        self.day = day
        self.amountMl = amountMl
        self.createdAt = Date()
    }
}

/// A body-weight measurement, stored in kg.
@Model
final class WeightEntry {
    var id: String
    var day: String
    var weightKg: Double
    var createdAt: Date

    init(day: String, weightKg: Double) {
        self.id = UUID().uuidString
        self.day = day
        self.weightKg = weightKg
        self.createdAt = Date()
    }
}
