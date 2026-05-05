import SwiftUI
import SwiftData
import PhotosUI

struct CocktailDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    
    // State
    @State private var cocktail: Cocktail?
    @State private var draft: CocktailDraft
    @State private var backgroundColor: Color?
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Construct
    init(cocktail: Cocktail) {
        self.cocktail = cocktail
        self.draft = CocktailDraft(from: cocktail)
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                pictureSectionShowing
                titleSectionShowing
                propertiesPillShowing
                ingredientsSectionShowing
                garnishSectionShowing
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
                        colors: [
                            backgroundColor,
                            backgroundColor.opacity(0.3)
                        ],
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
    
    // MARK: - View Components (Showing)
    
    @ViewBuilder
    private var pictureSectionShowing: some View {
        CocktailDraftImageView(cocktail: draft)
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
    private var ingredientsSectionShowing: some View {
        let regularIngredients = draft.ingredients.filter { $0.ingredient.type != .garnish }
        
        VStack(alignment: .leading, spacing: 16) {
            Text("Ingredients")
                .font(.title3.bold())
                .fontDesign(.rounded)
            
            Divider()
            
            if !regularIngredients.isEmpty {
                VStack(spacing: 16) {
                    ForEach(regularIngredients) { ingredient in
                        ingredientRow(for: ingredient)
                    }
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
    private var garnishSectionShowing: some View {
        let garnishIngredients = draft.ingredients.filter { $0.ingredient.type == .garnish }
        
        if !garnishIngredients.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("Garnish")
                    .font(.title3.bold())
                    .fontDesign(.rounded)
                
                Divider()
                
                VStack(spacing: 16) {
                    ForEach(garnishIngredients) { ingredient in
                        ingredientRow(for: ingredient)
                    }
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
        .glassEffect(in: RoundedRectangle(cornerRadius: 24, style: .continuous))    }
    

    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Close") { dismiss() }
        }
    }
    
    private func ingredientRow(for ingredient: RecipeIngredientDraft) -> some View {
        HStack(spacing: 12) {
            IngredientDraftImageView(ingredient: ingredient.ingredient)
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
