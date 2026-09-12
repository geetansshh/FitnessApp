import SwiftUI

/// Trimmed circle with a track behind it — the shape every metric on Today uses.
struct ProgressRing<Center: View>: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 18
    @ViewBuilder var center: Center

    var body: some View {
        ZStack {
            Circle().stroke(Color(.tertiarySystemFill), lineWidth: lineWidth)
            Circle().trim(from: 0, to: progress)
                .stroke(Theme.sweep(color),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(Theme.motion, value: progress)
            center
        }
    }
}

/// Big calorie ring: consumed vs target with "remaining" in the center.
/// Turns red once you go over budget so the state is readable at a glance.
struct CalorieRing: View {
    let summary: DailySummary
    private var over: Bool { summary.caloriesRemaining < 0 }
    private var tint: Color { over ? .red : Theme.calorie }

    var body: some View {
        ProgressRing(progress: summary.calorieProgress, color: tint) {
            VStack(spacing: 2) {
                Text("\(abs(summary.caloriesRemaining))")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(over ? .red : .primary)
                    .contentTransition(.numericText())
                    .animation(Theme.motion, value: summary.caloriesRemaining)
                Text(over ? "kcal over" : "kcal left")
                    .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                Text("\(summary.caloriesConsumed) / \(summary.calorieTarget)")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .frame(width: 190, height: 190)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(over
            ? "\(abs(summary.caloriesRemaining)) calories over your target"
            : "\(summary.caloriesRemaining) calories left of \(summary.calorieTarget)")
    }
}

/// One macro as a small ring: progress in the ring, grams under it.
struct MacroRing: View {
    let title: String
    let grams: Double
    let target: Int
    let color: Color

    private var progress: Double { target > 0 ? min(grams / Double(target), 1) : 0 }

    var body: some View {
        VStack(spacing: 6) {
            ProgressRing(progress: progress, color: color, lineWidth: 7) {
                Text("\(Int(grams))")
                    .font(.footnote.weight(.semibold).monospacedDigit())
                    .contentTransition(.numericText())
            }
            .frame(width: 58, height: 58)
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text("of \(target)g").font(.caption2).foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(Int(grams)) of \(target) grams")
    }
}

/// ‹ Today › date navigator shared by Dashboard/Food/Water.
struct DateNavBar: View {
    @Bindable var selection: DaySelection

    var body: some View {
        HStack(spacing: 0) {
            navButton("chevron.left", enabled: true) { selection.shift(-1) }
            Spacer()
            Button {
                Haptics.tap()
                withAnimation(Theme.motion) { selection.goToday() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar").font(.footnote)
                    Text(selection.label).fontWeight(.semibold)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(Color(.tertiarySystemFill), in: Capsule())
            }
            .buttonStyle(.plain)
            Spacer()
            navButton("chevron.right", enabled: selection.canGoForward) { selection.shift(1) }
        }
        .padding(.horizontal, 4)
    }

    private func navButton(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            withAnimation(Theme.motion) { action() }
        } label: {
            Image(systemName: icon).font(.body.weight(.semibold))
                .frame(width: 44, height: 34)
        }
        .buttonStyle(.plain)
        .foregroundStyle(enabled ? Color.primary : Color(.tertiaryLabel))
        .disabled(!enabled)
    }
}

extension View {
    /// Weigh-in popup. One number never justified a full sheet, and an alert
    /// keeps the keyboard and the current screen in view.
    func logWeightAlert(isPresented: Binding<Bool>, value: Binding<String>,
                        system: UnitSystem, onSave: @escaping (Double) -> Void) -> some View {
        alert("Log weight", isPresented: isPresented) {
            TextField(system.weightUnit, text: value)
                .keyboardType(.decimalPad)
            Button("Cancel", role: .cancel) { value.wrappedValue = "" }
            Button("Save") {
                if let v = Double(value.wrappedValue), v > 0 {
                    Haptics.success()
                    onSave(Units.kgFromDisplay(v, system: system))
                }
                value.wrappedValue = ""
            }
        } message: {
            Text("Today's weight in \(system.weightUnit)")
        }
    }
}
