import SwiftUI
import UIKit

struct LibraryCounts {
    var cocktails: Int = 0
}

struct RecipeLibrariesView: View {
    @Environment(\.modelContext) private var modelContext

    private let sources = RecipeSource.allCases.filter { !$0.filePrefix.isEmpty }
    @State private var counts: [String: LibraryCounts] = [:]
    @State private var isImportingIngredients = false
    @State private var ingredientsResult: ImportResult?
    @State private var ingredientsError: String?

    @State private var isReimportingCocktails = false
    @State private var cocktailsResult: ImportResult?
    @State private var cocktailsError: String?

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
                            LibraryCard(source: source, counts: counts[source.id] ?? LibraryCounts())
                        }
                        .buttonStyle(CardPressStyle())
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Import")
        .background(Color(.systemGroupedBackground))
        .task {
            for source in sources {
                counts[source.id] = loadCounts(for: source)
            }
        }
        .alert("Ingredients Imported", isPresented: .init(
            get: { ingredientsResult != nil },
            set: { if !$0 { ingredientsResult = nil } }
        )) {
            Button("OK") { ingredientsResult = nil }
        } message: {
            if let r = ingredientsResult {
                Text("\(r.ingredientsInserted) added, \(r.ingredientsSkipped) already present.")
            }
        }
        .alert("Import Failed", isPresented: .init(
            get: { ingredientsError != nil },
            set: { if !$0 { ingredientsError = nil } }
        )) {
            Button("OK") { ingredientsError = nil }
        } message: {
            if let e = ingredientsError { Text(e) }
        }
        .alert("Reimport Complete", isPresented: .init(
            get: { cocktailsResult != nil },
            set: { if !$0 { cocktailsResult = nil } }
        )) {
            Button("OK") { cocktailsResult = nil }
        } message: {
            if let r = cocktailsResult {
                Text("\(r.cocktailsInserted) cocktails reimported. \(r.ingredientsInserted) ingredients added, \(r.ingredientsSkipped) updated.")
            }
        }
        .alert("Reimport Failed", isPresented: .init(
            get: { cocktailsError != nil },
            set: { if !$0 { cocktailsError = nil } }
        )) {
            Button("OK") { cocktailsError = nil }
        } message: {
            if let e = cocktailsError { Text(e) }
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
                    ingredientsResult = try CocktailImporter(context: modelContext).importIngredients()
                } catch {
                    ingredientsError = error.localizedDescription
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
                    cocktailsResult = try CocktailImporter(context: modelContext).reimportEverything()
                } catch {
                    cocktailsError = error.localizedDescription
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
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(color.gradient)
                    .clipShape(Circle())

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

                if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .glassEffect()
        }
        .buttonStyle(CardPressStyle())
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

#Preview {
    NavigationStack {
        RecipeLibrariesView()
    }
}
