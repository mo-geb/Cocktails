import SwiftUI

struct CocktailGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    let backgroundColor: Color?

    var body: some View {
        ZStack {
            Color(.systemBackground)

            if let backgroundColor {
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        .init(0.0, 0.0), .init(0.5, 0.0), .init(1.0, 0.0),
                        .init(0.0, 0.5), .init(0.7, 0.4), .init(1.0, 0.5),
                        .init(0.0, 1.0), .init(0.5, 1.0), .init(1.0, 1.0)
                    ],
                    colors: [
                        backgroundColor.opacity(0.3),    backgroundColor.opacity(0.25), backgroundColor.opacity(0.15),
                        backgroundColor.opacity(0.2),    backgroundColor.opacity(0.1),  .clear,
                        backgroundColor.opacity(0.07),   .clear,                        .clear
                    ]
                )
                .blendMode(colorScheme == .dark ? .screen : .normal)
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.5), value: backgroundColor)
    }
}
