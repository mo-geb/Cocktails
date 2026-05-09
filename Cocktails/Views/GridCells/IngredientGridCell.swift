import SwiftUI

struct IngredientGridCell: View {
    let ingredient: Ingredient

    @State private var backgroundColor: Color?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            if let backgroundColor {
                LinearGradient(
                    colors: [backgroundColor, backgroundColor.opacity(0.15)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .saturation(1.9)
                .blendMode(colorScheme == .dark ? .screen : .normal)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

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
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.85, contentMode: .fit)
        .glassEffect(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .task {
            let color = await ingredient.displayImage.dominantColor(
                placeholderName: ingredient.type.imageName,
                cacheKey: ingredient.id
            )
            withAnimation(.easeInOut(duration: 0.6)) {
                backgroundColor = color
            }
        }
    }
}
