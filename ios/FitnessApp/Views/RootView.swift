import SwiftUI
import SwiftData

/// Decides between onboarding and the main tab bar based on whether a profile exists.
struct RootView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        if let profile = profiles.first {
            MainTabView(profile: profile)
        } else {
            OnboardingView()
        }
    }
}

struct MainTabView: View {
    let profile: UserProfile
    @State private var tab = initialTab()

    var body: some View {
        TabView(selection: $tab) {
            DashboardView(profile: profile)
                .tabItem { Label("Today", systemImage: "square.grid.2x2.fill") }.tag(0)
            FoodLogView()
                .tabItem { Label("Food", systemImage: "fork.knife") }.tag(1)
            WaterView(profile: profile)
                .tabItem { Label("Water", systemImage: "drop.fill") }.tag(2)
            GoalsView(profile: profile)
                .tabItem { Label("Goals", systemImage: "chart.line.uptrend.xyaxis") }.tag(3)
            SettingsView(profile: profile)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }.tag(4)
        }
        .tint(Theme.calorie)
    }

    /// DEBUG helper: `-tab food|goals|...` opens that tab for screenshot verification.
    private static func initialTab() -> Int {
        #if DEBUG
        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "-tab"), i + 1 < args.count {
            return ["today": 0, "food": 1, "water": 2, "goals": 3, "settings": 4][args[i + 1]] ?? 0
        }
        #endif
        return 0
    }
}
