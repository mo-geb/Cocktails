import SwiftUI
import SwiftData

struct MakeableCocktailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var cocktails: [Cocktail]
    @State private var activeCocktailSheet: ActiveCocktailSheet?
    @State private var cocktailToDelete: Cocktail?

    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private var makeableCocktails: [Cocktail] {
        cocktails.filter { cocktail in
            let core = cocktail.ingredients?.filter { $0.role == .core } ?? []
            return !core.isEmpty && core.allSatisfy { $0.ingredient?.isStocked == true }
        }.sorted { $0.name < $1.name }
    }

    private var almostMakeableCocktails: [(cocktail: Cocktail, missing: String)] {
        cocktails
            .sorted { $0.name < $1.name }
            .compactMap { cocktail in
                let core = cocktail.ingredients?.filter { $0.role == .core } ?? []
                let unstocked = core.filter { $0.ingredient?.isStocked != true }
                guard unstocked.count == 1, let missingName = unstocked.first?.ingredient?.name else { return nil }
                return (cocktail: cocktail, missing: missingName)
            }
    }

    var body: some View {
        NavigationStack {
            Group {
                if makeableCocktails.isEmpty && almostMakeableCocktails.isEmpty {
                    ContentUnavailableView(
                        "Nothing to make",
                        systemImage: "wineglass",
                        description: Text("Stock ingredients in your inventory to see cocktails you can make.")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 28) {
                            if !makeableCocktails.isEmpty {
                                section(title: "Ready to make") {
                                    LazyVGrid(columns: columns, spacing: 12) {
                                        ForEach(makeableCocktails) { cocktail in
                                            CocktailGridCell(cocktail: cocktail, onDelete: { cocktailToDelete = cocktail }) {
                                                activeCocktailSheet = .view(cocktail)
                                            }
                                        }
                                    }
                                }
                            }

                            if !almostMakeableCocktails.isEmpty {
                                section(title: "Almost there") {
                                    LazyVGrid(columns: columns, spacing: 12) {
                                        ForEach(almostMakeableCocktails, id: \.cocktail.id) { item in
                                            CocktailGridCell(cocktail: item.cocktail, footerLabel: "Missing: \(item.missing)", onDelete: { cocktailToDelete = item.cocktail }) {
                                                activeCocktailSheet = .view(item.cocktail)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("What can I make?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .confirmationDialog(
                "Delete \"\(cocktailToDelete?.name ?? "")\"?",
                isPresented: Binding(get: { cocktailToDelete != nil }, set: { if !$0 { cocktailToDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let c = cocktailToDelete { modelContext.delete(c) }
                    cocktailToDelete = nil
                }
            }
            .sheet(item: $activeCocktailSheet) { sheet in
                if case .view(let cocktail) = sheet {
                    NavigationStack {
                        CocktailDetailView(cocktail: cocktail)
                    }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
            }
        }
    }

    @ViewBuilder
    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())
                .fontDesign(.rounded)
            content()
        }
    }
}
