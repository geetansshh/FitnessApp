import Foundation
import SwiftData

/// Holds onboarding form state and derives a live calorie plan.
/// Inputs are captured in the user's chosen unit system and converted to metric on save.
@Observable
final class OnboardingViewModel {
    var name = ""
    var age = 30
    var sex: Sex = .male
    var activity: ActivityLevel = .moderate
    var goal: GoalType = .lose

    // Entered in display units (metric or imperial).
    var system: UnitSystem = .metric
    var heightCm = 175.0        // metric height
    var heightFeet = 5
    var heightInches = 9
    var weightValue = 75.0      // in display unit
    var goalWeightValue = 70.0  // in display unit
    var waterGoalMl = 2500      // daily water goal in ml

    var metricHeightCm: Double {
        guard system == .imperial else { return heightCm }
        let totalInches = Double(heightFeet) * 12 + Double(heightInches)
        return totalInches * 2.54
    }
    var metricWeightKg: Double { Units.kgFromDisplay(weightValue, system: system) }
    var metricGoalWeightKg: Double { Units.kgFromDisplay(goalWeightValue, system: system) }

    var plan: CalorieCalculator.Plan {
        CalorieCalculator.plan(age: age, sex: sex, heightCm: metricHeightCm,
                               weightKg: metricWeightKg, activity: activity, goal: goal)
    }

    var isValid: Bool {
        age >= 13 && age <= 100 &&
        metricHeightCm >= 100 && metricHeightCm <= 250 &&
        metricWeightKg >= 30 && metricWeightKg <= 400 &&
        metricGoalWeightKg >= 30 && metricGoalWeightKg <= 400
    }

    /// Persist the profile. Returns the inserted profile.
    @discardableResult
    func save(into context: ModelContext) -> UserProfile {
        let profile = UserProfile(
            name: name.trimmingCharacters(in: .whitespaces),
            age: age, sex: sex,
            heightCm: metricHeightCm, weightKg: metricWeightKg,
            goalWeightKg: metricGoalWeightKg,
            activity: activity, goal: goal,
            waterGoalMl: waterGoalMl)
        context.insert(profile)
        // Seed the weight history with the starting weight so charts have a first point.
        context.insert(WeightEntry(day: DayKey.today, weightKg: metricWeightKg))
        return profile
    }
}
