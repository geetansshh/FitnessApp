import SwiftUI

/// Edit body stats & goals. Recomputes the calorie target on save so it never drifts.
struct EditProfileSheet: View {
    let profile: UserProfile
    let system: UnitSystem
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var age = 30
    @State private var sex: Sex = .male
    @State private var activity: ActivityLevel = .moderate
    @State private var goal: GoalType = .lose
    @State private var heightDisplay = 0.0   // cm (metric) or total inches (imperial)
    @State private var weightDisplay = 0.0
    @State private var goalWeightDisplay = 0.0

    var body: some View {
        NavigationStack {
            Form {
                Section("About you") {
                    TextField("Name", text: $name)
                    Picker("Sex", selection: $sex) { ForEach(Sex.allCases) { Text($0.label).tag($0) } }
                    Stepper("Age: \(age)", value: $age, in: 13...100)
                }
                Section("Body (\(system.weightUnit))") {
                    if system == .metric {
                        Stepper("Height: \(Int(heightDisplay)) cm", value: $heightDisplay, in: 100...250, step: 1)
                    } else {
                        Stepper("Height: \(Int(heightDisplay)/12) ft \(Int(heightDisplay)%12) in",
                                value: $heightDisplay, in: 48...96, step: 1)
                    }
                    Stepper("Weight: \(weightDisplay, specifier: "%.1f") \(system.weightUnit)",
                            value: $weightDisplay, in: weightRange, step: 0.5)
                }
                Section("Goal") {
                    Picker("Goal", selection: $goal) { ForEach(GoalType.allCases) { Text($0.label).tag($0) } }
                    Stepper("Goal weight: \(goalWeightDisplay, specifier: "%.1f") \(system.weightUnit)",
                            value: $goalWeightDisplay, in: weightRange, step: 0.5)
                    Picker("Activity", selection: $activity) {
                        ForEach(ActivityLevel.allCases) { Text($0.label).tag($0) }
                    }
                }
                Section("New daily target") {
                    TargetPreview(plan: previewPlan)
                }
            }
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear(perform: load)
        }
    }

    private var weightRange: ClosedRange<Double> { system == .metric ? 30...400 : 66...880 }

    private var metricHeightCm: Double { system == .metric ? heightDisplay : heightDisplay * 2.54 }
    private var metricWeightKg: Double { Units.kgFromDisplay(weightDisplay, system: system) }
    private var metricGoalKg: Double { Units.kgFromDisplay(goalWeightDisplay, system: system) }

    private var previewPlan: CalorieCalculator.Plan {
        CalorieCalculator.plan(age: age, sex: sex, heightCm: metricHeightCm,
                               weightKg: metricWeightKg, activity: activity, goal: goal)
    }

    private func load() {
        name = profile.name
        age = profile.age
        sex = profile.sex
        activity = profile.activity
        goal = profile.goal
        heightDisplay = system == .metric ? profile.heightCm : (profile.heightCm / 2.54).rounded()
        weightDisplay = Units.displayWeight(kg: profile.weightKg, system: system)
        goalWeightDisplay = Units.displayWeight(kg: profile.goalWeightKg, system: system)
    }

    private func save() {
        profile.name = name.trimmingCharacters(in: .whitespaces)
        profile.age = age
        profile.sex = sex
        profile.activity = activity
        profile.goal = goal
        profile.heightCm = metricHeightCm
        profile.weightKg = metricWeightKg
        profile.goalWeightKg = metricGoalKg
        profile.recomputeTargets()
        dismiss()
    }
}
