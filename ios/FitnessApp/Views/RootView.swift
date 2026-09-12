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
    @Environment(\.modelContext) private var context
    @AppStorage(SettingsKey.syncEnabled) private var syncEnabled = false
    @AppStorage(SettingsKey.serverURL) private var serverURL = ""
    @AppStorage(SettingsKey.apiKey) private var apiKey = ""
    @AppStorage(SettingsKey.foodCatalogFetchedAt) private var catalogFetchedAt = 0.0
    @State private var tab = initialTab()

    var body: some View {
        TabView(selection: $tab) {
            DashboardView(profile: profile)
                .tabItem { Label("Today", systemImage: "square.grid.2x2.fill") }.tag(0)
            GoalsView(profile: profile)
                .tabItem { Label("Goals", systemImage: "chart.line.uptrend.xyaxis") }.tag(1)
            SettingsView(profile: profile)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }.tag(2)
        }
        .tint(Theme.calorie)
        .task {
            await refreshFoodCatalog()
            await NotificationService.scheduleBuildExpiryWarnings()
        }
    }

    /// Reference data changes rarely — pull it weekly, and only when sync is on.
    /// A failure is silent: the cached table keeps working.
    private func refreshFoodCatalog() async {
        let now = Date().timeIntervalSince1970
        guard syncEnabled, now - catalogFetchedAt > 7 * 24 * 3600,
              let url = URL(string: serverURL) else { return }
        do {
            try await FoodCatalog.refresh(context, client: APIClient(baseURL: url, apiKey: apiKey))
            catalogFetchedAt = now
        } catch {}
    }

    /// DEBUG helper: `-tab today|goals|settings` opens that tab for screenshot verification.
    private static func initialTab() -> Int {
        #if DEBUG
        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "-tab"), i + 1 < args.count {
            return ["today": 0, "goals": 1, "settings": 2][args[i + 1]] ?? 0
        }
        #endif
        return 0
    }
}
