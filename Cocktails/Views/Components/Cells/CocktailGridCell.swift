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

    private let cornerRadius: CGFloat = 22
    private let wellArtSize: CGFloat = 116
    private let wellVerticalPadding: CGFloat = 11

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 3) {
                    well
                        .padding(.bottom, 8)

                    Text(cocktail.name)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(1, accessibility: 3)

                    HStack(spacing: 4) {
                        Image(cocktail.source.imageName)
                            .resizable()
                            .scaledToFit()
                            .scaledFrame(12, relativeTo: .caption2)
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
                                    .scaledFrame(11, relativeTo: .caption2)
                                    .accessibilityHidden(true)
                                Text(cocktail.ice.localizedName)
                                Text("·").foregroundStyle(.tertiary)
                                Image(cocktail.method.customImageName)
                                    .resizable()
                                    .scaledToFit()
                                    .scaledFrame(11, relativeTo: .caption2)
                                    .accessibilityHidden(true)
                                Text(cocktail.method.localizedName)
                            }
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1, accessibility: 2)
                    .minimumScaleFactor(0.8)
                }
                .padding(8)
                .padding(.bottom, 6)
            }
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .task(id: cocktail.id) {
                let image = cocktail.displayImage
                let placeholder = cocktail.glass.imageNameFilled
                bgColor = await Task.detached(priority: .background) {
                    image.dominantColor(placeholderName: placeholder)
                }.value
            }
            .overlay {
                if isSelecting && isSelected {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 2.5)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
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

    @ViewBuilder
    private var well: some View {
        CocktailArtWell(
            image: cocktail.displayImage,
            placeholder: cocktail.glass.imageNameFilled,
            tint: bgColor,
            artSize: wellArtSize,
            verticalPadding: wellVerticalPadding
        )
        .overlay(alignment: .topTrailing) {
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.primary.opacity(0.3))
                    .accessibilityLabel(isSelected ? Text("Selected") : Text("Not selected"))
                    .contentTransition(.symbolEffect(.replace))
                    .animation(.default, value: isSelected)
                    .padding(8)
            } else if cocktail.isFavourite {
                Image(systemName: "star.fill")
                    .font(.subheadline)
                    .foregroundStyle(.yellow)
                    .accessibilityLabel(Text("Favourite"))
                    .transition(.symbolEffect)
                    .padding(8)
            }
        }
    }
}

func addCocktailCell(name: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        VStack(spacing: 3) {
            Image(systemName: "plus.circle.fill")
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundStyle(.tint)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(height: 116 + 11 * 2)
                .padding(.bottom, 8)
            Text(name)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(1, accessibility: 3)
            Text("Add Cocktail")
                .font(.caption2)
                .foregroundStyle(.tint)
            // Reserves the height of the meta line below the source row in CocktailGridCell,
            // so this tile's natural height matches its grid neighbors.
            Text(verbatim: " ")
                .font(.caption2)
                .hidden()
        }
        .padding(8)
        .padding(.bottom, 6)
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.55), lineWidth: 1.5)
        }
        .accessibilityElement(children: .combine)
    }
    .buttonStyle(.plain)
}

#Preview(traits: .sampleData) {
    let cocktails = PreviewSampleData.mockCocktails
    cocktails.first?.isFavourite = true
    return ScrollView {
        AdaptiveGrid(.cocktails) {
            ForEach(cocktails) { cocktail in
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
    .background(Color(.systemGroupedBackground))
}

