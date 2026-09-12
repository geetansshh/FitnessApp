import Foundation
import SwiftData

/// One row of the searchable food table, cached locally. The server's
/// `food_catalog` table is the source of truth; this is a copy so search still
/// works offline. `id` is unique, so a refresh upserts instead of duplicating.
@Model
final class FoodCatalogItem {
    @Attribute(.unique) var id: String
    var name: String
    var serving: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fats: Double

    init(id: String, name: String, serving: String, calories: Int,
         protein: Double, carbs: Double, fats: Double) {
        self.id = id
        self.name = name
        self.serving = serving
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
    }
}
