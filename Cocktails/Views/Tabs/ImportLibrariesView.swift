import SwiftUI
import UIKit

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

    @Environment(\.colorScheme) private var colorScheme
    @State private var accentColor: Color?

    var body: some View {
        Button(action: {}) {
            ZStack(alignment: .bottom) {
                // Gradient background from source image dominant color
                if let accentColor {
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .saturation(1.9)
                    .blendMode(colorScheme == .dark ? .screen : .normal)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }

                VStack(spacing: 0) {
                    Spacer()

                    Image(source.imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 28)
                        .padding(.top, 24)

                    Spacer()

                    // Info bar
                    VStack(alignment: .leading, spacing: 5) {
                        Text(source.localizedName)
                            .font(.headline)
                            .fontDesign(.rounded)

                        HStack(spacing: 14) {
                            Label("\(counts.cocktails) cocktails", systemImage: "wineglass")
                            Label("\(counts.ingredients) ingredients", systemImage: "leaf")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 0, style: .continuous))
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(0.8, contentMode: .fit)
            .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(CardPressStyle())
        .onAppear {
            if let uiImage = UIImage(named: source.imageName) {
                accentColor = uiImage.dominantColor().map { Color($0) }
            }
        }
    }
}

private struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        ImportLibrariesView()
    }
}
