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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    DateNavBar(selection: day)
                    ZStack {
                        Circle().stroke(Color(.tertiarySystemFill), lineWidth: 18)
                        Circle().trim(from: 0, to: progress)
                            .stroke(Theme.water, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 0.35), value: progress)
                        VStack {
                            Text("\(Units.displayVolume(ml: totalMl, system: system))")
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                            Text("of \(Units.displayVolume(ml: profile.waterGoalMl, system: system)) \(system.volumeUnit)")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 200, height: 200)
                    .padding(.top)

                    HStack(spacing: 14) {
                        Button {
                            context.insert(WaterEntry(day: today, amountMl: glassMl))
                        } label: {
                            Label("Add glass", systemImage: "plus").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent).tint(Theme.water)

                        Button(role: .destructive) {
                            if let last = todayWaters.max(by: { $0.createdAt < $1.createdAt }) {
                                context.delete(last)
                            }
                        } label: {
                            Label("Undo", systemImage: "arrow.uturn.backward").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(todayWaters.isEmpty)
                    }

                    HStack {
                        Text("\(todayWaters.count) glasses today")
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
