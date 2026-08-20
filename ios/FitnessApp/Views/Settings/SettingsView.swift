import SwiftUI
import SwiftData

struct SettingsView: View {
    let profile: UserProfile
    @Environment(\.modelContext) private var context

    @AppStorage(SettingsKey.unitSystem) private var unitRaw = UnitSystem.metric.rawValue
    @AppStorage(SettingsKey.waterRemindersOn) private var remindersOn = false
    @AppStorage(SettingsKey.waterReminderCount) private var reminderCount = 6
    @AppStorage(SettingsKey.waterReminderStart) private var reminderStart = 9
    @AppStorage(SettingsKey.waterReminderEnd) private var reminderEnd = 21
    @AppStorage(SettingsKey.syncEnabled) private var syncEnabled = false
    @AppStorage(SettingsKey.serverURL) private var serverURL = "http://localhost:8080"
    @AppStorage(SettingsKey.apiKey) private var apiKey = ""
    @AppStorage(SettingsKey.healthKitEnabled) private var healthKitEnabled = false
    @State private var healthStatus = ""

    @Query private var foods: [FoodEntry]
    @Query private var waters: [WaterEntry]
    @Query private var weights: [WeightEntry]
    @Query private var profiles: [UserProfile]

    @State private var syncStatus = ""
    @State private var showResetConfirm = false

    private var system: UnitSystem {
        get { UnitSystem(rawValue: unitRaw) ?? .metric }
        nonmutating set { unitRaw = newValue.rawValue }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Units") {
                    Picker("Measurement", selection: Binding(
                        get: { system }, set: { unitRaw = $0.rawValue })) {
                        ForEach(UnitSystem.allCases) { Text($0.label).tag($0) }
                    }
                }

                Section("Water reminders") {
                    Toggle("Daily reminders", isOn: $remindersOn)
                        .onChange(of: remindersOn) { _, _ in reschedule() }
                    if remindersOn {
                        Stepper("\(reminderCount) reminders / day", value: $reminderCount, in: 1...12)
                            .onChange(of: reminderCount) { _, _ in reschedule() }
                        Picker("From", selection: $reminderStart) {
                            ForEach(hourOptions(0...22), id: \.self) { Text(hourLabel($0)).tag($0) }
                        }
                        .onChange(of: reminderStart) { _, _ in
                            if reminderEnd <= reminderStart { reminderEnd = min(reminderStart + 1, 23) }
                            reschedule()
                        }
                        Picker("Until", selection: $reminderEnd) {
                            ForEach(hourOptions((reminderStart + 1)...23), id: \.self) { Text(hourLabel($0)).tag($0) }
                        }
                        .onChange(of: reminderEnd) { _, _ in reschedule() }
                    }
                }

                Section("Apple Health") {
                    Toggle("Sync with Apple Health", isOn: $healthKitEnabled)
                        .onChange(of: healthKitEnabled) { _, on in
                            if on { Task { await connectHealth() } }
                        }
                        .disabled(!HealthKitService.isAvailable)
                    if !HealthKitService.isAvailable {
                        Text("Health data isn't available on this device.")
                            .font(.caption).foregroundStyle(.secondary)
                    } else if !healthStatus.isEmpty {
                        Text(healthStatus).font(.caption).foregroundStyle(.secondary)
                    }
                }

                Section("Cloud backup (optional)") {
                    Toggle("Enable server sync", isOn: $syncEnabled)
                    if syncEnabled {
                        TextField("Server URL", text: $serverURL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                        SecureField("API key (if your server sets one)", text: $apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button("Test connection") { Task { await testConnection() } }
                        Button("Back up now") { Task { await backup() } }
                        if !syncStatus.isEmpty {
                            Text(syncStatus).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Data") {
                    Button("Reset all data", role: .destructive) { showResetConfirm = true }
                }

                Section {
                    Text("FitnessApp v1.0 · local-first")
                        .font(.caption).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Delete everything?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Delete all data", role: .destructive) { resetAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes your profile, food, water, and weight history. This cannot be undone.")
            }
        }
    }

    private func client() -> APIClient? {
        guard let url = URL(string: serverURL) else { return nil }
        return APIClient(baseURL: url, apiKey: apiKey)
    }

    private func reschedule() {
        Task {
            if remindersOn {
                await NotificationService.scheduleWaterReminders(
                    count: reminderCount, startHour: reminderStart, endHour: reminderEnd)
            } else {
                NotificationService.cancelWaterReminders()
            }
        }
    }

    private func connectHealth() async {
        let ok = await HealthKitService.requestAuthorization()
        guard ok else {
            healthStatus = "Couldn't get Health permission."
            healthKitEnabled = false
            return
        }
        // Pull the latest weight from Health into the app.
        if let kg = await HealthKitService.latestWeightKg() {
            let today = DayKey.today
            if let existing = weights.first(where: { $0.day == today }) {
                existing.weightKg = kg
            } else {
                context.insert(WeightEntry(day: today, weightKg: kg))
            }
            profile.weightKg = kg
            profile.recomputeTargets()
            healthStatus = "Connected ✓ Imported \(String(format: "%.1f", kg)) kg."
        } else {
            healthStatus = "Connected ✓"
        }
    }

    private func hourOptions(_ range: ClosedRange<Int>) -> [Int] { Array(range) }
    private func hourLabel(_ h: Int) -> String {
        var c = DateComponents(); c.hour = h
        let date = Calendar.current.date(from: c) ?? Date()
        return date.formatted(.dateTime.hour())
    }

    private func testConnection() async {
        guard let c = client() else { syncStatus = "Invalid URL"; return }
        do { try await c.health(); syncStatus = "Connected ✓" }
        catch { syncStatus = "Failed: \(error.localizedDescription)" }
    }

    private func backup() async {
        guard let c = client() else { syncStatus = "Invalid URL"; return }
        syncStatus = "Backing up…"
        do {
            try await SyncService.backup(profile: profile, foods: foods, waters: waters,
                                         weights: weights, client: c)
            syncStatus = "Backed up ✓"
        } catch {
            syncStatus = "Failed: \(error.localizedDescription)"
        }
    }

    private func resetAll() {
        for f in foods { context.delete(f) }
        for w in waters { context.delete(w) }
        for w in weights { context.delete(w) }
        for p in profiles { context.delete(p) }
        NotificationService.cancelWaterReminders()
    }
}
