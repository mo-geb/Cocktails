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

                    Group {
                        if let footerLabel {
                            Text(footerLabel)
                        } else {
                            CocktailMetaLine(glass: cocktail.glass, ice: cocktail.ice, method: cocktail.method)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1, accessibility: 2)
                    .minimumScaleFactor(0.8)
                }
                .padding(8)
                .padding(.bottom, 6)
            }
            .frame(maxWidth: .infinity)
            .cardBackground(cornerRadius: cornerRadius)
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

/// "Martini · No Ice · Shake": the summary under a cocktail's name in grid cells,
/// mirroring the glass / ice / method pill on the detail view.
struct CocktailMetaLine: View {
    let glass: GlassType
    let ice: IceType
    let method: PreparationMethod

    var body: some View {
        Text(verbatim: [glass.localizedName, ice.localizedName, method.localizedName].joined(separator: " · "))
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
                .font(.caption)
                .foregroundStyle(.tint)
        }
        .padding(8)
        .padding(.bottom, 6)
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity)
        .cardBackground(cornerRadius: 22)
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

