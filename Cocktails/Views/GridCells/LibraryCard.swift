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
                        .glassEffect()
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
        .onAppear {
            if let uiImage = UIImage(named: source.imageName) {
                accentColor = uiImage.dominantColor().map { Color($0) }
            }
        }
    }
}

