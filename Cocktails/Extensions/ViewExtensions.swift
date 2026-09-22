import UIKit
import SwiftUI

extension View {
    func glassCard() -> some View {
        glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
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
            .fontDesign(.rounded)
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
    /// A consistent pill tint derived from a drink's dominant colour: keeps the
    /// hue but normalizes saturation/brightness so no extracted colour reads
    /// harsh or muddy. Near-greyscale colours stay neutral. Apply at low opacity
    /// so it adapts to light/dark.
    func normalizedTint() -> Color {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        guard s >= 0.1 else { return Color(hue: 0, saturation: 0, brightness: 0.7) }
        return Color(hue: h, saturation: 0.5, brightness: 0.85)
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
