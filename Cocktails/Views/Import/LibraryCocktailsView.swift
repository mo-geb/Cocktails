import SwiftUI
import SwiftData

struct LibraryCocktailsView: View {
    let source: RecipeSource

    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var store
    @Query private var existingCocktails: [Cocktail]

    @State private var cocktails: [CocktailDTO] = []
    @State private var selected: Set<String> = []
    @State private var importResult: ImportResult?
    @State private var importError: String?
    @State private var isImporting = false
    @State private var showPaywall = false

    private var alreadyImported: Set<String> {
        Set(existingCocktails.filter { $0.source == source }.map { $0.name })
    }

    private var importable: [CocktailDTO] {
        cocktails.filter { !alreadyImported.contains($0.name) }
    }

    var body: some View {
        ScrollView {
            libraryHeader

            LazyVGrid(columns: GridColumns.cocktails, spacing: 12) {
                ForEach(cocktails, id: \.name) { cocktail in
                    CocktailPreviewCell(
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
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .importResultAlerts(result: $importResult, error: $importError)
    }

    // MARK: - Header

    @ViewBuilder
    private var libraryHeader: some View {
        let description = source.localizedDescription
        if !description.isEmpty || source.sourceURL != nil {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: "info.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    if !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let url = source.sourceURL {
                        Link(destination: url) {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                Text(url.host ?? String(localized: "Source"))
                            }
                            .font(.caption.bold())
                            .fontDesign(.rounded)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .glassEffect(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 4)
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        Button {
            performImport(names: Array(selected))
        } label: {
            Text(selected.isEmpty ? "Import Selected" : "Import Selected (\(selected.count))")
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .disabled(selected.isEmpty || isImporting)
        .padding(.horizontal)
        .padding(.vertical, 12)
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

        let newCount = names.filter { !alreadyImported.contains($0) }.count
        guard store.canImport(currentCount: existingCocktails.count, requestedCount: newCount) else {
            showPaywall = true
            return
        }

        isImporting = true
        Task {
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

#Preview("EBS", traits: .sampleData) {
    NavigationStack {
        LibraryCocktailsView(source: .ebsInter2023)
            .environment(StoreManager())
    }
}

#Preview("ClutterFree", traits: .sampleData) {
    NavigationStack {
        LibraryCocktailsView(source: .clutterfree)
            .environment(StoreManager())
    }
}
