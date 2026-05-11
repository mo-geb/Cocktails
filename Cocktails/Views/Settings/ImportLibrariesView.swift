import SwiftUI
import UIKit

struct LibraryCounts {
    var cocktails: Int = 0
}

struct ImportLibrariesView: View {
    private let sources = RecipeSource.allCases.filter { !$0.filePrefix.isEmpty }
    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    @State private var counts: [String: LibraryCounts] = [:]

    var body: some View {
        ScrollView {
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
        return result
    }
}

#Preview {
    NavigationStack {
        ImportLibrariesView()
    }
}
