import SwiftUI
import SwiftData

/// The dashboard: date nav, streak, calorie + macro rings, food log, water, weight goal.
struct DashboardView: View {
    let profile: UserProfile
    @Environment(\.modelContext) private var context
    @AppStorage(SettingsKey.unitSystem) private var unitRaw = UnitSystem.metric.rawValue
    @AppStorage(SettingsKey.healthKitEnabled) private var healthKitEnabled = false
    @Environment(DaySelection.self) private var day

    @Query private var allFoods: [FoodEntry]
    @Query private var allWaters: [WaterEntry]
    @Query(sort: \WeightEntry.day) private var weights: [WeightEntry]

    @State private var showAddWeight = false
    @State private var weightInput = ""
    @State private var addingFood: MealType?

    private var system: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .metric }
    private var dayKey: String { day.dayKey }
    private var dayFoods: [FoodEntry] { allFoods.filter { $0.day == dayKey } }
    private var dayWaters: [WaterEntry] { allWaters.filter { $0.day == dayKey } }
    private var summary: DailySummary {
        DailySummary.build(profile: profile, foods: dayFoods, waters: dayWaters)
    }
    private var streak: Int {
        Insights.streak(foodDays: Set(allFoods.map { $0.day }))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.gutter) {
                    DateNavBar(selection: day)

                    if streak > 0 {
                        Label("\(streak)-day logging streak", systemImage: "flame.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.calorie)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Theme.calorie.opacity(0.12),
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Hero card: everything about eating, including the one add button.
                    VStack(spacing: Theme.stack) {
                        CalorieRing(summary: summary)
                        HStack(spacing: 20) {
                            MacroRing(title: "Protein", grams: summary.protein,
                                      target: summary.proteinTarget, color: Theme.protein)
                            MacroRing(title: "Carbs", grams: summary.carbs,
                                      target: summary.carbsTarget, color: Theme.carbs)
                            MacroRing(title: "Fats", grams: summary.fats,
                                      target: summary.fatsTarget, color: Theme.fats)
                        }
                        Button { Haptics.tap(); addingFood = .suggested() } label: {
                            Label("Add food", systemImage: "plus")
                                .font(.headline).frame(maxWidth: .infinity, minHeight: 28)
                        }
                        .buttonStyle(.borderedProminent).tint(Theme.calorie)
                        .controlSize(.large)
                    }
                    .frame(maxWidth: .infinity)
                    .card()

                    WaterCard(profile: profile, dayKey: dayKey, entries: dayWaters)

                    // Food log lives here now — no separate tab. Adding is the hero card's button.
                    DayFoodCard(dayKey: dayKey, foods: dayFoods)

                    // Goal / weight trend
                    GoalProgressCard(profile: profile, weights: weights, system: system) {
                        showAddWeight = true
                    }
                }
                .padding(Theme.gutter)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(greeting)
            .sheet(item: $addingFood) { AddFoodView(day: dayKey, defaultMeal: $0) }
            .logWeightAlert(isPresented: $showAddWeight, value: $weightInput, system: system) {
                upsertWeight(kg: $0)
            }
        }
        .onAppear(perform: publishWidget)
        .onChange(of: allFoods.count) { _, _ in publishWidget() }
        .onChange(of: allWaters.count) { _, _ in publishWidget() }
    }

    private func upsertWeight(kg: Double) {
        WeightLog.upsert(kg: kg, weights: weights, profile: profile,
                         context: context, healthKitEnabled: healthKitEnabled)
    }

    /// Push *today's* numbers to the shared App Group for the widget.
    private func publishWidget() {
        let today = DayKey.today
        let s = DailySummary.build(profile: profile,
                                   foods: allFoods.filter { $0.day == today },
                                   waters: allWaters.filter { $0.day == today })
        WidgetBridge.publish(s, day: today)
    }

    private var greeting: String {
        let name = profile.name.isEmpty ? "" : ", \(profile.name)"
        let hour = Calendar.current.component(.hour, from: Date())
        let part = switch hour {
        case 5..<12: "Good morning"
        case 12..<17: "Good afternoon"
        case 17..<22: "Good evening"
        default: "Hi"
        }
        return "\(part)\(name)"
    }
}

/// Weight goal progress + latest vs goal + estimated time to goal.
struct GoalProgressCard: View {
    let profile: UserProfile
    let weights: [WeightEntry]
    let system: UnitSystem
    let onLogWeight: () -> Void

    private var latest: Double { weights.last?.weightKg ?? profile.weightKg }
    private var start: Double { weights.first?.weightKg ?? profile.startWeightKg }

    private var progress: Double {
        let total = start - profile.goalWeightKg
        guard abs(total) > 0.01 else { return 1 }
        let done = start - latest
        return min(max(done / total, 0), 1)
    }

    private var etaWeeks: Int? {
        let plan = CalorieCalculator.plan(age: profile.age, sex: profile.sex,
                                          heightCm: profile.heightCm, weightKg: latest,
                                          activity: profile.activity, goal: profile.goal)
        return Insights.weeksToGoal(currentKg: latest, goalKg: profile.goalWeightKg,
                                    tdee: plan.tdee, calorieTarget: plan.calorieTarget)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CardTitle("Weight goal")
            HStack {
                weightColumn("Now", latest)
                Spacer()
                weightColumn("Goal", profile.goalWeightKg)
            }
            ProgressView(value: progress).tint(Theme.weight)
                .animation(Theme.motion, value: progress)
            HStack {
                Text("\(Int(progress * 100))% to goal")
                if let w = etaWeeks {
                    Spacer()
                    Text("~\(w) \(w == 1 ? "week" : "weeks") to go")
                }
            }
            .font(.caption).foregroundStyle(.secondary)

            Button { Haptics.tap(); onLogWeight() } label: {
                Label("Log weight", systemImage: "scalemass")
                    .font(.subheadline).frame(maxWidth: .infinity, minHeight: 24)
            }
            .buttonStyle(.bordered).tint(Theme.weight)
        }
        .card()
    }

    private func weightColumn(_ label: String, _ kg: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text("\(Units.displayWeight(kg: kg, system: system), specifier: "%.1f") \(system.weightUnit)")
                .font(.title3.weight(.semibold))
        }
    }
}
