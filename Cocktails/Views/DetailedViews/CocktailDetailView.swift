import SwiftUI
import SwiftData
import PhotosUI

struct CocktailDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var draft: CocktailDraft
    @State private var backgroundColor: Color?

    init(cocktail: Cocktail) {
        self.draft = CocktailDraft(from: cocktail)
    }

    var body: some View {
        let regularIngredients = draft.ingredients.filter { $0.ingredient.type != .garnish }
        let garnishIngredients = draft.ingredients.filter { $0.ingredient.type == .garnish }

        ScrollView {
            VStack(spacing: 18) {
                pictureSectionShowing
                titleSectionShowing
                propertiesPillShowing
                ingredientsSectionShowing(regularIngredients)
                garnishSectionShowing(garnishIngredients)
                instructionsSectionShowing
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .scrollContentBackground(.hidden)
        .onAppear {
            backgroundColor = draft.displayImage.dominantColor(placeholderName: draft.glass.imageNameFilled)
        }
        .background {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                if let backgroundColor {
                    LinearGradient(
                        colors: [backgroundColor, backgroundColor.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .saturation(1.9)
                    .blendMode(colorScheme == .dark ? .screen : .normal)
                    .ignoresSafeArea()
                }
            }
        }
        .toolbar { toolbarContent }
    }

    // MARK: - View Components

    @ViewBuilder
    private var pictureSectionShowing: some View {
        draft.displayImage.view(placeholder: draft.glass.imageNameFilled)
            .scaledToFit()
            .frame(width: 110, height: 110)
            .padding(12)
    }

    @ViewBuilder
    private var titleSectionShowing: some View {
        VStack(spacing: 8) {
            Text(draft.name.isEmpty ? "Unnamed Cocktail" : draft.name)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .padding(.horizontal)

            HStack(spacing: 5) {
                Image(draft.source.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text(draft.source.localizedName)
                    .font(.callout)
                    .fontDesign(.rounded)
            }
            .foregroundStyle(.secondary)
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassEffect()
        }
    }

    @ViewBuilder
    private var propertiesPillShowing: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(draft.glass.imageNameEmpty)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                Text(draft.glass.localizedName)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 16)

            HStack(spacing: 6) {
                Image(draft.ice.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                Text(draft.ice.localizedName)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 16)

            HStack(spacing: 6) {
                Image(draft.method.customImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                Text(draft.method.localizedName)
            }
            .frame(maxWidth: .infinity)
        }
        .font(.subheadline)
        .foregroundColor(.primary)
        .padding(.vertical, 16)
        .glassEffect()
    }

    @ViewBuilder
    private func ingredientsSectionShowing(_ ingredients: [RecipeIngredientDraft]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ingredients")
                .font(.title3.bold())
                .fontDesign(.rounded)

            Divider()

            if !ingredients.isEmpty {
                VStack(spacing: 16) {
                    ForEach(ingredients) { ingredientRow(for: $0) }
                }
            } else {
                Text("No ingredients provided.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .glassEffect(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    @ViewBuilder
    private func garnishSectionShowing(_ garnishes: [RecipeIngredientDraft]) -> some View {
        if !garnishes.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("Garnish")
                    .font(.title3.bold())
                    .fontDesign(.rounded)

                Divider()

                VStack(spacing: 16) {
                    ForEach(garnishes) { ingredientRow(for: $0) }
                }
            }
            .padding(20)
            .glassEffect(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    @ViewBuilder
    private var instructionsSectionShowing: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes")
                .font(.title3.bold())
                .fontDesign(.rounded)

            Divider()

            if !draft.notes.isEmpty {
                Text(draft.notes)
                    .lineSpacing(6)
            } else {
                Text("No instructions provided.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .glassEffect(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Close") { dismiss() }
        }
    }

    private func ingredientRow(for ingredient: RecipeIngredientDraft) -> some View {
        HStack(spacing: 12) {
            ingredient.ingredient.displayImage.view(placeholder: ingredient.ingredient.type.imageName)
                .scaledToFit()
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let amount = ingredient.amount, amount > 0 {
                        let text = ingredient.unit.displayText(for: amount)
                        if !text.isEmpty {
                            Text(text)
                                .bold()
                                .fontDesign(.rounded)
                        }
                    }
                    Text(ingredient.ingredient.name)
                    Spacer()
                }
                if !ingredient.note.isEmpty {
                    Text(ingredient.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CocktailDetailView(cocktail: PreviewSampleData.mockCocktail)
    }
    .modelContainer(PreviewSampleData.container)
}
