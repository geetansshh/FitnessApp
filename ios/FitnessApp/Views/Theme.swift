import SwiftUI

/// App-wide colors & reusable card styling. Minimal by design.
enum Theme {
    static let calorie = Color.orange
    static let protein = Color(red: 0.31, green: 0.55, blue: 0.95)   // blue
    static let carbs = Color(red: 0.95, green: 0.65, blue: 0.20)     // amber
    static let fats = Color(red: 0.55, green: 0.45, blue: 0.85)      // purple
    static let water = Color(red: 0.25, green: 0.68, blue: 0.90)     // cyan
    static let weight = Color(red: 0.20, green: 0.75, blue: 0.55)    // green
}

/// A large rounded card — the app's primary surface.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

extension View {
    func card() -> some View { Card { self } }
}
