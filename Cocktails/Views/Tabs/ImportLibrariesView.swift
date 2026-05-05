import SwiftUI

private struct LibraryCounts {
    var cocktails: Int = 0
    var ingredients: Int = 0
}

struct ImportLibrariesView: View {
    private let sources = RecipeSource.allCases.filter { !$0.filePrefix.isEmpty }
    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    @State private var counts: [String: LibraryCounts] = [:]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(sources) { source in
                    LibraryCard(source: source, counts: counts[source.id] ?? LibraryCounts())
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
    }

    private func loadCounts(for source: RecipeSource) -> LibraryCounts {
        var result = LibraryCounts()
        let prefix = source.filePrefix

        if let url = Bundle.main.url(forResource: "\(prefix)_cocktails", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            result.cocktails = arr.count
        }

        if let url = Bundle.main.url(forResource: "\(prefix)_ingredients", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            result.ingredients = arr.count
        }

        return result
    }
}

private struct LibraryCard: View {
    let source: RecipeSource
    let counts: LibraryCounts

    var body: some View {
        VStack(spacing: 0) {
            Image(source.imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 90)
                .padding(.vertical, 20)
                .padding(.horizontal, 12)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text(source.localizedName)
                    .font(.headline)

                HStack(spacing: 14) {
                    Label("\(counts.cocktails)", systemImage: "wineglass")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label("\(counts.ingredients)", systemImage: "leaf")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .glassEffect(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ImportLibrariesView()
    }
}
