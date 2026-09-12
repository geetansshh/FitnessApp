import Foundation
import SwiftData

/// The food table the Add-food sheet searches. Rows live in SwiftData and the
/// search runs as a fetch with a predicate — the bundled list is only the seed
/// for a first launch with no server reachable.
enum FoodCatalog {
    /// Fill an empty cache from the bundled seed so search works before any sync.
    static func seedIfEmpty(_ context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<FoodCatalogItem>())) ?? 0
        guard count == 0 else { return }
        for item in FoodSeed.all { context.insert(item.asCatalogItem) }
        try? context.save()
    }

    /// Pull the server's table and upsert it over the cache.
    static func refresh(_ context: ModelContext, client: APIClient) async throws {
        let items = try await client.foodCatalog()
        guard !items.isEmpty else { return }   // never wipe the cache over an empty response
        for dto in items {
            context.insert(FoodCatalogItem(id: dto.id, name: dto.name, serving: dto.serving,
                                           calories: dto.calories, protein: dto.protein,
                                           carbs: dto.carbs, fats: dto.fats))
        }
        try context.save()
    }

    /// Case/diacritic-insensitive DB search, prefix matches first.
    static func search(_ query: String, in context: ModelContext, limit: Int = 12) -> [FoodCatalogItem] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        var d = FetchDescriptor<FoodCatalogItem>(
            predicate: #Predicate { $0.name.localizedStandardContains(q) },
            sortBy: [SortDescriptor(\.name)])
        d.fetchLimit = limit * 3   // room to rank before trimming
        let hits = (try? context.fetch(d)) ?? []
        let lower = q.lowercased()
        return Array(hits.sorted {
            let a = $0.name.lowercased().hasPrefix(lower), b = $1.name.lowercased().hasPrefix(lower)
            return a == b ? $0.name.count < $1.name.count : a
        }.prefix(limit))
    }
}

#if DEBUG
extension FoodCatalog {
    /// ponytail: one runnable check for seeding + search ranking, on a throwaway store.
    static func selfCheck() {
        guard let container = try? ModelContainer(
            for: FoodCatalogItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)) else {
            return assertionFailure("in-memory container failed")
        }
        let context = ModelContext(container)
        seedIfEmpty(context)
        assert((try? context.fetchCount(FetchDescriptor<FoodCatalogItem>())) ?? 0 > 50, "seed did not land")
        assert(search("", in: context).isEmpty, "empty query -> no results")
        assert(search("banana", in: context).first?.calories == 105, "banana lookup failed")
        assert(search("egg", in: context).first?.name.hasPrefix("Egg") == true, "prefix should rank first")
        assert(search("zzzzz", in: context).isEmpty, "unknown food -> no results")
    }
}
#endif
