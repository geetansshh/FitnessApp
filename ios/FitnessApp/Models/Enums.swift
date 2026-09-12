import Foundation

/// Biological sex used by the Mifflin-St Jeor equation. Raw values match the Go API.
enum Sex: String, CaseIterable, Codable, Identifiable {
    case male, female
    var id: String { rawValue }
    var label: String { self == .male ? "Male" : "Female" }
}

/// Activity multiplier applied to BMR to get TDEE.
enum ActivityLevel: String, CaseIterable, Codable, Identifiable {
    case sedentary, light, moderate, active, veryActive

    var id: String { rawValue }
    var factor: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .veryActive: return 1.9
        }
    }
    var label: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .light: return "Lightly active"
        case .moderate: return "Moderately active"
        case .active: return "Active"
        case .veryActive: return "Very active"
        }
    }
    var detail: String {
        switch self {
        case .sedentary: return "Little or no exercise"
        case .light: return "1–3 workouts / week"
        case .moderate: return "3–5 workouts / week"
        case .active: return "6–7 workouts / week"
        case .veryActive: return "Hard training or physical job"
        }
    }
}

/// Direction of the calorie goal. Adjusts the daily target off TDEE.
enum GoalType: String, CaseIterable, Codable, Identifiable {
    case lose, maintain, gain
    var id: String { rawValue }
    /// kcal/day added to TDEE.
    var calorieAdjustment: Double {
        switch self {
        case .lose: return -500
        case .maintain: return 0
        case .gain: return 300
        }
    }
    var label: String {
        switch self {
        case .lose: return "Lose weight"
        case .maintain: return "Maintain"
        case .gain: return "Gain weight"
        }
    }
}

/// Which meal a food entry belongs to (feature #15: meal grouping).
enum MealType: String, CaseIterable, Codable, Identifiable {
    case breakfast, lunch, dinner, snack
    var id: String { rawValue }
    var label: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "takeoutbag.and.cup.and.straw.fill"
        }
    }
    /// Ordering for grouped display.
    var sortRank: Int {
        switch self {
        case .breakfast: return 0
        case .lunch: return 1
        case .dinner: return 2
        case .snack: return 3
        }
    }

    /// Best-guess meal from the current time of day, used as the default for new entries.
    static func suggested(now: Date = Date()) -> MealType {
        switch Calendar.current.component(.hour, from: now) {
        case 4..<11: return .breakfast
        case 11..<16: return .lunch
        case 16..<22: return .dinner
        default: return .snack
        }
    }
}

/// Display/entry unit system. Storage is always metric; this only affects UI.
enum UnitSystem: String, CaseIterable, Codable, Identifiable {
    case metric, imperial
    var id: String { rawValue }
    var label: String { self == .metric ? "Metric (kg, cm, ml)" : "Imperial (lb, ft/in, oz)" }
    var weightUnit: String { self == .metric ? "kg" : "lb" }
    var volumeUnit: String { self == .metric ? "ml" : "oz" }
}
