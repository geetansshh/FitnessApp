import WidgetKit
import SwiftUI

// Shared App Group + keys — kept in sync with the app's WidgetBridge.
// ponytail: tiny key list duplicated across the target boundary instead of a shared framework.
private let appGroup = "group.com.geetansh.FitnessApp"

struct FitnessEntry: TimelineEntry {
    let date: Date
    let calorieTarget: Int
    let caloriesConsumed: Int
    let waterMl: Int
    let waterGoalMl: Int

    var caloriesRemaining: Int { max(calorieTarget - caloriesConsumed, 0) }
    var calorieProgress: Double {
        calorieTarget > 0 ? min(Double(caloriesConsumed) / Double(calorieTarget), 1) : 0
    }
    var waterProgress: Double {
        waterGoalMl > 0 ? min(Double(waterMl) / Double(waterGoalMl), 1) : 0
    }

    static let sample = FitnessEntry(date: Date(), calorieTarget: 2200,
                                     caloriesConsumed: 1450, waterMl: 1500, waterGoalMl: 2500)
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> FitnessEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (FitnessEntry) -> Void) {
        completion(read())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FitnessEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [read()], policy: .after(next)))
    }

    private func read() -> FitnessEntry {
        let d = UserDefaults(suiteName: appGroup)
        return FitnessEntry(
            date: Date(),
            calorieTarget: d?.integer(forKey: "w.calorieTarget") ?? 0,
            caloriesConsumed: d?.integer(forKey: "w.caloriesConsumed") ?? 0,
            waterMl: d?.integer(forKey: "w.waterMl") ?? 0,
            waterGoalMl: d?.integer(forKey: "w.waterGoalMl") ?? 0)
    }
}

struct FitnessAppWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: FitnessEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: entry.calorieProgress) {
                Text("kcal")
            } currentValueLabel: {
                Text("\(entry.caloriesRemaining)")
            }
            .gaugeStyle(.accessoryCircularCapacity)

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.caloriesRemaining) kcal left").font(.headline)
                Text("Water \(entry.waterMl) / \(entry.waterGoalMl) ml")
                    .font(.caption).foregroundStyle(.secondary)
            }

        case .systemMedium:
            HStack(spacing: 20) {
                ringView
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(entry.caloriesRemaining)").font(.system(size: 30, weight: .bold, design: .rounded))
                    Text("kcal left").font(.caption).foregroundStyle(.secondary)
                    ProgressView(value: entry.waterProgress) {
                        Text("Water").font(.caption2)
                    }.tint(.cyan)
                }
            }

        default: // systemSmall
            VStack(spacing: 6) {
                ringView
                Text("kcal left").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private var ringView: some View {
        ZStack {
            Circle().stroke(.quaternary, lineWidth: 10)
            Circle().trim(from: 0, to: entry.calorieProgress)
                .stroke(.orange, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(entry.caloriesRemaining)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
        }
        .frame(width: 76, height: 76)
    }
}

struct FitnessAppWidget: Widget {
    let kind = "FitnessAppWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FitnessAppWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today")
        .description("Calories left and water at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

@main
struct FitnessAppWidgetBundle: WidgetBundle {
    var body: some Widget { FitnessAppWidget() }
}
