import Foundation

/// Pushes all local data to the backend as a one-shot backup. Push-only, and
/// idempotent: entries carry their local id, so the server upserts rather than
/// duplicating when you back up again.
enum SyncService {
    static func backup(profile: UserProfile?, foods: [FoodEntry], waters: [WaterEntry],
                       weights: [WeightEntry], client: APIClient) async throws {
        if let p = profile {
            try await client.putProfile(.init(
                name: p.name, age: p.age, sex: p.sexRaw,
                heightCm: p.heightCm, weightKg: p.weightKg, goalWeightKg: p.goalWeightKg,
                activityLevel: p.activityRaw, goalType: p.goalRaw,
                calorieTarget: p.calorieTarget, proteinTarget: p.proteinTarget,
                carbsTarget: p.carbsTarget, fatsTarget: p.fatsTarget, waterGoalMl: p.waterGoalMl))
        }
        for f in foods {
            try await client.postFood(.init(id: f.id, date: f.day, name: f.name, calories: f.calories,
                                            protein: f.protein, carbs: f.carbs, fats: f.fats))
        }
        for w in waters { try await client.postWater(.init(id: w.id, date: w.day, amountMl: w.amountMl)) }
        for w in weights { try await client.postWeight(.init(id: w.id, date: w.day, weightKg: w.weightKg)) }
    }
}
