import SwiftUI
import SwiftData
import Charts

/// Goals & progress: weight trend chart, add a weigh-in, edit body stats.
struct GoalsView: View {
    let profile: UserProfile
    @Environment(\.modelContext) private var context
    @AppStorage(SettingsKey.unitSystem) private var unitRaw = UnitSystem.metric.rawValue
    @AppStorage(SettingsKey.healthKitEnabled) private var healthKitEnabled = false
    @Query(sort: \WeightEntry.day) private var weights: [WeightEntry]
    @Query private var allFoods: [FoodEntry]
    @State private var showAddWeight = false
    @State private var weightInput = ""
    @State private var showEdit = false

    private var system: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .metric }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.gutter) {
                    WeightChartCard(profile: profile, weights: weights, system: system)

                    CalorieHistoryCard(profile: profile, foods: allFoods)

                    Button {
                        showAddWeight = true
                    } label: {
                        Label("Log weight", systemImage: "plus").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).tint(Theme.weight)

                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Goals")
            .toolbar {
                Button("Edit") { showEdit = true }
            }
            .logWeightAlert(isPresented: $showAddWeight, value: $weightInput, system: system) {
                upsertWeight(kg: $0)
            }
            .sheet(isPresented: $showEdit) {
                EditProfileSheet(profile: profile, system: system)
            }
        }
    }

    private func upsertWeight(kg: Double) {
        WeightLog.upsert(kg: kg, weights: weights, profile: profile,
                         context: context, healthKitEnabled: healthKitEnabled)
    }
}

struct WeightChartCard: View {
    let profile: UserProfile
    let weights: [WeightEntry]
    let system: UnitSystem

    /// Zoom to the data (plus the goal line) with a little padding — a 0-based
    /// axis flattens a few kg of change into a straight line.
    private var yDomain: ClosedRange<Double> {
        let values = weights.map { Units.displayWeight(kg: $0.weightKg, system: system) }
            + [Units.displayWeight(kg: profile.goalWeightKg, system: system)]
        let lo = values.min() ?? 0, hi = values.max() ?? 1
        let pad = max((hi - lo) * 0.15, 1)
        return (lo - pad)...(hi + pad)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardTitle("Weight trend")
            if weights.count < 2 {
                EmptyHint(icon: "chart.xyaxis.line", title: "No trend yet",
                          message: "Log a couple of weigh-ins to see your progress line.")
                    .frame(minHeight: 160)
            } else {
                Chart {
                    ForEach(weights) { w in
                        LineMark(
                            x: .value("Date", DayKey.date(from: w.day)),
                            y: .value("Weight", Units.displayWeight(kg: w.weightKg, system: system))
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Theme.weight)
                        PointMark(
                            x: .value("Date", DayKey.date(from: w.day)),
                            y: .value("Weight", Units.displayWeight(kg: w.weightKg, system: system))
                        )
                        .foregroundStyle(Theme.weight)
                    }
                    RuleMark(y: .value("Goal", Units.displayWeight(kg: profile.goalWeightKg, system: system)))
                        .foregroundStyle(Theme.calorie.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                        .annotation(position: .top, alignment: .leading) {
                            Text("Goal").font(.caption2).foregroundStyle(Theme.calorie)
                        }
                }
                .chartYScale(domain: yDomain)
                .frame(height: 200)
            }
        }
        .card()
    }
}

/// Last-14-days calorie intake bar chart vs target, with a weekly average (#7).
struct CalorieHistoryCard: View {
    let profile: UserProfile
    let foods: [FoodEntry]

    private struct DayTotal: Identifiable { let id: String; let date: Date; let calories: Int }

    private var last14: [DayTotal] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // Sum calories per day key once.
        var totals: [String: Int] = [:]
        for f in foods { totals[f.day, default: 0] += f.calories }
        return (0..<14).reversed().map { offset in
            let d = cal.date(byAdding: .day, value: -offset, to: today) ?? today
            let key = DayKey.key(for: d)
            return DayTotal(id: key, date: d, calories: totals[key] ?? 0)
        }
    }

    private var loggedDays: [DayTotal] { last14.filter { $0.calories > 0 } }
    private var weeklyAvg: Int {
        guard !loggedDays.isEmpty else { return 0 }
        return loggedDays.reduce(0) { $0 + $1.calories } / loggedDays.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardTitle("Calorie history", accessory: weeklyAvg > 0 ? "avg \(weeklyAvg) kcal" : nil)
            if loggedDays.isEmpty {
                EmptyHint(icon: "chart.bar", title: "No history yet",
                          message: "Log a few days to see how your intake tracks your target.")
                    .frame(minHeight: 140)
            } else {
                Chart {
                    ForEach(last14) { d in
                        BarMark(
                            x: .value("Day", d.date, unit: .day),
                            y: .value("Calories", d.calories)
                        )
                        .foregroundStyle(d.calories <= profile.calorieTarget ? Theme.weight : Theme.calorie)
                        .opacity(d.calories == 0 ? 0.15 : 1)
                    }
                    RuleMark(y: .value("Target", profile.calorieTarget))
                        .foregroundStyle(.secondary)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Target").font(.caption2).foregroundStyle(.secondary)
                        }
                }
                .frame(height: 180)
            }
        }
        .card()
    }
}
