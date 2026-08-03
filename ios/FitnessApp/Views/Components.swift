import SwiftUI

/// Big calorie ring: consumed vs target with "remaining" in the center.
struct CalorieRing: View {
    let summary: DailySummary
    var body: some View {
        ZStack {
            Circle().stroke(Color(.tertiarySystemFill), lineWidth: 16)
            Circle()
                .trim(from: 0, to: summary.calorieProgress)
                .stroke(Theme.calorie, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.4), value: summary.calorieProgress)
            VStack(spacing: 2) {
                Text("\(max(summary.caloriesRemaining, 0))")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                Text(summary.caloriesRemaining >= 0 ? "kcal left" : "over")
                    .font(.caption).foregroundStyle(.secondary)
                Text("\(summary.caloriesConsumed) / \(summary.calorieTarget)")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .frame(width: 180, height: 180)
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
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.subheadline.weight(.medium))
                Spacer()
                Text("\(Int(grams)) / \(target) g").font(.caption).foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill))
                    Capsule().fill(color).frame(width: geo.size.width * progress)
                        .animation(.easeOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

/// ‹ Today › date navigator shared by Dashboard/Food/Water (feature #1).
struct DateNavBar: View {
    @Bindable var selection: DaySelection

    var body: some View {
        HStack {
            Button { withAnimation { selection.shift(-1) } } label: {
                Image(systemName: "chevron.left").frame(width: 44, height: 32)
            }
            Spacer()
            Button { withAnimation { selection.goToday() } } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    Text(selection.label).fontWeight(.semibold)
                }
            }
            .tint(.primary)
            Spacer()
            Button { withAnimation { selection.shift(1) } } label: {
                Image(systemName: "chevron.right").frame(width: 44, height: 32)
            }
            .disabled(!selection.canGoForward)
        }
        .padding(.horizontal, 4)
    }
}

/// Small linear progress with a caption, used for water/goal.
struct ProgressStat: View {
    let title: String
    let caption: String
    let progress: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                Text(caption).font(.caption).foregroundStyle(.secondary)
            }
            ProgressView(value: progress).tint(color)
        }
    }
}
