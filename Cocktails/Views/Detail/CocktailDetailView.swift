import SwiftUI
import SwiftData
import StoreKit

struct CocktailDetailView: View {
    @Environment(\.requestReview) private var requestReview

    private let cocktail: Cocktail
    private let onDone: (() -> Void)?
    @State private var draft: CocktailDraft
    @State private var backgroundColor: Color?
    @State private var isEditing = false

    init(cocktail: Cocktail, onDone: (() -> Void)? = nil) {
        self.cocktail = cocktail
        self.onDone = onDone
        let draft = CocktailDraft(from: cocktail)
        self._draft = State(initialValue: draft)
        // Seed before the first frame so the mesh doesn't fade in from nil
        // while the zoom transition is still settling.
        self._backgroundColor = State(initialValue: draft.displayImage.dominantColor(placeholderName: draft.glass.imageNameFilled))
    }

    var body: some View {
        Group {
            if isEditing {
                CocktailEditView(cocktail: cocktail, backgroundColor: $backgroundColor, onFinish: finishEditing)
                    .transition(.opacity)
            } else {
                detailView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isEditing)
        .background { CocktailGradientBackground(backgroundColor: backgroundColor) }
    }

    /// Refreshes the cached draft from the (now-edited) model and returns to the
    /// detail view — keeps everything inside the one presented sheet.
    private func finishEditing() {
        draft = CocktailDraft(from: cocktail)
        backgroundColor = draft.displayImage.dominantColor(placeholderName: draft.glass.imageNameFilled)
        isEditing = false
    }

    private var detailView: some View {
        let regularIngredients = draft.ingredients.filter { $0.role == .core }.sorted { $0.sortOrder < $1.sortOrder }
        let garnishIngredients = draft.ingredients.filter { $0.role == .garnish }.sorted { $0.sortOrder < $1.sortOrder }

        return ScrollView {
            GlassEffectContainer(spacing: 18) {
                VStack(spacing: 18) {
                    imageSection
                    titleSection
                    propertiesPill
                    ingredientListCard(regularIngredients)
                    ingredientListCard(garnishIngredients, title: "Garnish", hideWhenEmpty: true)
                    if !draft.notes.isEmpty { notesCard }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .scrollContentBackground(.hidden)
        .task {
            if ReviewManager.recordCocktailViewed() {
                try? await Task.sleep(for: .seconds(1))
                requestReview()
            }
        }
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
                .font(.system(.largeTitle, design: .rounded).bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 5) {
                Image(draft.source.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .accessibilityHidden(true)
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
                    .accessibilityHidden(true)
                Text(draft.glass.localizedName)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 16)

            HStack(spacing: 6) {
                Image(draft.ice.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .accessibilityHidden(true)
                Text(draft.ice.localizedName)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 16)

            HStack(spacing: 6) {
                Image(draft.method.customImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .accessibilityHidden(true)
                Text(draft.method.localizedName)
            }
            .frame(maxWidth: .infinity)
        }
        .font(.subheadline)
        .foregroundStyle(.primary)
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
            Text(draft.notes)
                .lineSpacing(6)
        }
    }
    
    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Button {
                withAnimation {
                    cocktail.isFavourite.toggle()
                }
            } label: {
                Label(
                    cocktail.isFavourite ? "Remove from Favourites" : "Add to Favourites",
                    systemImage: cocktail.isFavourite ? "star.fill" : "star"
                )
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: cocktail.isFavourite)
            }
            .foregroundStyle(cocktail.isFavourite ? .yellow : .primary)
            .sensoryFeedback(.impact(weight: .light), trigger: cocktail.isFavourite)
        }
        
        ToolbarItem(placement: .automatic) {
            if let shareItem = CocktailTransferable(cocktail: cocktail) {
                ShareLink(item: shareItem, preview: SharePreview(cocktail.name, image: Image(cocktail.glass.imageNameEmpty)))
            }
        }

        if let onDone, !isEditing {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { onDone() }
            }
        }

        ToolbarSpacer()

        ToolbarItem(placement: .confirmationAction) {
            Button("Edit", systemImage: "pencil") { isEditing = true }
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
