import SwiftUI
import SwiftData

/// Compact water row on Today: a small progress ring, the day's total, and one
/// big button. Tap it for a glass, hold it for presets / undo / goal.
struct WaterCard: View {
    let profile: UserProfile
    let dayKey: String
    /// The selected day's entries (filtered by the caller).
    let entries: [WaterEntry]

    @Environment(\.modelContext) private var context
    @AppStorage(SettingsKey.unitSystem) private var unitRaw = UnitSystem.metric.rawValue
    @State private var showGoal = false

    private var system: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .metric }
    private var totalMl: Int { entries.reduce(0) { $0 + $1.amountMl } }
    private var goalMl: Int { max(profile.waterGoalMl, 1) }
    private var progress: Double { min(Double(totalMl) / Double(goalMl), 1) }

    /// One tap = one glass. 250 ml (metric) / 8 oz (imperial ≈ 237 ml).
    private var glassMl: Int { system == .metric ? 250 : 237 }
    private var presets: [Int] { system == .metric ? [500, 1000] : [473, 946] }

    var body: some View {
        HStack(spacing: Theme.gutter) {
            ring
            VStack(alignment: .leading, spacing: 2) {
                Text("Water").font(.subheadline.weight(.semibold))
                Text("\(Units.displayVolume(ml: totalMl, system: system)) / \(Units.displayVolume(ml: goalMl, system: system)) \(system.volumeUnit)")
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(Theme.motion, value: totalMl)
                if totalMl == 0 {
                    Text("Tap + for a glass, hold for more")
                        .font(.caption2).foregroundStyle(.tertiary)
                }
            }
            Spacer(minLength: 0)
            addButton
        }
        .card()
        .sheet(isPresented: $showGoal) { WaterGoalSheet(profile: profile, system: system) }
    }

    private var ring: some View {
        ProgressRing(progress: progress, color: Theme.water, lineWidth: 7) {
            if progress >= 1 {
                Image(systemName: "checkmark")
                    .font(.subheadline.weight(.bold)).foregroundStyle(Theme.water)
            } else {
                Text("\(Int(progress * 100))%")
                    .font(.caption.weight(.bold).monospacedDigit())
            }
        }
        .frame(width: 54, height: 54)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int(progress * 100)) percent of your water goal")
    }

    /// Tap adds a glass; long-press opens the rest, so the common case stays one tap.
    private var addButton: some View {
        Menu {
            ForEach(presets, id: \.self) { ml in
                Button {
                    add(ml)
                } label: {
                    Label("Add \(Units.displayVolume(ml: ml, system: system)) \(system.volumeUnit)",
                          systemImage: "drop.fill")
                }
            }
            Button { undo() } label: { Label("Undo last", systemImage: "arrow.uturn.backward") }
                .disabled(entries.isEmpty)
            Button { showGoal = true } label: { Label("Edit goal", systemImage: "target") }
            Button(role: .destructive) { clear() } label: { Label("Clear day", systemImage: "trash") }
                .disabled(entries.isEmpty)
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Theme.water)
                .frame(width: 54, height: 54)
                .background(Theme.water.opacity(0.14), in: Circle())
        } primaryAction: {
            add(glassMl)
        }
        .accessibilityLabel("Add a glass of water")
    }

    private func add(_ ml: Int) {
        Haptics.success()
        withAnimation(Theme.motion) { context.insert(WaterEntry(day: dayKey, amountMl: ml)) }
    }

    private func undo() {
        Haptics.tap()
        guard let last = entries.max(by: { $0.createdAt < $1.createdAt }) else { return }
        withAnimation(Theme.motion) { context.delete(last) }
    }

    private func clear() {
        Haptics.tap()
        withAnimation(Theme.motion) { entries.forEach(context.delete) }
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
            .presentationDetents([.height(220)])
        }
    }

    private var goalRange: ClosedRange<Double> { system == .metric ? 500...5000 : 16...170 }
    private var step: Double { system == .metric ? 250 : 8 }
}
