import SwiftUI
import SwiftData
import StoreKit

struct CocktailDetailView: View {
    @Environment(\.requestReview) private var requestReview
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let cocktail: Cocktail
    private let onDone: (() -> Void)?
    @State private var backgroundColor: Color?
    @State private var isEditing = false

    init(cocktail: Cocktail, onDone: (() -> Void)? = nil) {
        self.cocktail = cocktail
        self.onDone = onDone
        self._backgroundColor = State(initialValue: cocktail.artworkTint)
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
        // On the container rather than `detailView`, which is recreated each time
        // editing ends — that would count one visit as several views.
        .task {
            if ReviewManager.recordCocktailViewed() {
                try? await Task.sleep(for: .seconds(1))
                requestReview()
            }
        }
    }

    private func finishEditing() {
        backgroundColor = cocktail.artworkTint
        isEditing = false
    }

    private var detailView: some View {
        ScrollView {
            GlassEffectContainer(spacing: 18) {
                VStack(spacing: 18) {
                    imageSection
                    titleSection
                    propertiesPill
                    ingredientListCard(cocktail.coreIngredients)
                    ingredientListCard(cocktail.garnishIngredients, title: "Garnish", hideWhenEmpty: true)
                    if !cocktail.notes.isEmpty { notesCard }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .scrollContentBackground(.hidden)
        .toolbar { toolbarContent }
    }

    // MARK: - View Components

    @ViewBuilder
    private var imageSection: some View {
        if cocktail.displayImage.isCustom {
            cocktail.displayImage.view(placeholder: cocktail.glass.imageNameFilled)
                .scaledToFill()
                .frame(width: 190, height: 190)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .padding(8)
                .glassEffect(in: RoundedRectangle(cornerRadius: 40, style: .continuous))
        } else {
            // Same upward nudge as the cell artwork, which reads low when centered.
            cocktail.displayImage.view(placeholder: cocktail.glass.imageNameFilled)
                .scaledToFit()
                .frame(width: 180, height: 180)
                .offset(y: -9)
        }
    }

    @ViewBuilder
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text(cocktail.name.isEmpty ? "Unnamed Cocktail" : cocktail.name)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 5) {
                Image(cocktail.source.imageName)
                    .resizable()
                    .scaledToFit()
                    .scaledFrame(20, relativeTo: .callout)
                    .accessibilityHidden(true)
                Text(cocktail.source.localizedName)
                    .font(.callout)
            }
            .foregroundStyle(.secondary)
            .font(.subheadline)
        }
    }

    @ViewBuilder
    private var propertiesPill: some View {
        Group {
            // Stacked at accessibility sizes rather than squeezing the labels
            // into thirds of the width.
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 12) {
                    propertyPill(imageName: cocktail.glass.imageNameEmpty, label: cocktail.glass.localizedName)
                    propertyPill(imageName: cocktail.ice.imageName, label: cocktail.ice.localizedName)
                    propertyPill(imageName: cocktail.method.customImageName, label: cocktail.method.localizedName)
                }
                .padding(.vertical, 16)
                .glassEffect(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            } else {
                HStack(spacing: 0) {
                    propertyPill(imageName: cocktail.glass.imageNameEmpty, label: cocktail.glass.localizedName)
                    Divider().frame(height: 16)
                    propertyPill(imageName: cocktail.ice.imageName, label: cocktail.ice.localizedName)
                    Divider().frame(height: 16)
                    propertyPill(imageName: cocktail.method.customImageName, label: cocktail.method.localizedName)
                }
                .padding(.vertical, 16)
                .glassEffect()
            }
        }
        .font(.subheadline)
        .foregroundStyle(.primary)
    }

    private func propertyPill(imageName: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .scaledFrame(16, relativeTo: .subheadline)
                .accessibilityHidden(true)
            Text(label)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func ingredientListCard(_ ingredients: [RecipeIngredient], title: LocalizedStringKey = "Ingredients", hideWhenEmpty: Bool = false) -> some View {
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
            Text(cocktail.notes)
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
                Button(role: .close) { onDone() }
            }
        }

        ToolbarSpacer()

        ToolbarItem(placement: .confirmationAction) {
            Button("Edit", systemImage: "pencil") { isEditing = true }
        }
    }

    private func ingredientRow(for item: RecipeIngredient) -> some View {
        HStack(spacing: 12) {
            if let ing = item.ingredient {
                ing.displayImage.view(placeholder: ing.type.imageName)
                    .scaledToFit()
                    .scaledFrame(30)
            }

            HStack(alignment: .center, spacing: 6) {
                if let amountText = item.unit.amountLabel(item.amount) {
                    Text(amountText)
                        .bold()
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.ingredient?.localizedName ?? "")
                    if !item.note.isEmpty {
                        Text(item.note)
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
