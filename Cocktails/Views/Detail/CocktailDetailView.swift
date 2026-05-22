import SwiftUI
import SwiftData

struct CocktailDetailView: View {
    @Environment(\.dismiss) private var dismiss

    private let cocktail: Cocktail
    @State private var draft: CocktailDraft
    @State private var backgroundColor: Color?
    @State private var showEdit = false
    @State private var cocktailWasDeleted = false

    init(cocktail: Cocktail) {
        self.cocktail = cocktail
        self._draft = State(initialValue: CocktailDraft(from: cocktail))
    }

    var body: some View {
        let regularIngredients = draft.ingredients.filter { $0.role == .core }.sorted { $0.sortOrder < $1.sortOrder }
        let garnishIngredients = draft.ingredients.filter { $0.role == .garnish }.sorted { $0.sortOrder < $1.sortOrder }

        ScrollView {
            VStack(spacing: 18) {
                imageSection
                titleSection
                propertiesPill
                ingredientListCard(regularIngredients)
                ingredientListCard(garnishIngredients, title: "Garnish", hideWhenEmpty: true)
                notesCard
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .scrollContentBackground(.hidden)
        .onAppear {
            backgroundColor = draft.displayImage.dominantColor(placeholderName: draft.glass.imageNameFilled)
        }
        .sheet(isPresented: $showEdit, onDismiss: {
            if cocktailWasDeleted {
                dismiss()
                return
            }
            draft = CocktailDraft(from: cocktail)
            backgroundColor = draft.displayImage.dominantColor(placeholderName: draft.glass.imageNameFilled)
        }) {
            NavigationStack {
                CocktailEditView(cocktail: cocktail, onDelete: { cocktailWasDeleted = true })
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .background { CocktailGradientBackground(backgroundColor: backgroundColor) }
        .toolbar { toolbarContent }
    }

    // MARK: - View Components

    @ViewBuilder
    private var imageSection: some View {
        if draft.displayImage.isCustom {
            draft.displayImage.view(placeholder: draft.glass.imageNameFilled)
                .scaledToFill()
                .frame(width: 140, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .padding(8)
                .glassEffect(in: RoundedRectangle(cornerRadius: 40, style: .continuous))
                .padding(.top, 12)
                .padding(.bottom, 8)
        } else {
            draft.displayImage.view(placeholder: draft.glass.imageNameFilled)
                .scaledToFit()
                .frame(width: 110, height: 110)
                .padding(12)
        }
    }

    @ViewBuilder
    private var titleSection: some View {
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
    private var propertiesPill: some View {
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
    private func ingredientListCard(_ ingredients: [RecipeIngredientDraft], title: LocalizedStringKey = "Ingredients", hideWhenEmpty: Bool = false) -> some View {
        if !hideWhenEmpty || !ingredients.isEmpty {
            CocktailSectionCard(title: title) {
                if !ingredients.isEmpty {
                    VStack(spacing: 16) {
                        ForEach(ingredients) { ingredientRow(for: $0) }
                    }
                } else {
                    Text("No ingredients provided.")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var notesCard: some View {
        CocktailSectionCard(title: "Notes") {
            if !draft.notes.isEmpty {
                Text(draft.notes)
                    .lineSpacing(6)
            } else {
                Text("No instructions provided.")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Close", systemImage: "chevron.down") { dismiss() }
        }
        ToolbarItem(placement: .automatic) {
            if let shareItem = CocktailTransferable(cocktail: cocktail) {
                ShareLink(item: shareItem, preview: SharePreview(cocktail.name, image: Image(cocktail.glass.imageNameEmpty)))
            }
        }
        
        ToolbarSpacer()
        
        ToolbarItem(placement: .confirmationAction) {
            Button("Edit", systemImage: "pencil") { showEdit = true }
        }
    }

    private func ingredientRow(for ingredient: RecipeIngredientDraft) -> some View {
        HStack(spacing: 12) {
            ingredient.ingredient.displayImage.view(placeholder: ingredient.ingredient.type.imageName)
                .scaledToFit()
                .frame(width: 30, height: 30)

            HStack(alignment: .center, spacing: 6) {
                let amountText = ingredient.unit == .fill
                    ? ingredient.unit.displayText(for: 0)
                    : ((ingredient.amount ?? 0) > 0 ? ingredient.unit.displayText(for: ingredient.amount ?? 0) : "")
                if !amountText.isEmpty {
                    Text(amountText)
                        .bold()
                        .fontDesign(.rounded)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(ingredient.ingredient.localizedName)
                    if !ingredient.note.isEmpty {
                        Text(ingredient.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        }
    }
}

#Preview(traits: .sampleData) {
    NavigationStack {
        CocktailDetailView(cocktail: PreviewSampleData.mockCocktail)
    }
}
