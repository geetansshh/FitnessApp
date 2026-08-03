import Foundation

/// Mifflin-St Jeor calorie & macro planner.
/// This mirrors the Go `internal/calc` package byte-for-byte so offline (local) results
/// match the backend. Keep both in sync if you change a constant.
enum CalorieCalculator {

    struct Plan: Equatable {
        var bmr: Int
        var tdee: Int
        var calorieTarget: Int
        var protein: Int
        var carbs: Int
        var fats: Int
    }

    static func bmr(age: Int, sex: Sex, heightCm: Double, weightKg: Double) -> Double {
        let base = 10 * weightKg + 6.25 * heightCm - 5 * Double(age)
        return sex == .male ? base + 5 : base - 161
    }

    static func plan(age: Int, sex: Sex, heightCm: Double, weightKg: Double,
                     activity: ActivityLevel, goal: GoalType) -> Plan {
        let bmrValue = bmr(age: age, sex: sex, heightCm: heightCm, weightKg: weightKg)
        let tdee = bmrValue * activity.factor
        let floor = sex == .male ? 1500.0 : 1200.0
        let target = max(tdee + goal.calorieAdjustment, floor)

        // Macro split: 30% protein, 40% carbs, 30% fats.
        let protein = target * 0.30 / 4.0
        let carbs = target * 0.40 / 4.0
        let fats = target * 0.30 / 9.0

        return Plan(
            bmr: Int(bmrValue.rounded()),
            tdee: Int(tdee.rounded()),
            calorieTarget: Int(target.rounded()),
            protein: Int(protein.rounded()),
            carbs: Int(carbs.rounded()),
            fats: Int(fats.rounded())
        )
    }

    /// ponytail: one runnable check — asserts a worked example so a formula change fails loudly.
    /// Called from FitnessAppApp init in DEBUG only.
    static func selfCheck() {
        // male, 30y, 180cm, 80kg, moderate, lose:
        // BMR = 10*80 + 6.25*180 - 5*30 + 5 = 800 + 1125 - 150 + 5 = 1780
        // TDEE = 1780 * 1.55 = 2759 ; target = 2759 - 500 = 2259
        let p = plan(age: 30, sex: .male, heightCm: 180, weightKg: 80,
                     activity: .moderate, goal: .lose)
        assert(p.bmr == 1780, "BMR expected 1780, got \(p.bmr)")
        assert(p.tdee == 2759, "TDEE expected 2759, got \(p.tdee)")
        assert(p.calorieTarget == 2259, "target expected 2259, got \(p.calorieTarget)")
        // protein = 2259*0.3/4 = 169.4 -> 169
        assert(p.protein == 169, "protein expected 169, got \(p.protein)")

        // female floor case: tiny stats must clamp to 1200
        let f = plan(age: 25, sex: .female, heightCm: 150, weightKg: 45,
                     activity: .sedentary, goal: .lose)
        assert(f.calorieTarget == 1200, "female floor expected 1200, got \(f.calorieTarget)")
    }
}
