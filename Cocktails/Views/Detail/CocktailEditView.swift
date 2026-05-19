import SwiftUI
import SwiftData
import PhotosUI

struct CocktailEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var draft: CocktailDraft
    @State private var backgroundColor: Color?
    @State private var photoItem: PhotosPickerItem?
    @State private var ingredientPickerTarget: IngredientPickerTarget?
    @State private var showDeleteConfirmation = false
    @State private var saveHapticTrigger = false

    private let originalCocktail: Cocktail?
    private let onDelete: (() -> Void)?

    init(cocktail: Cocktail, onDelete: (() -> Void)? = nil) {
        self.originalCocktail = cocktail
        self.onDelete = onDelete
        self._draft = State(initialValue: CocktailDraft(from: cocktail))
    }

    init(draft: CocktailDraft = CocktailDraft()) {
        self.originalCocktail = nil
        self.onDelete = nil
        self._draft = State(initialValue: draft)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                imageSection
                nameField
                propertiesCard
                ingredientListCard(title: "Ingredients", role: .core)
                ingredientListCard(title: "Garnish", role: .garnish)
                notesCard
                if originalCocktail != nil {
                    deleteButton
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 20)
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .dismissKeyboardOnTap()
        .background { gradientBackground }
        .toolbar { toolbarContent }
        .sensoryFeedback(.success, trigger: saveHapticTrigger)
        .onChange(of: draft.glass) { updateBackground() }
        .onChange(of: draft.imageData) { updateBackground() }
        .onChange(of: photoItem) { loadPhoto() }
        .onAppear { updateBackground() }
        .sheet(item: $ingredientPickerTarget) { target in
            IngredientPickerView(
                selection: Binding(
                    get: { draft.ingredients[target.index].ingredient },
                    set: { draft.ingredients[target.index].ingredient = $0 }
                )
            )
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var imageSection: some View {
        ZStack(alignment: .topTrailing) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
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

                    Image(systemName: "camera.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(7)
                        .background(.thinMaterial, in: Circle())
                        .offset(x: 2, y: 2)
                }
            }
            .buttonStyle(.plain)

            if draft.displayImage.isCustom {
                Button {
                    photoItem = nil
                    draft.imageData = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(.black.opacity(0.6), in: Circle())
                }
                .offset(x: -4, y: 4)
            }
        }
    }

    @ViewBuilder
    private var nameField: some View {
        TextField("Cocktail Name", text: $draft.name)
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .submitLabel(.done)
    }

    @ViewBuilder
    private var propertiesCard: some View {
        VStack(spacing: 0) {
            propertyChipRow(title: "Glass") {
                ForEach(GlassType.allCases) { type in
                    chip(label: type.localizedName, imageName: type.imageNameEmpty, isSelected: draft.glass == type) {
                        draft.glass = type
                    }
                }
            }

            Divider().padding(.leading, 20)

            propertyChipRow(title: "Method") {
                ForEach(PreparationMethod.allCases) { method in
                    chip(label: method.localizedName, imageName: method.customImageName, isSelected: draft.method == method) {
                        draft.method = method
                    }
                }
            }

            Divider().padding(.leading, 20)

            propertyChipRow(title: "Ice") {
                ForEach(IceType.allCases) { ice in
                    chip(label: ice.localizedName, imageName: ice.imageName, isSelected: draft.ice == ice) {
                        draft.ice = ice
                    }
                }
            }
        }
        .glassEffect(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    @ViewBuilder
    private func propertyChipRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    content()
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 14)
    }

    private func chip(label: String, imageName: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                Text(label)
                    .font(.caption2.weight(.medium))
                    .fontDesign(.rounded)
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func ingredientListCard(title: String, role: IngredientRole) -> some View {
        let roleIngredients = draft.ingredients.filter { $0.role == role }

        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.title3.bold())
                    .fontDesign(.rounded)
                Spacer()
                Button { addIngredient(role: role) } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }

            Divider()

            if roleIngredients.isEmpty {
                Text("None added yet.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                VStack(spacing: 14) {
                    ForEach(Array(roleIngredients.enumerated()), id: \.element.id) { position, item in
                        if let index = draft.ingredients.firstIndex(where: { $0.id == item.id }) {
                            ingredientRow(item: $draft.ingredients[index]) {
                                draft.ingredients.removeAll { $0.id == item.id }
                            }
                            if position != roleIngredients.count - 1 {
                                Divider().padding(.leading, 42)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .glassEffect(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    @ViewBuilder
    private func ingredientRow(item: Binding<RecipeIngredientDraft>, onDelete: @escaping () -> Void) -> some View {
        let ingredient = item.wrappedValue

        HStack(alignment: .top, spacing: 12) {
            ingredient.ingredient.displayImage
                .view(placeholder: ingredient.ingredient.type.imageName)
                .scaledToFit()
                .frame(width: 34, height: 34)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                // Name + remove
                HStack {
                    Button {
                        if let index = draft.ingredients.firstIndex(where: { $0.id == ingredient.id }) {
                            ingredientPickerTarget = IngredientPickerTarget(index: index)
                        }
                    } label: {
                        Text(ingredient.ingredient.name.isEmpty ? "Select ingredient…" : ingredient.ingredient.localizedName)
                            .fontDesign(.rounded)
                            .foregroundStyle(ingredient.ingredient.name.isEmpty ? AnyShapeStyle(.red) : AnyShapeStyle(.primary))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                // Amount + unit
                HStack(spacing: 6) {
                    TextField("0", value: Binding(
                        get: { ingredient.amount ?? 0.0 },
                        set: { item.wrappedValue.amount = $0 == 0 ? nil : $0 }
                    ), format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 44)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Picker("Unit", selection: item.unit) {
                        ForEach(MeasurementUnit.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                // Note
                TextField("Note (e.g. Sweet Vermouth)", text: item.note)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder
    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            Text("Delete Cocktail")
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 4)
        .confirmationDialog(
            "Delete \"\(originalCocktail?.name ?? "")\"?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let cocktail = originalCocktail {
                    modelContext.delete(cocktail)
                }
                onDelete?()
                dismiss()
            }
        }
    }

    @ViewBuilder
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes")
                .font(.title3.bold())
                .fontDesign(.rounded)

            Divider()

            TextField("Add preparation notes…", text: $draft.notes, axis: .vertical)
                .font(.body)
        }
        .padding(20)
        .glassEffect(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", systemImage: "xmark") { dismiss() }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button("Save", systemImage: "checkmark") { save() }
                .tint(.green)
                .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty || hasIncompleteIngredient)
        }
    }

    private var hasIncompleteIngredient: Bool {
        draft.ingredients.contains { $0.ingredient.name.isEmpty }
    }

    // MARK: - Background

    @ViewBuilder
    private var gradientBackground: some View {
        ZStack {
            Color(.systemBackground)

            if let backgroundColor {
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        .init(0.0, 0.0), .init(0.5, 0.0), .init(1.0, 0.0),
                        .init(0.0, 0.5), .init(0.7, 0.4), .init(1.0, 0.5),
                        .init(0.0, 1.0), .init(0.5, 1.0), .init(1.0, 1.0)
                    ],
                    colors: [
                        backgroundColor,                 backgroundColor.opacity(0.8), backgroundColor.opacity(0.5),
                        backgroundColor.opacity(0.7),    backgroundColor.opacity(0.3), .clear,
                        backgroundColor.opacity(0.2),    .clear,                       .clear
                    ]
                )
                .saturation(1.9)
                .blendMode(colorScheme == .dark ? .screen : .normal)
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.5), value: backgroundColor)
    }

    // MARK: - Actions

    private func updateBackground() {
        backgroundColor = draft.displayImage.dominantColor(placeholderName: draft.glass.imageNameFilled)
    }

    private func loadPhoto() {
        Task {
            if let data = try? await photoItem?.loadTransferable(type: Data.self) {
                draft.imageData = data
            }
        }
    }

    private func addIngredient(role: IngredientRole) {
        let count = draft.ingredients.filter { $0.role == role }.count
        draft.ingredients.append(RecipeIngredientDraft(role: role, sortOrder: count))
    }

    private func save() {
        if let cocktail = originalCocktail {
            update(cocktail)
        } else {
            createNew()
        }
        saveHapticTrigger.toggle()
        dismiss()
    }

    private func createNew() {
        let cocktail = Cocktail(
            name: draft.name.trimmingCharacters(in: .whitespaces),
            notes: draft.notes,
            glass: draft.glass,
            method: draft.method,
            ice: draft.ice,
            source: .custom,
            imageData: draft.imageData,
            imageName: draft.imageName
        )
        cocktail.isFavourite = draft.isFavourite
        modelContext.insert(cocktail)
        insertIngredients(for: draft.ingredients, into: cocktail)
    }

    private func update(_ cocktail: Cocktail) {
        cocktail.name = draft.name.trimmingCharacters(in: .whitespaces)
        cocktail.notes = draft.notes
        cocktail.glass = draft.glass
        cocktail.method = draft.method
        cocktail.ice = draft.ice
        cocktail.isFavourite = draft.isFavourite
        cocktail.source = .custom
        cocktail.imageData = draft.imageData
        cocktail.imageName = draft.imageName

        for existing in cocktail.ingredients ?? [] {
            modelContext.delete(existing)
        }
        cocktail.ingredients = []
        insertIngredients(for: draft.ingredients, into: cocktail)
    }

    private func insertIngredients(for drafts: [RecipeIngredientDraft], into cocktail: Cocktail) {
        for (index, d) in drafts.enumerated() {
            guard !d.ingredient.name.isEmpty else { continue }
            let ingredient = findOrCreate(d.ingredient)
            let item = RecipeIngredient(
                amount: d.amount ?? 0,
                unit: d.unit,
                note: d.note,
                role: d.role,
                sortOrder: index,
                ingredient: ingredient
            )
            item.cocktail = cocktail
            modelContext.insert(item)
        }
    }

    private func findOrCreate(_ draft: IngredientDraft) -> Ingredient {
        let id = draft.id
        let request = FetchDescriptor<Ingredient>(predicate: #Predicate { $0.id == id })
        if let existing = try? modelContext.fetch(request).first {
            existing.name = draft.name
            existing.type = draft.type
            existing.imageName = draft.imageName
            return existing
        }
        let ingredient = Ingredient(id: draft.id, name: draft.name, type: draft.type)
        modelContext.insert(ingredient)
        return ingredient
    }
}

// MARK: - Supporting Types

private struct IngredientPickerTarget: Identifiable {
    let id = UUID()
    let index: Int
}

#Preview(traits: .sampleData) {
    NavigationStack {
        CocktailEditView()
    }
}
