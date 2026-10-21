import UIKit
import SwiftUI

extension View {
    /// A solid content card for use on a grouped background. Glass is reserved
    /// for controls and navigation, which float above content.
    func cardBackground(cornerRadius: CGFloat = 24) -> some View {
        background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    func dismissKeyboardOnTap() -> some View {
        onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }

    func sectionTitleStyle() -> some View {
        font(.title3.bold())
    }

    /// Pushes the cocktail detail screen with the shared zoom transition.
    /// Pair with `.matchedTransitionSource(id:in:)` on the source cell.
    func cocktailZoomDestination(_ item: Binding<Cocktail?>, in namespace: Namespace.ID) -> some View {
        navigationDestination(item: item) { cocktail in
            CocktailDetailView(cocktail: cocktail)
                .navigationTransition(.zoom(sourceID: cocktail.id, in: namespace))
        }
    }

    /// Reports a `restore()` outcome that needs acknowledgement. Success is
    /// silent — the entitlement change is its own feedback.
    func restoreOutcomeAlert(_ store: StoreManager) -> some View {
        let outcome = Binding(get: { store.restoreOutcome },
                              set: { store.restoreOutcome = $0 })
        return alert("Restore Purchases", isPresented: .init(presence: outcome)) {
            Button("OK") {}
        } message: {
            Text(store.restoreOutcome == .failed
                 ? "Couldn't reach the App Store. Check your connection and try again."
                 : "No previous purchase was found for this Apple Account.")
        }
    }

    func importResultAlerts(result: Binding<ImportResult?>, error: Binding<String?>) -> some View {
        alert("Import Complete", isPresented: .init(presence: result)) {
            Button("OK") { result.wrappedValue = nil }
        } message: {
            if let r = result.wrappedValue {
                Text("\(r.cocktailsInserted) cocktails imported.")
            }
        }
        .alert("Import Failed", isPresented: .init(presence: error)) {
            Button("OK") { error.wrappedValue = nil }
        } message: {
            if let e = error.wrappedValue { Text(e) }
        }
    }
}

extension Color {
    /// The drink-derived fill behind artwork: keeps the hue but normalizes
    /// saturation/brightness so no extracted colour reads harsh or muddy, and
    /// near-greyscale colours stay neutral. Dark mode uses a deeper, more
    /// saturated shade, because a dimmed pastel over a
    /// dark card loses its hue and reads as brown.
    func adaptiveTint(lightOpacity: Double, darkOpacity: Double) -> Color {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let isNeutral = s < 0.1
        return Color(UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return isNeutral
                    ? UIColor(white: 0.5, alpha: darkOpacity)
                    : UIColor(hue: h, saturation: 0.7, brightness: 0.6, alpha: darkOpacity)
            }
            return isNeutral
                ? UIColor(white: 0.7, alpha: lightOpacity)
                : UIColor(hue: h, saturation: 0.5, brightness: 0.85, alpha: lightOpacity)
        })
    }
}

extension Binding where Value == Bool {
    /// True while `item` is non-nil; setting it to false (dismissal) resets the item.
    init<T>(presence item: Binding<T?>) {
        self.init(
            get: { item.wrappedValue != nil },
            set: { if !$0 { item.wrappedValue = nil } }
        )
    }
}

// MARK: - Dynamic Type

/// A square frame that grows with the user's text size, for icons that sit
/// next to text of the given style.
private struct ScaledFrame: ViewModifier {
    @ScaledMetric private var side: CGFloat

    init(_ side: CGFloat, relativeTo style: Font.TextStyle) {
        _side = ScaledMetric(wrappedValue: side, relativeTo: style)
    }

    func body(content: Content) -> some View {
        content.frame(width: side, height: side)
    }
}

/// Keeps compact layouts to `limit` lines, but lets text wrap further at
/// accessibility sizes instead of truncating.
private struct AdaptiveLineLimit: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let limit: Int
    let accessibilityLimit: Int

    func body(content: Content) -> some View {
        content.lineLimit(dynamicTypeSize.isAccessibilitySize ? accessibilityLimit : limit)
    }
}

extension View {
    func scaledFrame(_ side: CGFloat, relativeTo style: Font.TextStyle = .body) -> some View {
        modifier(ScaledFrame(side, relativeTo: style))
    }

    func lineLimit(_ limit: Int, accessibility accessibilityLimit: Int) -> some View {
        modifier(AdaptiveLineLimit(limit: limit, accessibilityLimit: accessibilityLimit))
    }
}
