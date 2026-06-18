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
            VStack(spacing: 0) {
                ingredient.displayImage.view(placeholder: ingredient.type.imageName)
                    .scaledToFit()
                    .padding(4)

                Text(ingredient.localizedName)
                    .font(.caption.bold())
                    .fontDesign(.rounded)
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
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color(.separator), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .grayscale(ingredient.isStocked ? 0 : 1)
            .opacity(ingredient.isStocked ? 1 : 0.4)
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

func addIngredientCell(name: String) -> some View {
    VStack(spacing: 0) {
        Image(systemName: "plus.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.tint)
            .padding(12)

        Text(name)
            .font(.caption.bold())
            .fontDesign(.rounded)
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
    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    .overlay {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(Color.accentColor.opacity(0.55), lineWidth: 1.5)
    }
}

#Preview(traits: .sampleData) {
    let ingredients = try! PreviewSampleData.container.mainContext.fetch(FetchDescriptor<Ingredient>())
    ScrollView {
        LazyVGrid(columns: GridColumns.ingredients, spacing: 10) {
            ForEach(ingredients) { ingredient in
                IngredientGridCell(ingredient: ingredient)
            }
            addIngredientCell(name: "New")
        }
        .padding()
    }
}
