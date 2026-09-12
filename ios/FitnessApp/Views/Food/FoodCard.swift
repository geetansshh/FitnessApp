import SwiftUI
import SwiftData

/// The day's food log, inline on Today. All four meals always show as collapsed
/// rows so the card's height stays predictable; one opens at a time, and each row
/// carries its own repeat/delete menu.
struct DayFoodCard: View {
    let dayKey: String
    /// The selected day's entries (filtered by the caller).
    let foods: [FoodEntry]

    @Environment(\.modelContext) private var context
    @State private var editing: FoodEntry?
    /// One meal open at a time — that is what bounds the card's height.
    @State private var expanded: MealType? = .suggested()

    private var totalCalories: Int { foods.reduce(0) { $0 + $1.calories } }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.stack) {
            CardTitle("Food", accessory: foods.isEmpty ? nil : "\(totalCalories) kcal")

            if foods.isEmpty {
                EmptyHint(icon: "fork.knife", title: "Nothing logged yet",
                          message: "Tap + Add food above to start.")
            } else {
                ForEach(MealType.allCases.sorted { $0.sortRank < $1.sortRank }) { meal in
                    mealGroup(meal, foods.filter { $0.meal == meal }
                                        .sorted { $0.createdAt < $1.createdAt })
                }
            }
        }
        .card()
        .sheet(item: $editing) { AddFoodView(day: dayKey, editing: $0) }
    }

    private func mealGroup(_ meal: MealType, _ items: [FoodEntry]) -> some View {
        DisclosureGroup(isExpanded: Binding(
            get: { expanded == meal },
            set: { isOpen in withAnimation(Theme.motion) { expanded = isOpen ? meal : nil } }
        )) {
            ForEach(items) { food in
                HStack(spacing: 4) {
                    Button { editing = food } label: { FoodRow(food: food) }
                        .buttonStyle(.plain)
                    // Visible affordance: swipeActions need a List, and a
                    // long-press-only delete is undiscoverable.
                    Menu { rowActions(food) } label: {
                        Image(systemName: "ellipsis")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 30, height: 34)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Actions for \(food.name.isEmpty ? "food" : food.name)")
                }
                .contextMenu { rowActions(food) }
            }
        } label: {
            HStack {
                Label(meal.label, systemImage: meal.icon)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(items.isEmpty ? "—" : "\(items.reduce(0) { $0 + $1.calories }) kcal")
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
        }
        .disabled(items.isEmpty)   // nothing to open in an empty meal
        .tint(.secondary)
    }

    @ViewBuilder
    private func rowActions(_ food: FoodEntry) -> some View {
        Button { logCopy(of: food) } label: {
            Label("Repeat", systemImage: "plus.square.on.square")
        }
        Button(role: .destructive) { delete(food) } label: {
            Label("Delete", systemImage: "trash")
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

    private func delete(_ food: FoodEntry) {
        Haptics.tap()
        withAnimation(Theme.motion) { context.delete(food) }
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
