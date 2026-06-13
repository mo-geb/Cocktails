import SwiftUI
import SwiftData

struct IngredientEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var type: IngredientType
    @State private var imageName: String?
    @State private var showDeleteConfirmation = false
    @State private var showImagePicker = false
    @State private var saveHapticTrigger = false

    private let originalIngredient: Ingredient?

    private let onSave: ((Ingredient) -> Void)?

    init(ingredient: Ingredient) {
        self.originalIngredient = ingredient
        self.onSave = nil
        self._name = State(initialValue: ingredient.name)
        self._type = State(initialValue: ingredient.type)
        self._imageName = State(initialValue: ingredient.imageName)
    }

    init(suggestedName: String = "", onSave: ((Ingredient) -> Void)? = nil) {
        self.originalIngredient = nil
        self.onSave = onSave
        self._name = State(initialValue: suggestedName)
        self._type = State(initialValue: .other)
        self._imageName = State(initialValue: nil)
    }

    private var isNew: Bool { originalIngredient == nil }

    /// True when the view was pushed onto a navigation stack (the picker's
    /// create-new flow, which passes `onSave`). When pushed, the system back
    /// chevron handles dismissal so the explicit Cancel button is omitted.
    private var isPushed: Bool { onSave != nil }

    private var previewImage: DisplayImageSource {
        let assetName = "Ingredient/" + (imageName ?? (originalIngredient?.id ?? ""))
        if UIImage(named: assetName) != nil { return .system(assetName) }
        return .placeholder
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    Button {
                        showImagePicker = true
                    } label: {
                        VStack(spacing: 6) {
                            previewImage
                                .view(placeholder: type.imageName)
                                .scaledToFit()
                                .frame(width: 64, height: 64)
                                .overlay(alignment: .bottomTrailing) {
                                    Image(systemName: "pencil.circle.fill")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, .tint)
                                        .font(.system(size: 20))
                                }
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())
            }

            Section {
                TextField("Name", text: $name, prompt: Text("e.g. Campari"))
                    .autocorrectionDisabled()

                Picker("Type", selection: $type) {
                    ForEach(IngredientType.allCases) { t in
                        Text(t.localizedName).tag(t)
                    }
                }
            }

            if !isNew {
                Section {
                    Button("Delete Ingredient", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(isNew ? "New Ingredient" : "Edit Ingredient")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isPushed {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            IngredientImagePickerSheet(selectedImageName: $imageName)
        }
        .confirmationDialog(
            "Delete \"\(originalIngredient?.name ?? "")\"?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { delete() }
        } message: {
            Text("It will be removed from any recipes that use it.")
        }
        .sensoryFeedback(.success, trigger: saveHapticTrigger)
    }

    // MARK: - Actions

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let ingredient = originalIngredient {
            ingredient.name = trimmed
            ingredient.type = type
            ingredient.imageName = imageName
            saveHapticTrigger.toggle()
            dismiss()
        } else {
            let ingredient = Ingredient(name: trimmed, type: type, imageName: imageName)
            modelContext.insert(ingredient)
            saveHapticTrigger.toggle()
            // Let the presenter (the picker) select it and unwind; otherwise dismiss.
            if let onSave { onSave(ingredient) } else { dismiss() }
        }
    }

    private func delete() {
        if let ingredient = originalIngredient {
            for usage in ingredient.usages ?? [] {
                modelContext.delete(usage)
            }
            modelContext.delete(ingredient)
        }
        dismiss()
    }
}

#Preview(traits: .sampleData) {
    ScrollView {
        NavigationStack {
            IngredientEditView()
        }
    }
}
