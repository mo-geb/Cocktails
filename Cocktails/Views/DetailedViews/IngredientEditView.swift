import SwiftUI
import SwiftData

struct IngredientEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var type: IngredientType
    @State private var showDeleteConfirmation = false

    private let originalIngredient: Ingredient?

    init(ingredient: Ingredient) {
        self.originalIngredient = ingredient
        self._name = State(initialValue: ingredient.name)
        self._type = State(initialValue: ingredient.type)
    }

    init(suggestedName: String = "") {
        self.originalIngredient = nil
        self._name = State(initialValue: suggestedName)
        self._type = State(initialValue: .other)
    }

    private var isNew: Bool { originalIngredient == nil }

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    (originalIngredient?.displayImage ?? DisplayImageSource.placeholder)
                        .view(placeholder: type.imageName)
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())
            }

            Section("Name") {
                TextField("e.g. Campari", text: $name)
                    .autocorrectionDisabled()
            }

            Section("Type") {
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
        .navigationTitle(isNew ? "New Ingredient" : "Edit Ingredient")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
            }
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
    }

    // MARK: - Actions

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let ingredient = originalIngredient {
            ingredient.name = trimmed
            ingredient.type = type
        } else {
            let ingredient = Ingredient(name: trimmed, type: type)
            modelContext.insert(ingredient)
        }
        dismiss()
    }

    private func delete() {
        if let ingredient = originalIngredient {
            modelContext.delete(ingredient)
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        IngredientEditView()
    }
    .modelContainer(PreviewSampleData.container)
}
