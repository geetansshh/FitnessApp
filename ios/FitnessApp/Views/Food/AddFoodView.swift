import SwiftUI
import SwiftData

/// Add or edit a food entry: name, calories, macros, and meal (#2 edit, #15 meal).
struct AddFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    /// The day the entry belongs to (from the selected date).
    let day: String
    /// nil = create a new entry; non-nil = edit this one.
    var editing: FoodEntry?
    var defaultMeal: MealType = MealType.suggested()

    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fats = ""
    @State private var meal: MealType = .snack
    @State private var loaded = false

    private var caloriesValue: Int? { Int(calories) }
    private var isValid: Bool { (caloriesValue ?? 0) > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("What did you eat?") {
                    TextField("Name (optional)", text: $name)
                    numberField("Calories", text: $calories, unit: "kcal")
                }
                Section("Meal") {
                    Picker("Meal", selection: $meal) {
                        ForEach(MealType.allCases) { Text("\($0.emoji) \($0.label)").tag($0) }
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
                    Button("Save") { save() }.disabled(!isValid)
                }
            }
            .onAppear(perform: load)
        }
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
        dismiss()
    }
}
