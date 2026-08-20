import SwiftUI
import SwiftData

/// Water tracker: one-tap glass adds, progress toward the daily goal, undo.
struct WaterView: View {
    let profile: UserProfile
    @Environment(\.modelContext) private var context
    @Environment(DaySelection.self) private var day
    @AppStorage(SettingsKey.unitSystem) private var unitRaw = UnitSystem.metric.rawValue
    @Query private var allWaters: [WaterEntry]
    @State private var showGoal = false

    private var system: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .metric }
    private var today: String { day.dayKey }
    private var todayWaters: [WaterEntry] { allWaters.filter { $0.day == today } }
    private var totalMl: Int { todayWaters.reduce(0) { $0 + $1.amountMl } }
    private var progress: Double {
        profile.waterGoalMl > 0 ? min(Double(totalMl) / Double(profile.waterGoalMl), 1) : 0
    }

    /// One tap = one glass. 250 ml (metric) / 8 oz (imperial ≈ 237 ml).
    private var glassMl: Int { system == .metric ? 250 : 237 }
    private var presets: [Int] { system == .metric ? [500, 1000] : [473, 946] }

    private func add(_ ml: Int) {
        Haptics.success()
        withAnimation(Theme.motion) {
            context.insert(WaterEntry(day: today, amountMl: ml))
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.gutter) {
                    DateNavBar(selection: day)
                    ZStack {
                        Circle().stroke(Color(.tertiarySystemFill), lineWidth: 20)
                        Circle().trim(from: 0, to: progress)
                            .stroke(Theme.sweep(Theme.water),
                                    style: StrokeStyle(lineWidth: 20, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(Theme.motion, value: progress)
                        VStack(spacing: 2) {
                            Text("\(Units.displayVolume(ml: totalMl, system: system))")
                                .font(.system(size: 46, weight: .bold, design: .rounded))
                                .contentTransition(.numericText())
                                .animation(Theme.motion, value: totalMl)
                            Text("of \(Units.displayVolume(ml: profile.waterGoalMl, system: system)) \(system.volumeUnit)")
                                .font(.subheadline).foregroundStyle(.secondary)
                            if progress >= 1 {
                                Text("Goal hit 🎉").font(.caption.weight(.semibold))
                                    .foregroundStyle(Theme.water)
                            }
                        }
                    }
                    .frame(width: 210, height: 210)
                    .padding(.top)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(Int(progress * 100)) percent of your water goal")

                    Button { add(glassMl) } label: {
                        Label("Add a glass", systemImage: "plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 30)
                    }
                    .buttonStyle(.borderedProminent).tint(Theme.water)
                    .controlSize(.large)

                    // Common non-glass amounts, so a bottle isn't four taps.
                    HStack(spacing: 10) {
                        ForEach(presets, id: \.self) { ml in
                            Button { add(ml) } label: {
                                Text("+\(Units.displayVolume(ml: ml, system: system)) \(system.volumeUnit)")
                                    .font(.subheadline).frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered).tint(Theme.water)
                        }
                        Button {
                            Haptics.tap()
                            if let last = todayWaters.max(by: { $0.createdAt < $1.createdAt }) {
                                withAnimation(Theme.motion) { context.delete(last) }
                            }
                        } label: {
                            Image(systemName: "arrow.uturn.backward").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(todayWaters.isEmpty)
                        .accessibilityLabel("Undo last entry")
                    }

                    HStack {
                        Text("\(todayWaters.count) \(todayWaters.count == 1 ? "entry" : "entries") today")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Edit goal") { showGoal = true }
                    }
                    .card()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Water")
            .sheet(isPresented: $showGoal) {
                WaterGoalSheet(profile: profile, system: system)
            }
        }
    }
}

struct WaterGoalSheet: View {
    let profile: UserProfile
    let system: UnitSystem
    @Environment(\.dismiss) private var dismiss
    @State private var goal: Double = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily water goal (\(system.volumeUnit))") {
                    Stepper(value: $goal, in: goalRange, step: step) {
                        Text("\(Int(goal)) \(system.volumeUnit)")
                    }
                }
            }
            .navigationTitle("Water goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        profile.waterGoalMl = system == .metric ? Int(goal)
                            : Int(Units.ml(fromOz: goal).rounded())
                        dismiss()
                    }
                }
            }
            .onAppear {
                goal = Double(Units.displayVolume(ml: profile.waterGoalMl, system: system))
            }
        }
    }

    private var goalRange: ClosedRange<Double> { system == .metric ? 500...5000 : 16...170 }
    private var step: Double { system == .metric ? 250 : 8 }
}
