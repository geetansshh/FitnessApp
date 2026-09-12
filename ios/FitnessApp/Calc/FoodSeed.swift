import Foundation

/// Seed rows for the local food table, used only when the cache is empty and no
/// server has been reached yet. The live table is `FoodCatalogItem` in SwiftData,
/// refreshed from the backend's `food_catalog`; search runs there, not here.
///
/// Kept in sync by hand with `backend/internal/repo/food_catalog.json` — the
/// server copy wins the moment sync is on.
struct FoodItem {
    let name: String
    let serving: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fats: Double

    /// Stable id from the name, matching the ids in the backend seed JSON.
    var asCatalogItem: FoodCatalogItem {
        FoodCatalogItem(id: name.lowercased().replacing(#/[^a-z0-9]+/#, with: "-")
                            .trimmingCharacters(in: CharacterSet(charactersIn: "-")),
                        name: name, serving: serving, calories: calories,
                        protein: protein, carbs: carbs, fats: fats)
    }
}

enum FoodSeed {
    static let all: [FoodItem] = [
        // Grains & staples
        .init(name: "Roti / chapati", serving: "1 medium", calories: 104, protein: 3, carbs: 20, fats: 2),
        .init(name: "White rice, cooked", serving: "1 cup", calories: 205, protein: 4, carbs: 45, fats: 0.4),
        .init(name: "Brown rice, cooked", serving: "1 cup", calories: 216, protein: 5, carbs: 45, fats: 1.8),
        .init(name: "Bread, white", serving: "1 slice", calories: 79, protein: 2.7, carbs: 15, fats: 1),
        .init(name: "Bread, whole wheat", serving: "1 slice", calories: 81, protein: 4, carbs: 14, fats: 1.1),
        .init(name: "Oats, dry", serving: "40 g", calories: 152, protein: 5.3, carbs: 27, fats: 2.6),
        .init(name: "Pasta, cooked", serving: "1 cup", calories: 221, protein: 8, carbs: 43, fats: 1.3),
        .init(name: "Poha, cooked", serving: "1 cup", calories: 250, protein: 5, carbs: 45, fats: 6),
        .init(name: "Idli", serving: "1 piece", calories: 58, protein: 2, carbs: 12, fats: 0.4),
        .init(name: "Dosa, plain", serving: "1 piece", calories: 133, protein: 3, carbs: 22, fats: 4),
        .init(name: "Paratha, plain", serving: "1 piece", calories: 260, protein: 5, carbs: 36, fats: 10),
        .init(name: "Quinoa, cooked", serving: "1 cup", calories: 222, protein: 8, carbs: 39, fats: 3.6),

        // Protein
        .init(name: "Egg, whole", serving: "1 large", calories: 72, protein: 6.3, carbs: 0.4, fats: 4.8),
        .init(name: "Egg white", serving: "1 large", calories: 17, protein: 3.6, carbs: 0.2, fats: 0.1),
        .init(name: "Chicken breast, cooked", serving: "100 g", calories: 165, protein: 31, carbs: 0, fats: 3.6),
        .init(name: "Chicken thigh, cooked", serving: "100 g", calories: 209, protein: 26, carbs: 0, fats: 11),
        .init(name: "Mutton curry", serving: "1 cup", calories: 300, protein: 22, carbs: 8, fats: 20),
        .init(name: "Fish, salmon cooked", serving: "100 g", calories: 206, protein: 22, carbs: 0, fats: 12),
        .init(name: "Fish, white cooked", serving: "100 g", calories: 105, protein: 23, carbs: 0, fats: 1.5),
        .init(name: "Prawns, cooked", serving: "100 g", calories: 99, protein: 24, carbs: 0.2, fats: 0.3),
        .init(name: "Paneer", serving: "100 g", calories: 296, protein: 20, carbs: 4, fats: 22),
        .init(name: "Tofu, firm", serving: "100 g", calories: 144, protein: 17, carbs: 3, fats: 9),
        .init(name: "Whey protein", serving: "1 scoop (30 g)", calories: 120, protein: 24, carbs: 3, fats: 1.5),
        .init(name: "Dal, cooked", serving: "1 cup", calories: 198, protein: 12, carbs: 34, fats: 1.5),
        .init(name: "Rajma / kidney beans", serving: "1 cup", calories: 215, protein: 13, carbs: 40, fats: 0.9),
        .init(name: "Chole / chickpeas", serving: "1 cup", calories: 269, protein: 15, carbs: 45, fats: 4),
        .init(name: "Soya chunks, dry", serving: "50 g", calories: 172, protein: 26, carbs: 16, fats: 0.5),

        // Dairy
        .init(name: "Milk, whole", serving: "1 cup", calories: 149, protein: 8, carbs: 12, fats: 8),
        .init(name: "Milk, skim", serving: "1 cup", calories: 83, protein: 8, carbs: 12, fats: 0.2),
        .init(name: "Curd / yogurt, plain", serving: "1 cup", calories: 149, protein: 8.5, carbs: 11, fats: 8),
        .init(name: "Greek yogurt, plain", serving: "170 g", calories: 100, protein: 17, carbs: 6, fats: 0.7),
        .init(name: "Cheese, cheddar", serving: "1 slice (28 g)", calories: 113, protein: 7, carbs: 0.4, fats: 9),
        .init(name: "Butter", serving: "1 tsp", calories: 34, protein: 0, carbs: 0, fats: 3.9),
        .init(name: "Ghee", serving: "1 tsp", calories: 45, protein: 0, carbs: 0, fats: 5),

        // Fruit & veg
        .init(name: "Banana", serving: "1 medium", calories: 105, protein: 1.3, carbs: 27, fats: 0.4),
        .init(name: "Apple", serving: "1 medium", calories: 95, protein: 0.5, carbs: 25, fats: 0.3),
        .init(name: "Orange", serving: "1 medium", calories: 62, protein: 1.2, carbs: 15, fats: 0.2),
        .init(name: "Mango", serving: "1 cup", calories: 99, protein: 1.4, carbs: 25, fats: 0.6),
        .init(name: "Grapes", serving: "1 cup", calories: 104, protein: 1.1, carbs: 27, fats: 0.2),
        .init(name: "Papaya", serving: "1 cup", calories: 62, protein: 0.7, carbs: 16, fats: 0.4),
        .init(name: "Avocado", serving: "1/2 fruit", calories: 161, protein: 2, carbs: 9, fats: 15),
        .init(name: "Mixed salad", serving: "1 bowl", calories: 45, protein: 2, carbs: 8, fats: 0.5),
        .init(name: "Potato, boiled", serving: "1 medium", calories: 130, protein: 3, carbs: 30, fats: 0.2),
        .init(name: "Sweet potato, boiled", serving: "1 medium", calories: 112, protein: 2, carbs: 26, fats: 0.1),
        .init(name: "Mixed vegetable sabzi", serving: "1 cup", calories: 150, protein: 4, carbs: 18, fats: 7),
        .init(name: "Palak paneer", serving: "1 cup", calories: 270, protein: 14, carbs: 12, fats: 19),

        // Nuts, fats, snacks
        .init(name: "Almonds", serving: "10 pieces", calories: 69, protein: 2.5, carbs: 2.6, fats: 6),
        .init(name: "Walnuts", serving: "5 halves", calories: 65, protein: 1.5, carbs: 1.4, fats: 6.5),
        .init(name: "Peanut butter", serving: "1 tbsp", calories: 94, protein: 4, carbs: 3, fats: 8),
        .init(name: "Olive oil", serving: "1 tbsp", calories: 119, protein: 0, carbs: 0, fats: 13.5),
        .init(name: "Cooking oil", serving: "1 tsp", calories: 40, protein: 0, carbs: 0, fats: 4.5),
        .init(name: "Dark chocolate", serving: "25 g", calories: 150, protein: 2, carbs: 12, fats: 10),
        .init(name: "Potato chips", serving: "small pack (30 g)", calories: 160, protein: 2, carbs: 15, fats: 10),
        .init(name: "Biscuit, digestive", serving: "1 piece", calories: 71, protein: 1, carbs: 10, fats: 3),
        .init(name: "Samosa", serving: "1 piece", calories: 262, protein: 4, carbs: 24, fats: 17),

        // Drinks & takeaway
        .init(name: "Tea with milk & sugar", serving: "1 cup", calories: 90, protein: 2, carbs: 12, fats: 3),
        .init(name: "Coffee, black", serving: "1 cup", calories: 2, protein: 0.3, carbs: 0, fats: 0),
        .init(name: "Latte", serving: "regular", calories: 190, protein: 10, carbs: 18, fats: 8),
        .init(name: "Orange juice", serving: "1 cup", calories: 112, protein: 1.7, carbs: 26, fats: 0.5),
        .init(name: "Cola", serving: "330 ml can", calories: 139, protein: 0, carbs: 35, fats: 0),
        .init(name: "Beer", serving: "330 ml", calories: 143, protein: 1.6, carbs: 11, fats: 0),
        .init(name: "Wine, red", serving: "150 ml", calories: 125, protein: 0.1, carbs: 4, fats: 0),
        .init(name: "Pizza slice", serving: "1 slice", calories: 285, protein: 12, carbs: 36, fats: 10),
        .init(name: "Burger", serving: "1 regular", calories: 354, protein: 17, carbs: 29, fats: 19),
        .init(name: "Biryani, chicken", serving: "1 plate", calories: 490, protein: 22, carbs: 60, fats: 18),
        .init(name: "Fried rice", serving: "1 plate", calories: 400, protein: 10, carbs: 60, fats: 13),
        .init(name: "Noodles / chow mein", serving: "1 plate", calories: 380, protein: 10, carbs: 55, fats: 13),
        .init(name: "Sandwich, veg", serving: "1 piece", calories: 250, protein: 8, carbs: 34, fats: 9),
        .init(name: "Protein bar", serving: "1 bar", calories: 210, protein: 20, carbs: 21, fats: 7),
    ]
}
