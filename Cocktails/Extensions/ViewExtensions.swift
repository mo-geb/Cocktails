import UIKit
import SwiftUI

extension View {
    func glassCard() -> some View {
        glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    func glassCell() -> some View {
        glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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

extension Binding where Value == Bool {
    /// True while `item` is non-nil; setting it to false (dismissal) resets the item.
    init<T>(presence item: Binding<T?>) {
        self.init(
            get: { item.wrappedValue != nil },
            set: { if !$0 { item.wrappedValue = nil } }
        )
    }
}
