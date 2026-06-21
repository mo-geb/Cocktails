import SwiftUI

struct LibraryCounts {
    var cocktails: Int = 0
}

struct RecipeLibrariesView: View {
    @Environment(\.modelContext) private var modelContext

    private let sources = RecipeSource.allCases.filter { !$0.filePrefix.isEmpty }
    @State private var counts: [String: LibraryCounts] = [:]
    @State private var isImportingIngredients = false
    @State private var isReimportingCocktails = false
    @State private var alert: AlertItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    importAllIngredientsCard
                    reimportEverythingCard
                }

                LazyVGrid(columns: GridColumns.libraries, spacing: 16) {
                    ForEach(sources) { source in
                        NavigationLink {
                            LibraryCocktailsView(source: source)
                        } label: {
                            LibraryCell(source: source, counts: counts[source.id] ?? LibraryCounts())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Import")
        .task {
            for source in sources {
                counts[source.id] = loadCounts(for: source)
            }
        }
        .alert(item: $alert) { item in
            switch item {
            case .ingredientsSuccess(let r):
                Alert(title: Text("Ingredients Imported"),
                      message: Text("\(r.ingredientsInserted) added, \(r.ingredientsSkipped) already present."),
                      dismissButton: .default(Text("OK")))
            case .ingredientsFailure(let e):
                Alert(title: Text("Import Failed"), message: Text(e), dismissButton: .default(Text("OK")))
            case .cocktailsSuccess(let r):
                Alert(title: Text("Reimport Complete"),
                      message: Text("\(r.cocktailsInserted) cocktails reimported. \(r.ingredientsInserted) ingredients added, \(r.ingredientsSkipped) updated."),
                      dismissButton: .default(Text("OK")))
            case .cocktailsFailure(let e):
                Alert(title: Text("Reimport Failed"), message: Text(e), dismissButton: .default(Text("OK")))
            }
        }
    }

    private var importAllIngredientsCard: some View {
        importActionCard(
            icon: "leaf.fill", color: .green,
            title: "Import All Ingredients",
            subtitle: "Add all available ingredients",
            isLoading: isImportingIngredients
        ) {
            guard !isImportingIngredients else { return }
            isImportingIngredients = true
            Task { @MainActor in
                defer { isImportingIngredients = false }
                await Task.yield()
                do {
                    let result = try CocktailImporter(context: modelContext).importIngredients()
                    alert = .ingredientsSuccess(result)
                } catch {
                    alert = .ingredientsFailure(error.localizedDescription)
                }
            }
        }
    }

    private var reimportEverythingCard: some View {
        importActionCard(
            icon: "arrow.clockwise", color: .blue,
            title: "Reimport Everything",
            subtitle: "Refresh ingredients and replace all library cocktails with the latest versions",
            isLoading: isReimportingCocktails
        ) {
            guard !isReimportingCocktails else { return }
            isReimportingCocktails = true
            Task { @MainActor in
                defer { isReimportingCocktails = false }
                await Task.yield()
                do {
                    let result = try CocktailImporter(context: modelContext).reimportEverything()
                    alert = .cocktailsSuccess(result)
                } catch {
                    alert = .cocktailsFailure(error.localizedDescription)
                }
            }
        }
    }

    private func importActionCard(
        icon: String,
        color: Color,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        isLoading: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(color.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isLoading { ProgressView() }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    private func loadCounts(for source: RecipeSource) -> LibraryCounts {
        var result = LibraryCounts()
        let prefix = source.filePrefix
        if let url = Bundle.main.url(forResource: "\(prefix)_cocktails", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            result.cocktails = arr.count
        }
        return result
    }
}

private enum AlertItem: Identifiable {
    case ingredientsSuccess(ImportResult)
    case ingredientsFailure(String)
    case cocktailsSuccess(ImportResult)
    case cocktailsFailure(String)

    var id: String {
        switch self {
        case .ingredientsSuccess: "ingredientsSuccess"
        case .ingredientsFailure: "ingredientsFailure"
        case .cocktailsSuccess: "cocktailsSuccess"
        case .cocktailsFailure: "cocktailsFailure"
        }
    }
}

#Preview {
    NavigationStack {
        RecipeLibrariesView()
    }
}
