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
    @State private var showEdit = false

    private var system: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .metric }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    WeightChartCard(profile: profile, weights: weights, system: system)

                    CalorieHistoryCard(profile: profile, foods: allFoods)

                    Button {
                        showAddWeight = true
                    } label: {
                        Label("Log weight", systemImage: "plus").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).tint(Theme.weight)

                    // Recent history
                    VStack(alignment: .leading, spacing: 10) {
                        Text("History").font(.headline)
                        if weights.isEmpty {
                            Text("No entries yet.").foregroundStyle(.secondary)
                        }
                        ForEach(weights.reversed()) { w in
                            HStack {
                                Text(w.day).foregroundStyle(.secondary)
                                Spacer()
                                Text("\(Units.displayWeight(kg: w.weightKg, system: system), specifier: "%.1f") \(system.weightUnit)")
                                    .fontWeight(.medium)
                            }
                            .font(.subheadline)
                        }
                    }
                    .card()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Goals")
            .toolbar {
                Button("Edit") { showEdit = true }
            }
            .sheet(isPresented: $showAddWeight) {
                AddWeightSheet(system: system) { kg in
                    upsertWeight(kg: kg)
                }
            }
            .sheet(isPresented: $showEdit) {
                EditProfileSheet(profile: profile, system: system)
            }
        }
    }

    /// One weigh-in per day: replace today's entry if it exists. Keeps the profile weight fresh.
    private func upsertWeight(kg: Double) {
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
    }
}

struct WeightChartCard: View {
    let profile: UserProfile
    let weights: [WeightEntry]
    let system: UnitSystem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weight trend").font(.headline)
            if weights.count < 2 {
                Text("Log a couple of weigh-ins to see your trend.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 160)
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
            HStack {
                Text("Calorie history").font(.headline)
                Spacer()
                if weeklyAvg > 0 {
                    Text("avg \(weeklyAvg) kcal").font(.caption).foregroundStyle(.secondary)
                }
            }
            if loggedDays.isEmpty {
                Text("Log a few days to see your intake trend.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 140)
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

struct AddWeightSheet: View {
    let system: UnitSystem
    let onSave: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var value = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Today's weight (\(system.weightUnit))") {
                    TextField("0.0", text: $value)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Log weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let v = Double(value), v > 0 {
                            onSave(Units.kgFromDisplay(v, system: system))
                            dismiss()
                        }
                    }
                    .disabled(Double(value) == nil)
                }
            }
        }
    }
}
