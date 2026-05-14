import SwiftUI

struct IngredientGridCell: View {
    let ingredient: Ingredient
    var onEdit: (() -> Void)? = nil

    var body: some View {
        Button {
            ingredient.isStocked.toggle()
        } label: {
            VStack(spacing: 0) {
                ingredient.displayImage.view(placeholder: ingredient.type.imageName)
                    .scaledToFit()
                    .padding(4)

                Text(ingredient.name)
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
            .glassEffect(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .grayscale(ingredient.isStocked ? 0 : 1)
            .opacity(ingredient.isStocked ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                ingredient.isStocked.toggle()
            } label: {
                Label(ingredient.isStocked ? "Mark as Unstocked" : "Mark as Stocked",
                      systemImage: ingredient.isStocked ? "minus.circle" : "checkmark.circle")
            }
            Button {
                onEdit?()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
        }
    }
}

func ingredientAddCellLabel(name: String) -> some View {
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
    .glassEffect(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    .overlay {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(.tint.opacity(0.55), lineWidth: 1.5)
    }
}

import SwiftData

#Preview {
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    let ingredients = try! PreviewSampleData.container.mainContext.fetch(FetchDescriptor<Ingredient>())
    ScrollView {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(ingredients) { ingredient in
                IngredientGridCell(ingredient: ingredient)
            }
            ingredientAddCellLabel(name: "New")
        }
        .padding()
    }
    .modelContainer(PreviewSampleData.container)
}
