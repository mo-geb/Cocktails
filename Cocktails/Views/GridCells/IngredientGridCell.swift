import SwiftUI

struct IngredientGridCell: View {
    let ingredient: Ingredient

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
            .grayscale(ingredient.isStocked ? 0 : 1)
            .opacity(ingredient.isStocked ? 1 : 0.4)
        }
        .buttonStyle(.plain)
    }
}
