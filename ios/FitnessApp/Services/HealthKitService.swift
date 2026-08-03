import Foundation
import HealthKit

/// Two-way Apple Health sync for body weight, plus read-only steps / active energy (#3).
///
/// Requires the HealthKit capability (entitlement) — available on a **paid** Apple Developer
/// account. Without it, `isAvailable`/authorization simply return false and the app works as
/// normal; nothing crashes.
enum HealthKitService {
    static let store = HKHealthStore()

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private static let bodyMass = HKQuantityType(.bodyMass)
    private static let steps = HKQuantityType(.stepCount)
    private static let activeEnergy = HKQuantityType(.activeEnergyBurned)

    static func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        let read: Set = [bodyMass, steps, activeEnergy]
        let write: Set = [bodyMass]
        do {
            try await store.requestAuthorization(toShare: write, read: read)
            return true
        } catch {
            return false
        }
    }

    // MARK: Weight

    /// Most recent body-mass sample, in kg.
    static func latestWeightKg() async -> Double? {
        guard isAvailable else { return nil }
        return await withCheckedContinuation { cont in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let q = HKSampleQuery(sampleType: bodyMass, predicate: nil, limit: 1,
                                  sortDescriptors: [sort]) { _, samples, _ in
                let kg = (samples?.first as? HKQuantitySample)?
                    .quantity.doubleValue(for: .gramUnit(with: .kilo))
                cont.resume(returning: kg)
            }
            store.execute(q)
        }
    }

    static func saveWeight(kg: Double, date: Date) async {
        guard isAvailable else { return }
        let sample = HKQuantitySample(type: bodyMass,
                                      quantity: HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg),
                                      start: date, end: date)
        try? await store.save(sample)
    }

    // MARK: Read-only daily activity

    static func todayActiveEnergyKcal() async -> Double {
        await sumToday(activeEnergy, unit: .kilocalorie())
    }

    static func todaySteps() async -> Int {
        Int(await sumToday(steps, unit: .count()))
    }

    private static func sumToday(_ type: HKQuantityType, unit: HKUnit) async -> Double {
        guard isAvailable else { return 0 }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, stats, _ in
                cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(q)
        }
    }
}
