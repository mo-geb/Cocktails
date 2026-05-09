import SwiftUI

struct LibraryCard: View {
    let source: RecipeSource
    let counts: LibraryCounts

    @Environment(\.colorScheme) private var colorScheme
    @State private var accentColor: Color?

    var body: some View {
        Button(action: {}) {
            ZStack(alignment: .bottom) {
                // Gradient background from source image dominant color
                if let accentColor {
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .saturation(1.9)
                    .blendMode(colorScheme == .dark ? .screen : .normal)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }

                VStack(spacing: 0) {
                    Image(source.imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 12)
                        .padding(.bottom, -16)

                    // Info bar
                    VStack(spacing: 0) {
                        Text(source.localizedName)
                            .font(.headline)
                            .fontDesign(.rounded)
                            .padding(.bottom, 8)

                        HStack(spacing: 0) {
                            HStack(spacing: 5) {
                                Image("Glass/Filled/martini")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 12, height: 12)
                                Text("\(counts.cocktails)")
                            }
                            .frame(maxWidth: .infinity)

                            Divider().frame(height: 12)

                            HStack(spacing: 5) {
                                Image("Ingredient/rum")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 12, height: 12)
                                Text("\(counts.ingredients)")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(0.8, contentMode: .fit)
            .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(CardPressStyle())
        .task {
            let cacheKey = "source-\(source.id)"
            if let cached = await ColorCache.shared.color(for: cacheKey) {
                accentColor = cached
                return
            }

            if let uiImage = UIImage(named: source.imageName) {
                let color = await Task.detached(priority: .userInitiated) {
                    uiImage.dominantColor().map { Color($0) }
                }.value
                
                if let color {
                    await ColorCache.shared.set(color, for: cacheKey)
                }

                withAnimation(.easeInOut(duration: 0.6)) {
                    accentColor = color
                }
            }
        }
    }
}

private struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
