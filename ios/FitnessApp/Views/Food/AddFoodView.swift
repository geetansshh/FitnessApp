import SwiftUI
import SwiftData

/// Add or edit a food entry. Primary path is search-and-tap from the built-in food
/// library with a servings stepper; manual macro entry stays available underneath.
struct AddFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    /// The day the entry belongs to (from the selected date).
    let day: String
    /// nil = create a new entry; non-nil = edit this one.
    var editing: FoodEntry?
    var defaultMeal: MealType = MealType.suggested()

    @Query private var allFoods: [FoodEntry]
    @State private var query = ""
    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fats = ""
    @State private var meal: MealType = .snack
    @State private var servings = 1.0
    /// Per-serving values of the picked catalog row, so the stepper can rescale.
    @State private var picked: FoodCatalogItem?
    @State private var loaded = false
    @FocusState private var searchFocused: Bool

    private var caloriesValue: Int? { Int(calories) }
    private var isValid: Bool { (caloriesValue ?? 0) > 0 }
    private var results: [FoodCatalogItem] { FoodCatalog.search(query, in: context) }

    /// Up to 8 most-recently-logged distinct foods, for one-tap re-use.
    private var recent: [FoodEntry] {
        var seen = Set<String>()
        var out: [FoodEntry] = []
        for f in allFoods.sorted(by: { $0.createdAt > $1.createdAt }) {
            let key = f.name.lowercased()
            guard !f.name.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key); out.append(f)
            if out.count == 8 { break }
        }
        return out
    }

    var body: some View {
        NavigationStack {
            Form {
                if editing == nil, !recent.isEmpty, query.isEmpty {
                    Section {
                        RecentFoodRow(recent: recent) { pick(recent: $0) }
                            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    }
                }

                if editing == nil {
                    Section {
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                            TextField("Search foods — e.g. banana, dal, roti", text: $query)
                                .focused($searchFocused)
                                .autocorrectionDisabled()
                            if !query.isEmpty {
                                Button { query = "" } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        ForEach(results) { item in
                            Button { pick(item) } label: { libraryRow(item) }
                                .buttonStyle(.plain)
                        }
                        if !query.isEmpty && results.isEmpty {
                            Text("No match — type the calories below instead.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Quick add")
                    }
                }

                if picked != nil {
                    Section {
                        Stepper(value: $servings, in: 0.25...20, step: 0.25) {
                            HStack {
                                Text("Servings")
                                Spacer()
                                Text(servingsLabel).foregroundStyle(.secondary)
                            }
                        }
                        .onChange(of: servings) { _, _ in rescale() }
                    }
                }

                Section(picked == nil ? "What did you eat?" : "Entry") {
                    TextField("Name (optional)", text: $name)
                    numberField("Calories", text: $calories, unit: "kcal")
                }

                Section("Meal") {
                    Picker("Meal", selection: $meal) {
                        ForEach(MealType.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Macros (grams, optional)") {
                    numberField("Protein", text: $protein, unit: "g")
                    numberField("Carbs", text: $carbs, unit: "g")
                    numberField("Fats", text: $fats, unit: "g")
                }
            }
            .navigationTitle(editing == nil ? "Add food" : "Edit food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!isValid).fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func libraryRow(_ item: FoodCatalogItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                Text(item.serving).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(item.calories) kcal")
                .font(.subheadline.weight(.medium)).foregroundStyle(Theme.calorie)
        }
        .contentShape(Rectangle())
    }

    private var servingsLabel: String {
        let n = servings.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(servings)) : String(format: "%.2g", servings)
        return "\(n) × \(picked?.serving ?? "")"
    }

    private func pick(_ item: FoodCatalogItem) {
        Haptics.tap()
        picked = item
        name = item.name
        servings = 1
        rescale()
        query = ""
        searchFocused = false
    }

    /// A recent entry carries no serving size, so it fills the fields as-is.
    private func pick(recent f: FoodEntry) {
        Haptics.tap()
        picked = nil
        name = f.name
        calories = String(f.calories)
        protein = trimmed(f.protein)
        carbs = trimmed(f.carbs)
        fats = trimmed(f.fats)
        searchFocused = false
    }

    /// Recompute the fields from the picked item × servings.
    private func rescale() {
        guard let p = picked else { return }
        calories = String(Int((Double(p.calories) * servings).rounded()))
        protein = trimmed((p.protein * servings * 10).rounded() / 10)
        carbs = trimmed((p.carbs * servings * 10).rounded() / 10)
        fats = trimmed((p.fats * servings * 10).rounded() / 10)
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let e = editing {
            name = e.name
            calories = String(e.calories)
            protein = e.protein == 0 ? "" : trimmed(e.protein)
            carbs = e.carbs == 0 ? "" : trimmed(e.carbs)
            fats = e.fats == 0 ? "" : trimmed(e.fats)
            meal = e.meal
        } else {
            meal = defaultMeal
        }
    }

    private func trimmed(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(v)
    }

    private func numberField(_ label: String, text: Binding<String>, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 90)
            Text(unit).foregroundStyle(.secondary)
        }
    }

    private func save() {
        guard let cal = caloriesValue else { return }
        let p = Double(protein) ?? 0, c = Double(carbs) ?? 0, f = Double(fats) ?? 0
        let cleanName = name.trimmingCharacters(in: .whitespaces)
        if let e = editing {
            e.name = cleanName; e.calories = cal
            e.protein = p; e.carbs = c; e.fats = f; e.meal = meal
        } else {
            context.insert(FoodEntry(day: day, name: cleanName, calories: cal,
                                     protein: p, carbs: c, fats: f, meal: meal))
        }
        Haptics.success()
        dismiss()
    }
}

/// Horizontal strip of recently logged foods, for one-tap re-use in the sheet.
struct RecentFoodRow: View {
    let recent: [FoodEntry]
    /// What a tap does here — the dashboard logs straight away, the sheet prefills.
    var caption = "RECENT · TAP TO RE-USE"
    let onPick: (FoodEntry) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(caption)
                .font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(recent) { f in
                        Button { onPick(f) } label: {
                            VStack(spacing: 2) {
                                Text(f.name).font(.caption2).lineLimit(1)
                                Text("\(f.calories)").font(.caption2.weight(.semibold))
                                    .foregroundStyle(Theme.calorie)
                            }
                            .padding(.horizontal, 12).frame(height: 48)
                            .background(Color(.tertiarySystemFill),
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}
