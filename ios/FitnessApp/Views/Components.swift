import SwiftUI

/// Big calorie ring: consumed vs target with "remaining" in the center.
/// Turns red once you go over budget so the state is readable at a glance.
struct CalorieRing: View {
    let summary: DailySummary
    private var over: Bool { summary.caloriesRemaining < 0 }
    private var tint: Color { over ? .red : Theme.calorie }

    var body: some View {
        ZStack {
            Circle().stroke(Color(.tertiarySystemFill), lineWidth: 18)
            Circle()
                .trim(from: 0, to: summary.calorieProgress)
                .stroke(Theme.sweep(tint), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(Theme.motion, value: summary.calorieProgress)
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

/// A labeled macro progress bar (grams consumed vs target).
struct MacroBar: View {
    let title: String
    let grams: Double
    let target: Int
    let color: Color

    private var progress: Double { target > 0 ? min(grams / Double(target), 1) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title).font(.subheadline.weight(.medium))
                Spacer()
                Text("\(Int(grams)) / \(target) g")
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill))
                    Capsule().fill(Theme.bar(color))
                        .frame(width: max(geo.size.width * progress, progress > 0 ? 8 : 0))
                        .animation(Theme.motion, value: progress)
                }
            }
            .frame(height: 9)
        }
        .accessibilityElement(children: .combine)
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

/// Small linear progress with a caption, used for water/goal.
struct ProgressStat: View {
    let title: String
    let caption: String
    let progress: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.tight) {
            CardTitle(title, accessory: caption)
            ProgressView(value: progress).tint(color)
                .animation(Theme.motion, value: progress)
        }
    }
}

/// One tappable action tile in the dashboard's quick-action row.
struct QuickAction: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.title3)
                Text(title).font(.caption2.weight(.medium))
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
