import SwiftUI
import SwiftData

/// Food log for the selected day: grouped by meal, with recent one-tap re-log,
/// per-meal add buttons, and swipe to duplicate/delete.
struct FoodLogView: View {
    @Environment(\.modelContext) private var context
    @Environment(DaySelection.self) private var day
    @Query private var allFoods: [FoodEntry]

    @State private var addingMeal: MealType?
    @State private var editing: FoodEntry?

    private var dayKey: String { day.dayKey }
    private var foods: [FoodEntry] { allFoods.filter { $0.day == dayKey } }
    private var totalCalories: Int { foods.reduce(0) { $0 + $1.calories } }

    /// Up to 8 most-recently-logged distinct foods, for one-tap re-logging.
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
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
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

                // Every meal always gets a section with its own "+", so adding to
                // breakfast at 9pm is one tap instead of a picker round-trip.
                ForEach(MealType.allCases.sorted { $0.sortRank < $1.sortRank }) { meal in
                    let items = foods.filter { $0.meal == meal }.sorted { $0.createdAt < $1.createdAt }
                    Section {
                        ForEach(items) { food in
                            Button { editing = food } label: { FoodRow(food: food) }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .leading) {
                                    Button { logCopy(of: food) } label: {
                                        Label("Repeat", systemImage: "plus.square.on.square")
                                    }.tint(Theme.calorie)
                                }
                        }
                        .onDelete { delete(items, $0) }

                        Button { addingMeal = meal } label: {
                            Label("Add to \(meal.label.lowercased())", systemImage: "plus")
                                .font(.subheadline)
                        }
                    } header: {
                        HStack {
                            Text("\(meal.emoji) \(meal.label)")
                            Spacer()
                            if !items.isEmpty {
                                Text("\(items.reduce(0) { $0 + $1.calories }) kcal")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Food")
            .toolbar {
                Button { addingMeal = MealType.suggested() } label: { Image(systemName: "plus") }
            }
            .sheet(item: $addingMeal) { meal in
                AddFoodView(day: dayKey, defaultMeal: meal)
            }
            .sheet(item: $editing) { food in
                AddFoodView(day: dayKey, editing: food)
            }
        }
    }

    private func logCopy(of f: FoodEntry) {
        Haptics.success()
        withAnimation(Theme.motion) {
            context.insert(FoodEntry(day: dayKey, name: f.name, calories: f.calories,
                                     protein: f.protein, carbs: f.carbs, fats: f.fats,
                                     meal: MealType.suggested()))
        }
    }

    private func delete(_ items: [FoodEntry], _ offsets: IndexSet) {
        Haptics.tap()
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
            Text("\(food.calories) kcal")
                .font(.subheadline.weight(.medium).monospacedDigit())
        }
        .contentShape(Rectangle())
    }
}

/// Horizontal strip of recently logged foods for one-tap re-logging.
struct RecentFoodRow: View {
    let recent: [FoodEntry]
    let onPick: (FoodEntry) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("RECENT · TAP TO RE-LOG")
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
