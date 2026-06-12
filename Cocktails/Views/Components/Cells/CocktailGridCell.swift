import SwiftUI
import SwiftData

struct CocktailGridCell: View {
    let cocktail: Cocktail
    var footerLabel: String? = nil
    var isSelected: Bool = false
    var isSelecting: Bool = false
    var onDelete: (() -> Void)? = nil
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var bgColor: Color? = nil

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
                    Spacer()

                    if cocktail.displayImage.isCustom {
                        cocktail.displayImage.view(placeholder: cocktail.glass.imageNameFilled)
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .padding(6)
                            .glassEffect(in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                    } else {
                        cocktail.displayImage.view(placeholder: cocktail.glass.imageNameFilled)
                            .scaledToFit()
                            .padding(.horizontal, 40)
                    }

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

                if cocktail.isFavourite && !isSelecting {
                    Image(systemName: "star.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.yellow)
                        .padding(7)
                        .glassEffect(in: Circle())
                        .padding(10)
                }

                if isSelecting {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isSelected ? Color.accentColor : Color.primary.opacity(0.3))
                        .padding(10)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(0.85, contentMode: .fit)
            .glassCard()
            .background {
                if let bgColor {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(bgColor.opacity(0.18))
                }
            }
            .task(id: cocktail.id) {
                let image = cocktail.displayImage
                let placeholder = cocktail.glass.imageNameFilled
                bgColor = await Task.detached(priority: .background) {
                    await image.dominantColor(placeholderName: placeholder)
                }.value
            }
            .overlay {
                if isSelecting && isSelected {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 2.5)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .sensoryFeedback(.selection, trigger: isSelected)
        .sensoryFeedback(.impact(weight: .light), trigger: cocktail.isFavourite)
        .buttonStyle(.plain)
        .contextMenu {
            if !isSelecting {
                Button {
                    cocktail.isFavourite.toggle()
                } label: {
                    Label(
                        cocktail.isFavourite ? "Remove from Favourites" : "Add to Favourites",
                        systemImage: cocktail.isFavourite ? "star.slash" : "star"
                    )
                }
                if let onDelete {
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
}

func addCocktailCell(name: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.tint)
                .frame(maxWidth: .infinity)
            Spacer()
            VStack(spacing: 4) {
                Text(name)
                    .font(.subheadline.bold())
                    .fontDesign(.rounded)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Text("Add Cocktail")
                    .font(.caption2)
                    .foregroundStyle(.tint)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 14)
        }
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity)
        .aspectRatio(0.85, contentMode: .fit)
        .glassCard()
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.tint.opacity(0.55), lineWidth: 1.5)
        }
    }
    .buttonStyle(.plain)
}

#Preview(traits: .sampleData) {
    ScrollView {
        LazyVGrid(columns: GridColumns.cocktails, spacing: 12) {
            ForEach(PreviewSampleData.mockCocktails) { cocktail in
                CocktailGridCell(cocktail: cocktail, onDelete: {}) {}
            }
            CocktailGridCell(
                cocktail: PreviewSampleData.mockCocktail,
                footerLabel: "Missing: Kahlúa",
                onDelete: {}
            ) {}
            addCocktailCell(name: "New Cocktail") {}
        }
        .padding()
    }
}

