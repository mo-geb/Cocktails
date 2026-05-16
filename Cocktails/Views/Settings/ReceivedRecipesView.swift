import SwiftUI

struct ReceivedRecipesView: View {
    let url: URL
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var package: SharedCocktailPackage?
    @State private var errorMessage: String?
    @State private var importResult: ImportResult?
    @State private var importError: String?
    @State private var selected = Set<String>()
    @State private var imported = Set<String>()

    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private var allImported: Bool { package.map { imported == Set($0.cocktails.map(\.name)) } ?? false }

    var body: some View {
        NavigationStack {
            Group {
                if let package {
                    cocktailGrid(package)
                } else if let errorMessage {
                    ContentUnavailableView("Cannot Open File", systemImage: "doc.badge.exclamationmark", description: Text(errorMessage))
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(allImported ? "Done" : "Cancel") { onDismiss() }
                }
                if let package, !allImported {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Import \(importButtonLabel(package))") { performImport(package) }
                            .disabled(selected.isEmpty)
                    }
                }
            }
        }
        .onAppear { loadPackage() }
        .presentationDetents([.medium, .large])
        .alert("Import Complete", isPresented: .init(
            get: { importResult != nil },
            set: { if !$0 { importResult = nil } }
        )) {
            Button("OK") { importResult = nil }
        } message: {
            if let r = importResult {
                let n = r.cocktailsInserted
                Text("\(n) cocktail\(n == 1 ? "" : "s") imported.")
            }
        }
        .alert("Import Failed", isPresented: .init(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK") { importError = nil }
        } message: {
            if let e = importError { Text(e) }
        }
    }

    private var navigationTitle: String {
        guard let package else { return "Import Recipe" }
        return package.cocktails.count == 1 ? package.cocktails[0].name : "Import \(package.cocktails.count) Recipes"
    }

    private func importButtonLabel(_ package: SharedCocktailPackage) -> String {
        selected.count == package.cocktails.count ? "" : "(\(selected.count))"
    }

    @ViewBuilder
    private func cocktailGrid(_ package: SharedCocktailPackage) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(package.cocktails.enumerated()), id: \.offset) { _, cocktail in
                    CocktailPreviewCard(
                        dto: cocktail,
                        isSelected: selected.contains(cocktail.name),
                        isImported: imported.contains(cocktail.name)
                    ) {
                        selected.toggle(cocktail.name)
                    }
                }
            }
            .padding()
        }
    }

    private func loadPackage() {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(SharedCocktailPackage.self, from: data)
            package = decoded
            selected = Set(decoded.cocktails.map(\.name))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func performImport(_ package: SharedCocktailPackage) {
        let toImport = package.cocktails.filter { selected.contains($0.name) }
        let filtered = SharedCocktailPackage(cocktails: toImport, ingredients: package.ingredients)
        do {
            let result = try CocktailImporter(context: modelContext).importSharedCocktail(package: filtered)
            imported = imported.union(selected)
            selected.removeAll()
            importResult = result
        } catch {
            importError = error.localizedDescription
        }
    }
}

#Preview("Single cocktail", traits: .sampleData) {
    let url: URL = {
        let package = SharedCocktailPackage(from: [PreviewSampleData.mockCocktail])
        let data = try! JSONEncoder().encode(package)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("preview.cocktail")
        try! data.write(to: url)
        return url
    }()
    ReceivedRecipesView(url: url, onDismiss: {})
}

#Preview("Multiple cocktails", traits: .sampleData) {
    let url: URL = {
        let package = SharedCocktailPackage(from: PreviewSampleData.mockCocktails)
        let data = try! JSONEncoder().encode(package)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("preview_multi.cocktail")
        try! data.write(to: url)
        return url
    }()
    ReceivedRecipesView(url: url, onDismiss: {})
}
