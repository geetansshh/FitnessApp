import Foundation

/// Optional REST client for the Go backend. The app is fully functional offline with
/// SwiftData; this only powers "backup to server" / future multi-device sync.
///
/// ponytail: push-only backup + health check. Two-way merge with conflict resolution is
/// deferred — add a `pull()` + updatedAt timestamps when multi-device sync is actually needed.
struct APIClient {
    var baseURL: URL
    var userId: String = "local"

    struct APIError: LocalizedError { let message: String; var errorDescription: String? { message } }

    // MARK: DTOs (JSON keys must match internal/models on the Go side)
    struct CalorieTargetRequest: Encodable {
        var age: Int; var sex: String; var heightCm: Double; var weightKg: Double
        var activityLevel: String; var goalType: String
    }
    struct CalorieTargetResponse: Decodable {
        var bmr: Double; var tdee: Int; var calorieTarget: Int
        var protein: Int; var carbs: Int; var fats: Int
    }
    struct ProfileDTO: Codable {
        var name: String; var age: Int; var sex: String
        var heightCm: Double; var weightKg: Double; var goalWeightKg: Double
        var activityLevel: String; var goalType: String
        var calorieTarget: Int; var proteinTarget: Int; var carbsTarget: Int; var fatsTarget: Int
        var waterGoalMl: Int
    }
    struct FoodDTO: Codable {
        var date: String; var name: String; var calories: Int
        var protein: Double; var carbs: Double; var fats: Double
    }
    struct WaterDTO: Codable { var date: String; var amountMl: Int }
    struct WeightDTO: Codable { var date: String; var weightKg: Double }

    // MARK: Requests
    func health() async throws {
        _ = try await sendRaw(path: "/healthz", method: "GET", body: Optional<Int>.none)
    }

    func calorieTarget(_ req: CalorieTargetRequest) async throws -> CalorieTargetResponse {
        try await send(path: "/api/v1/calorie-target", method: "POST", body: req)
    }

    func putProfile(_ p: ProfileDTO) async throws {
        _ = try await sendRaw(path: "/api/v1/profile", method: "PUT", body: p)
    }
    func postFood(_ f: FoodDTO) async throws {
        _ = try await sendRaw(path: "/api/v1/food", method: "POST", body: f)
    }
    func postWater(_ w: WaterDTO) async throws {
        _ = try await sendRaw(path: "/api/v1/water", method: "POST", body: w)
    }
    func postWeight(_ w: WeightDTO) async throws {
        _ = try await sendRaw(path: "/api/v1/weight", method: "POST", body: w)
    }

    // MARK: Transport
    private func makeRequest<B: Encodable>(path: String, method: String, body: B?) throws -> URLRequest {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(userId, forHTTPHeaderField: "X-User-Id")
        if let body { req.httpBody = try JSONEncoder().encode(body) }
        return req
    }

    /// Decoding variant.
    private func send<B: Encodable, R: Decodable>(path: String, method: String, body: B?) async throws -> R {
        let data = try await sendRaw(path: path, method: method, body: body)
        return try JSONDecoder().decode(R.self, from: data)
    }

    /// Raw-data variant.
    private func sendRaw<B: Encodable>(path: String, method: String, body: B?) async throws -> Data {
        let req = try makeRequest(path: path, method: method, body: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw APIError(message: "No response") }
        guard (200..<300).contains(http.statusCode) else {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
                ?? "HTTP \(http.statusCode)"
            throw APIError(message: msg)
        }
        return data
    }
}
