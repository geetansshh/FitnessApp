import Foundation
import SwiftData

/// Single place that records a weigh-in — called from both Today and Goals.
/// One entry per day: today's row is replaced rather than duplicated.
enum WeightLog {
    static func upsert(kg: Double, weights: [WeightEntry], profile: UserProfile,
                       context: ModelContext, healthKitEnabled: Bool) {
        let today = DayKey.today
        if let existing = weights.first(where: { $0.day == today }) {
            existing.weightKg = kg
        } else {
            context.insert(WeightEntry(day: today, weightKg: kg))
        }
        profile.weightKg = kg
        profile.recomputeTargets()
        if healthKitEnabled {
            Task { await HealthKitService.saveWeight(kg: kg, date: Date()) }
        }
        Haptics.success()
    }
}
