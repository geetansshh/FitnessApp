import SwiftUI
import UIKit

/// App-wide design tokens: color, spacing, radius, elevation, motion.
enum Theme {
    // Palette
    static let calorie = Color(red: 0.98, green: 0.45, blue: 0.16)   // warm orange
    static let protein = Color(red: 0.31, green: 0.55, blue: 0.95)   // blue
    static let carbs = Color(red: 0.95, green: 0.65, blue: 0.20)     // amber
    static let fats = Color(red: 0.55, green: 0.45, blue: 0.85)      // purple
    static let water = Color(red: 0.25, green: 0.68, blue: 0.90)     // cyan
    static let weight = Color(red: 0.16, green: 0.74, blue: 0.52)    // green

    // Spacing scale — use these instead of ad-hoc numbers.
    static let gutter: CGFloat = 16
    static let stack: CGFloat = 14
    static let tight: CGFloat = 6
    static let radius: CGFloat = 22

    /// Ring/bar fills read better as a gradient than a flat stroke.
    static func sweep(_ c: Color) -> AngularGradient {
        AngularGradient(colors: [c.opacity(0.55), c, c], center: .center,
                        startAngle: .degrees(-90), endAngle: .degrees(270))
    }
    static func bar(_ c: Color) -> LinearGradient {
        LinearGradient(colors: [c.opacity(0.75), c], startPoint: .leading, endPoint: .trailing)
    }

    /// One spring for every state change in the app, so motion feels like one system.
    static let motion: Animation = .spring(response: 0.38, dampingFraction: 0.82)
}

/// Tactile confirmation for logging actions — the app's main feedback channel.
enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
}

/// A large rounded card — the app's primary surface.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(Theme.gutter)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}

extension View {
    func card() -> some View { Card { self } }
}

/// Section heading used inside cards: small, quiet, consistent.
struct CardTitle: View {
    let text: String
    var accessory: String?
    init(_ text: String, accessory: String? = nil) { self.text = text; self.accessory = accessory }
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(text).font(.subheadline.weight(.semibold))
            Spacer()
            if let accessory { Text(accessory).font(.caption).foregroundStyle(.secondary) }
        }
    }
}

/// Friendly placeholder for a screen or card with nothing in it yet.
struct EmptyHint: View {
    let icon: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: Theme.tight) {
            Image(systemName: icon).font(.title2).foregroundStyle(.tertiary)
            Text(title).font(.subheadline.weight(.medium))
            Text(message).font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
