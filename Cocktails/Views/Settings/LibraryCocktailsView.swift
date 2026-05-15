import SwiftUI
import SwiftData

struct LibraryCocktailsView: View {
    let source: RecipeSource

    @Environment(\.modelContext) private var modelContext
    @Query private var existingCocktails: [Cocktail]

    @State private var cocktails: [CocktailDTO] = []
    @State private var selected: Set<String> = []
    @State private var importResult: ImportResult?
    @State private var importError: String?
    @State private var isImporting = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private var alreadyImported: Set<String> {
        Set(existingCocktails.filter { $0.source == source }.map { $0.name })
    }

    private var importable: [CocktailDTO] {
        cocktails.filter { !alreadyImported.contains($0.name) }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(cocktails, id: \.name) { cocktail in
                    CocktailPreviewCard(
                        dto: cocktail,
                        isSelected: selected.contains(cocktail.name),
                        isImported: alreadyImported.contains(cocktail.name)
                    ) {
                        if selected.contains(cocktail.name) {
                            selected.remove(cocktail.name)
                        } else {
                            selected.insert(cocktail.name)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .navigationTitle(source.localizedName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                let allSelected = !importable.isEmpty && importable.allSatisfy { selected.contains($0.name) }
                Button(allSelected ? "Deselect All" : "Select All") {
                    selected = allSelected ? [] : Set(importable.map(\.name))
                }
                .disabled(importable.isEmpty)
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .task {
            loadCocktails()
        }
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

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                performImport(names: Array(selected))
            } label: {
                Text(selected.isEmpty ? "Import Selected" : "Import Selected (\(selected.count))")
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(selected.isEmpty || isImporting)

            Button {
                performImport(names: importable.map(\.name))
            } label: {
                Text("Import All")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(importable.isEmpty || isImporting)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.bar)
    }

    // MARK: - Logic

    private func loadCocktails() {
        let fileName = "\(source.filePrefix)_cocktails"
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dtos = try? JSONDecoder().decode([CocktailDTO].self, from: data)
        else { return }
        cocktails = dtos.sorted { $0.name < $1.name }
    }

    private func performImport(names: [String]) {
        guard !names.isEmpty, !isImporting else { return }
        isImporting = true
        Task { @MainActor in
            defer { isImporting = false }
            await Task.yield()
            do {
                importResult = try CocktailImporter(context: modelContext)
                    .importSelectedCocktails(names: names, from: source)
                selected = []
            } catch {
                importError = error.localizedDescription
            }
        }
    }
}

#Preview(traits: .sampleData) {
    NavigationStack {
        LibraryCocktailsView(source: .ebsInter2023)
    }
}
