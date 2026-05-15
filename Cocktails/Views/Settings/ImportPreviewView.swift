import SwiftUI

struct ImportPreviewView: View {
    let url: URL
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var package: SharedCocktailPackage?
    @State private var errorMessage: String?
    @State private var didImport = false

    var body: some View {
        NavigationStack {
            Group {
                if let package {
                    importPreview(for: package)
                } else if let errorMessage {
                    ContentUnavailableView("Cannot Open File", systemImage: "doc.badge.exclamationmark", description: Text(errorMessage))
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Import Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                if package != nil && !didImport {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Import") { performImport() }
                    }
                }
            }
        }
        .onAppear { loadPackage() }
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private func importPreview(for package: SharedCocktailPackage) -> some View {
        if didImport {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                Text("\(package.cocktail.name) imported.")
                    .font(.headline)
                    .fontDesign(.rounded)
                Button("Done") { onDismiss() }
                    .buttonStyle(.bordered)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(package.cocktail.name)
                        .font(.title2.bold())
                        .fontDesign(.rounded)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 16) {
                        Label(package.cocktail.glass.localizedName, image: package.cocktail.glass.imageNameEmpty)
                        Label(package.cocktail.method.localizedName, image: package.cocktail.method.customImageName)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    let core = package.cocktail.ingredients
                    let garnishes = package.cocktail.garnishes ?? []

                    ForEach(core, id: \.ingredientId) { ri in
                        ingredientRow(ri, in: package)
                    }
                    if !garnishes.isEmpty {
                        Divider()
                        ForEach(garnishes, id: \.ingredientId) { ri in
                            ingredientRow(ri, in: package)
                        }
                    }
                }
                .padding()
                .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private func ingredientRow(_ ri: RecipeIngredientDTO, in package: SharedCocktailPackage) -> some View {
        let name = package.ingredients.first(where: { $0.id == ri.ingredientId })?.name ?? ri.ingredientId
        return HStack(spacing: 8) {
            if let amount = ri.amount > 0 ? ri.amount : nil,
               let unit = ri.unit {
                Text(unit.displayText(for: amount))
                    .bold()
                    .fontDesign(.rounded)
            }
            Text(name)
            Spacer()
            if let note = ri.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func loadPackage() {
        do {
            let data = try Data(contentsOf: url)
            package = try JSONDecoder().decode(SharedCocktailPackage.self, from: data)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func performImport() {
        guard let package else { return }
        do {
            let data = try JSONEncoder().encode(package)
            let importer = CocktailImporter(context: modelContext)
            try importer.importSharedCocktail(from: data)
            didImport = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview(traits: .sampleData) {
    let url: URL = {
        let cocktail = PreviewSampleData.mockCocktail
        let package = SharedCocktailPackage(from: cocktail)
        let data = try! JSONEncoder().encode(package)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("preview.cocktail")
        try! data.write(to: url)
        return url
    }()
    ImportPreviewView(url: url, onDismiss: {})
}
