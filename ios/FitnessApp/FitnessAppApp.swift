import SwiftUI
import SwiftData

/// AppStorage keys, centralized so Settings and views agree.
enum SettingsKey {
    static let unitSystem = "unitSystem"           // UnitSystem.rawValue
    static let waterRemindersOn = "waterRemindersOn"
    static let waterReminderCount = "waterReminderCount"
    static let waterReminderStart = "waterReminderStart"   // hour 0-23 (#8)
    static let waterReminderEnd = "waterReminderEnd"       // hour 0-23 (#8)
    static let syncEnabled = "syncEnabled"
    static let serverURL = "serverURL"
    static let onboarded = "onboarded"
    static let healthKitEnabled = "healthKitEnabled"
}

@main
struct FitnessAppApp: App {
    let container: ModelContainer
    @State private var daySelection = DaySelection()

    init() {
        #if DEBUG
        CalorieCalculator.selfCheck()
        Insights.selfCheck()
        #endif
        do {
            container = try ModelContainer(for: UserProfile.self, FoodEntry.self,
                                           WaterEntry.self, WeightEntry.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        #if DEBUG
        if CommandLine.arguments.contains("-seedDemo") {
            DemoSeed.run(container.mainContext)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(daySelection)
        }
        .modelContainer(container)
    }
}
