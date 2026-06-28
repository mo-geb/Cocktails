import SwiftUI
import SwiftData

struct CocktailGridCell: View {
    let cocktail: Cocktail
    var footerLabel: String? = nil
    var isSelected: Bool = false
    var isSelecting: Bool = false
    var onDelete: (() -> Void)? = nil
    let onTap: () -> Void

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
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
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

                        HStack(spacing: 4) {
                            Image(cocktail.source.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                                .accessibilityHidden(true)
                            Text(cocktail.source.localizedName)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)

                        Group {
                            if let footerLabel {
                                Text(footerLabel)
                            } else {
                                HStack(spacing: 5) {
                                    Image(cocktail.ice.imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 11, height: 11)
                                        .accessibilityHidden(true)
                                    Text(cocktail.ice.localizedName)
                                    Text("·").foregroundStyle(.tertiary)
                                    Image(cocktail.method.customImageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 11, height: 11)
                                        .accessibilityHidden(true)
                                    Text(cocktail.method.localizedName)
                                }
                            }
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background((bgColor ?? .gray).normalizedTint().opacity(0.35), in: Capsule())
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 14)
                }

                if cocktail.isFavourite && !isSelecting {
                    Image(systemName: "star.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.yellow)
                        .accessibilityLabel(Text("Favourite"))
                        .transition(.symbolEffect)
                        .padding(6)
                        .glassEffect(in: Circle())
                        .padding(10)
                }

                if isSelecting {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isSelected ? Color.accentColor : Color.primary.opacity(0.3))
                        .accessibilityLabel(isSelected ? Text("Selected") : Text("Not selected"))
                        .contentTransition(.symbolEffect(.replace))
                        .animation(.default, value: isSelected)
                        .padding(10)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(0.85, contentMode: .fit)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                if let bgColor {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(bgColor.opacity(0.2))
                }
            }
            .task(id: cocktail.id) {
                let image = cocktail.displayImage
                let placeholder = cocktail.glass.imageNameFilled
                bgColor = await Task.detached(priority: .background) {
                    image.dominantColor(placeholderName: placeholder)
                }.value
            }
            .overlay {
                let selected = isSelecting && isSelected
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(selected ? Color.accentColor : Color(.separator),
                                  lineWidth: selected ? 2.5 : 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .accessibilityElement(children: .combine)
        }
        .sensoryFeedback(.selection, trigger: isSelected)
        .sensoryFeedback(.impact(weight: .light), trigger: cocktail.isFavourite)
        .buttonStyle(.plain)
        .contextMenu {
            if !isSelecting {
                Button {
                    withAnimation {
                        cocktail.isFavourite.toggle()
                    }
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
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.55), lineWidth: 1.5)
        }
        .accessibilityElement(children: .combine)
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

