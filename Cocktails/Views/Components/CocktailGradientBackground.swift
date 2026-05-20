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
                        backgroundColor,                 backgroundColor.opacity(0.8), backgroundColor.opacity(0.5),
                        backgroundColor.opacity(0.7),    backgroundColor.opacity(0.3), .clear,
                        backgroundColor.opacity(0.2),    .clear,                       .clear
                    ]
                )
                .saturation(1.9)
                .blendMode(colorScheme == .dark ? .screen : .normal)
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.5), value: backgroundColor)
    }
}
