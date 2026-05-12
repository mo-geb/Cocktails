import SwiftUI
import UIKit

struct LibraryCounts {
    var cocktails: Int = 0
}

struct ImportLibrariesView: View {
    @Environment(\.modelContext) private var modelContext

    private let sources = RecipeSource.allCases.filter { !$0.filePrefix.isEmpty }
    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    @State private var counts: [String: LibraryCounts] = [:]
    @State private var isImportingIngredients = false
    @State private var ingredientsResult: ImportResult?
    @State private var ingredientsError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                importAllIngredientsCard

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(sources) { source in
                        NavigationLink {
                            LibraryPreviewView(source: source)
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
    }

    private var importAllIngredientsCard: some View {
        Button {
            guard !isImportingIngredients else { return }
            isImportingIngredients = true
            defer { isImportingIngredients = false }
            do {
                ingredientsResult = try CocktailImporter(context: modelContext).importIngredients()
            } catch {
                ingredientsError = error.localizedDescription
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "leaf.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.green.gradient)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Import All Ingredients")
                        .font(.subheadline.bold())
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                    Text("Add all available ingredients to your inventory")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isImportingIngredients {
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
        .disabled(isImportingIngredients)
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
        ImportLibrariesView()
    }
}
