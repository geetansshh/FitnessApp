import SwiftUI
import SwiftData

/// Single-scroll onboarding: collect stats, preview the calorie target, save.
struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(SettingsKey.unitSystem) private var unitRaw = UnitSystem.metric.rawValue
    @State private var vm = OnboardingViewModel()

    private var system: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .metric }

    var body: some View {
        NavigationStack {
            Form {
                Section("About you") {
                    TextField("Name", text: $vm.name)
                    Picker("Sex", selection: $vm.sex) {
                        ForEach(Sex.allCases) { Text($0.label).tag($0) }
                    }
                    Stepper("Age: \(vm.age)", value: $vm.age, in: 13...100)
                }

                Section("Body") {
                    Picker("Units", selection: $vm.system) {
                        Text("Metric").tag(UnitSystem.metric)
                        Text("Imperial").tag(UnitSystem.imperial)
                    }
                    .pickerStyle(.segmented)

                    if vm.system == .metric {
                        LabeledStepper(label: "Height", value: $vm.heightCm,
                                       range: 100...250, step: 1, unit: "cm")
                    } else {
                        HStack {
                            Text("Height")
                            Spacer()
                            Picker("ft", selection: $vm.heightFeet) {
                                ForEach(3...7, id: \.self) { Text("\($0) ft").tag($0) }
                            }.labelsHidden()
                            Picker("in", selection: $vm.heightInches) {
                                ForEach(0...11, id: \.self) { Text("\($0) in").tag($0) }
                            }.labelsHidden()
                        }
                    }
                    LabeledStepper(label: "Weight", value: $vm.weightValue,
                                   range: unitRange, step: 0.5, unit: vm.system.weightUnit)
                }

                Section("Goal") {
                    Picker("Goal", selection: $vm.goal) {
                        ForEach(GoalType.allCases) { Text($0.label).tag($0) }
                    }
                    LabeledStepper(label: "Goal weight", value: $vm.goalWeightValue,
                                   range: unitRange, step: 0.5, unit: vm.system.weightUnit)
                    Picker("Activity", selection: $vm.activity) {
                        ForEach(ActivityLevel.allCases) { level in
                            Text(level.label).tag(level)
                        }
                    }
                    Text(vm.activity.detail)
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section("Daily water goal") {
                    Stepper(value: waterBinding, in: waterRange, step: waterStep) {
                        HStack {
                            Text("Water")
                            Spacer()
                            Text("\(Units.displayVolume(ml: vm.waterGoalMl, system: vm.system)) \(vm.system.volumeUnit)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Your daily target") {
                    TargetPreview(plan: vm.plan)
                }

                Section {
                    Button {
                        vm.system = system
                        let profile = vm.save(into: context)
                        _ = profile
                    } label: {
                        Text("Get started").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!vm.isValid)
                }
            }
            .navigationTitle("Welcome")
            .onAppear { vm.system = system }
        }
    }

    private var unitRange: ClosedRange<Double> {
        vm.system == .metric ? 30...400 : 66...880
    }

    // Water goal edited in display units, stored back as ml.
    private var waterStep: Double { vm.system == .metric ? 250 : 8 }
    private var waterRange: ClosedRange<Double> { vm.system == .metric ? 500...5000 : 16...170 }
    private var waterBinding: Binding<Double> {
        Binding(
            get: { Double(Units.displayVolume(ml: vm.waterGoalMl, system: vm.system)) },
            set: { vm.waterGoalMl = vm.system == .metric ? Int($0) : Int(Units.ml(fromOz: $0).rounded()) }
        )
    }
}

/// Compact numeric row with +/- and a unit suffix.
struct LabeledStepper: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String

    var body: some View {
        Stepper(value: $value, in: range, step: step) {
            HStack {
                Text(label)
                Spacer()
                Text("\(value, specifier: value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f") \(unit)")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct TargetPreview: View {
    let plan: CalorieCalculator.Plan
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(plan.calorieTarget)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.calorie)
                Text("kcal / day").foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                MacroPill(title: "Protein", grams: plan.protein, color: Theme.protein)
                MacroPill(title: "Carbs", grams: plan.carbs, color: Theme.carbs)
                MacroPill(title: "Fats", grams: plan.fats, color: Theme.fats)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct MacroPill: View {
    let title: String
    let grams: Int
    let color: Color
    var body: some View {
        VStack {
            Text("\(grams)g").font(.headline).foregroundStyle(color)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
    }
}
