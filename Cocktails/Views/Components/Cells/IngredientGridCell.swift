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
            // Flattens icon and text into one layer so they move together when the
            // stocked-first sort repositions the cell; the icon's grayscale filter
            // otherwise renders it separately and it lags behind the text.
            .compositingGroup()
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

    var body: some View {
        VStack(spacing: 0) {
            art()
                .grayscale(isDimmed ? 1 : 0)
                .opacity(isDimmed ? 0.35 : 1)

            Text(name)
                .font(.caption.bold())
                .foregroundStyle(isDimmed ? .secondary : .primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
        }
        .padding(.all, 4)
        .frame(maxWidth: .infinity)
        .aspectRatio(0.85, contentMode: .fit)
        .cardBackground(cornerRadius: 18)
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
