import SwiftUI
import SwiftData

/// Food log for the selected day: grouped by meal, with recent one-tap re-log + manual entry.
struct FoodLogView: View {
    @Environment(\.modelContext) private var context
    @Environment(DaySelection.self) private var day
    @Query private var allFoods: [FoodEntry]

    @State private var showAdd = false
    @State private var editing: FoodEntry?

    private var dayKey: String { day.dayKey }
    private var foods: [FoodEntry] { allFoods.filter { $0.day == dayKey } }
    private var totalCalories: Int { foods.reduce(0) { $0 + $1.calories } }

    /// Up to 8 most-recently-logged distinct foods, for one-tap re-logging (#4).
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
            List {
                Section {
                    DateNavBar(selection: day)
                    Text("\(totalCalories) kcal logged")
                        .font(.caption).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                if !recent.isEmpty {
                    Section {
                        RecentFoodRow(recent: recent) { logCopy(of: $0) }
                            .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                    }
                }

                if foods.isEmpty {
                    Section {
                        Text("No food logged for \(day.label.lowercased()). Tap + to add.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(MealType.allCases.sorted { $0.sortRank < $1.sortRank }) { meal in
                        let items = foods.filter { $0.meal == meal }.sorted { $0.createdAt < $1.createdAt }
                        if !items.isEmpty {
                            Section("\(meal.emoji) \(meal.label) · \(items.reduce(0) { $0 + $1.calories }) kcal") {
                                ForEach(items) { food in
                                    Button { editing = food } label: { FoodRow(food: food) }
                                        .buttonStyle(.plain)
                                }
                                .onDelete { delete(items, $0) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Food")
            .toolbar {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
            .sheet(isPresented: $showAdd) {
                AddFoodView(day: dayKey)
            }
            .sheet(item: $editing) { food in
                AddFoodView(day: dayKey, editing: food)
            }
        }
    }

    private func logCopy(of f: FoodEntry) {
        context.insert(FoodEntry(day: dayKey, name: f.name, calories: f.calories,
                                 protein: f.protein, carbs: f.carbs, fats: f.fats,
                                 meal: MealType.suggested()))
    }

    private func delete(_ items: [FoodEntry], _ offsets: IndexSet) {
        for i in offsets { context.delete(items[i]) }
    }
}

struct FoodRow: View {
    let food: FoodEntry
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(food.name.isEmpty ? "Food" : food.name).foregroundStyle(.primary)
                Text("P \(Int(food.protein)) · C \(Int(food.carbs)) · F \(Int(food.fats))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(food.calories) kcal").font(.subheadline.weight(.medium))
        }
    }
}

/// Horizontal strip of recently logged foods for one-tap re-logging.
struct RecentFoodRow: View {
    let recent: [FoodEntry]
    let onPick: (FoodEntry) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("RECENT").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
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
                            .background(Color(.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
