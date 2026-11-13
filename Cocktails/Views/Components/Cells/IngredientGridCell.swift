import SwiftUI
import SwiftData

struct IngredientGridCell: View {
    let ingredient: Ingredient
    var onShowCocktails: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    var body: some View {
        Button {
            ingredient.isStocked.toggle()
        } label: {
            IngredientCard(name: ingredient.localizedName, isDimmed: !ingredient.isStocked) {
                ingredient.displayImage.view(placeholder: ingredient.type.imageName)
                    .scaledToFit()
                    .padding(4)
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            // Rasterize the visual label so text, artwork, and background move
            // as one image when the grid reorders stocked ingredients.
            .drawingGroup()
            .accessibilityElement(children: .combine)
            .accessibilityValue(ingredient.isStocked ? Text("Stocked") : Text("Not stocked"))
            .accessibilityHint(Text("Toggles whether you have this ingredient."))
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: ingredient.isStocked)
        .buttonStyle(.plain)
        .contextMenu {
            if let onShowCocktails {
                Button(action: onShowCocktails) {
                    Label("View Cocktails", systemImage: "wineglass")
                }
            }
            Button {
                onEdit?()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

/// The ingredient tile used across the app: artwork above a name on a white
/// card. Unstocked ingredients are dimmed.
struct IngredientCard<Art: View>: View {
    let name: String
    var isDimmed = false
    @ViewBuilder var art: () -> Art
    @ScaledMetric(relativeTo: .caption) private var contentHeight: CGFloat = 84

    var body: some View {
        IngredientCardLayout(contentHeight: contentHeight) {
            art()
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .grayscale(isDimmed ? 1 : 0)
                .opacity(isDimmed ? 0.35 : 1)

            Text(name)
                .font(.caption.bold())
                .foregroundStyle(isDimmed ? .secondary : .primary)
                .multilineTextAlignment(.center)
                // Let localized names grow vertically at every text size.
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
        }
        .padding(.all, 4)
        .frame(maxWidth: .infinity)
        .cardBackground(cornerRadius: 18)
    }
}

/// Gives the name its full height and the artwork the remaining space.
/// Only exceptionally long names grow beyond the shared compact card height.
private struct IngredientCardLayout: Layout {
    let contentHeight: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 72
        let textSize = subviews[1].sizeThatFits(ProposedViewSize(width: width, height: nil))
        return CGSize(width: width, height: max(contentHeight, textSize.height + 20))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let textSize = subviews[1].sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
        let artHeight = max(0, bounds.height - textSize.height)
        subviews[0].place(
            at: CGPoint(x: bounds.midX, y: bounds.minY),
            anchor: .top,
            proposal: ProposedViewSize(width: bounds.width, height: artHeight)
        )
        subviews[1].place(
            at: CGPoint(x: bounds.minX, y: bounds.minY + artHeight),
            anchor: .topLeading,
            proposal: ProposedViewSize(width: bounds.width, height: textSize.height)
        )
    }
}

/// The tile offered when a search matches no ingredient, for creating one.
func addIngredientCell(name: String) -> some View {
    IngredientCard(name: name) {
        Image(systemName: "plus.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.tint)
            .padding(12)
    }
    .overlay {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(Color.accentColor.opacity(0.55), lineWidth: 1.5)
    }
}

#Preview(traits: .sampleData) {
    let ingredients = try! PreviewSampleData.container.mainContext.fetch(FetchDescriptor<Ingredient>())
    ingredients.prefix(3).forEach { $0.isStocked = true }
    return ScrollView {
        AdaptiveGrid(.ingredients) {
            ForEach(ingredients) { ingredient in
                IngredientGridCell(ingredient: ingredient)
            }
            addIngredientCell(name: "New")
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
