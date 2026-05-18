import Foundation

extension Array where Element == Ingredient {
    func groupedByType() -> [(IngredientType, [Ingredient])] {
        let groups = Dictionary(grouping: self) { $0.type }
        return IngredientType.allCases.compactMap { type in
            guard let items = groups[type], !items.isEmpty else { return nil }
            return (type, items)
        }
    }
}

extension Set {
    mutating func toggle(_ element: Element) {
        if contains(element) { remove(element) } else { insert(element) }
    }
}
