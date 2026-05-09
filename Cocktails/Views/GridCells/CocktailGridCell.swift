import SwiftUI

struct CocktailGridCell: View {
    let cocktail: Cocktail
    var footerLabel: String? = nil
    let onTap: () -> Void

    @State private var backgroundColor: Color?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                if let backgroundColor {
                    LinearGradient(
                        colors: [backgroundColor, backgroundColor.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .saturation(1.9)
                    .blendMode(colorScheme == .dark ? .screen : .normal)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }

                VStack(spacing: 0) {
                    Spacer()

                    cocktail.displayImage.view(placeholder: cocktail.glass.imageNameFilled)
                        .scaledToFit()
                        .padding(.horizontal, 40)

                    Spacer()

                    VStack(spacing: 6) {
                        Text(cocktail.name)
                            .font(.subheadline.bold())
                            .fontDesign(.rounded)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)

                        HStack(spacing: 4) {
                            Image(cocktail.source.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                            Text(cocktail.source.localizedName)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)

                        Group {
                            if let footerLabel {
                                Text(footerLabel)
                                    .frame(maxWidth: .infinity)
                            } else {
                                HStack(spacing: 0) {
                                    HStack(spacing: 5) {
                                        Image(cocktail.ice.imageName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 12, height: 12)
                                        Text(cocktail.ice.localizedName)
                                    }
                                    .frame(maxWidth: .infinity)

                                    Divider().frame(height: 12)

                                    HStack(spacing: 5) {
                                        Image(cocktail.method.customImageName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 12, height: 12)
                                        Text(cocktail.method.localizedName)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .glassEffect()
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 14)
                }

                if cocktail.isFavourite {
                    Image(systemName: "star.fill")
                        .font(.title)
                        .foregroundStyle(.yellow)
                        .padding(12)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(0.85, contentMode: .fit)
            .glassEffect(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(CardPressStyle())
        .contextMenu {
            Button {
                cocktail.isFavourite.toggle()
            } label: {
                Label(
                    cocktail.isFavourite ? "Remove from Favourites" : "Add to Favourites",
                    systemImage: cocktail.isFavourite ? "star.slash" : "star"
                )
            }
        }
        .onAppear {
            backgroundColor = cocktail.displayImage.dominantColor(placeholderName: cocktail.glass.imageNameFilled)
        }
    }
}

private struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.06 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
