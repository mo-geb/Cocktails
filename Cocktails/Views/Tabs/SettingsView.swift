import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var cocktails: [Cocktail]
    @Query(sort: \Ingredient.name) private var ingredients: [Ingredient]

    @State private var showClearConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink(destination: ImportLibrariesView()) {
                        Label("Import Library", systemImage: "square.and.arrow.down")
                    }
                }

                Section("About") {
                    Link(destination: URL(string: "https://mo-geb.com")!) {
                        Label("Website", systemImage: "globe")
                            .foregroundStyle(.primary)
                    }
                    Link(destination: URL(string: "mailto:support@mo-geb.com")!) {
                        Label("Contact Support", systemImage: "envelope")
                            .foregroundStyle(.primary)
                    }
                }

                Section("Data") {
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        Label("Clear Data…", systemImage: "trash")
                    }
                }

                Section {
                    HStack {
                        Spacer()
                        versionInfo
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Clear Data", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                Button("Clear Unused Ingredients", role: .destructive) { clearUnusedIngredients() }
                Button("Delete Imported Cocktails", role: .destructive) { deleteImportedCocktails() }
                Button("Delete Everything", role: .destructive) { deleteEverything() }
            } message: {
                Text("Choose what to delete. This cannot be undone.")
            }
        }
    }

    @ViewBuilder
    var versionInfo: some View {
        Text(Bundle.main.fullVersionString)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    // MARK: - Data actions

    private func clearUnusedIngredients() {
        for ingredient in ingredients where ingredient.usages?.isEmpty ?? true {
            modelContext.delete(ingredient)
        }
        try? modelContext.save()
    }

    private func deleteImportedCocktails() {
        for cocktail in cocktails where cocktail.source != .custom {
            modelContext.delete(cocktail)
        }
        try? modelContext.save()
    }

    private func deleteEverything() {
        cocktails.forEach { modelContext.delete($0) }
        ingredients.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewSampleData.container)
}
