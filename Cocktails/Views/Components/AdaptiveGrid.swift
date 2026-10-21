import SwiftUI

/// The app's card grids. Columns widen at accessibility text sizes so larger
/// text gets room instead of being squeezed into the default column count.
struct AdaptiveGrid<Content: View>: View {
    enum Kind {
        case cocktails, ingredients, libraries
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let kind: Kind
    private let content: Content

    init(_ kind: Kind, @ViewBuilder content: () -> Content) {
        self.kind = kind
        self.content = content()
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth), spacing: spacing)], spacing: spacing) {
            content
        }
    }

    private var minimumWidth: CGFloat {
        let large = dynamicTypeSize.isAccessibilitySize
        switch kind {
        case .cocktails, .libraries: return large ? 300 : 160
        case .ingredients: return large ? 140 : 80
        }
    }

    private var spacing: CGFloat {
        switch kind {
        case .cocktails: 12
        case .ingredients: 10
        case .libraries: 16
        }
    }
}
