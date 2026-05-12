import SwiftUI
import SwiftData

struct CocktailTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cocktails: [Cocktail]

    @State private var activeCocktailSheet: ActiveCocktailSheet?
    @State private var grouping: CocktailGrouping = .none
    @State private var showSettings = false
    @State private var cocktailToDelete: Cocktail?

    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private var groupedCocktails: [(String, [Cocktail])] {
        let sortedCocktails = cocktails.sorted { $0.name < $1.name }
        switch grouping {
        case .none:
            return [("", sortedCocktails)]
        case .glass:
            let groups = Dictionary(grouping: sortedCocktails) { $0.glass.localizedName }
            return groups.sorted { $0.key < $1.key }
        case .method:
            let groups = Dictionary(grouping: sortedCocktails) { $0.method.localizedName }
            return groups.sorted { $0.key < $1.key }
        case .ice:
            let groups = Dictionary(grouping: sortedCocktails) { $0.ice.localizedName }
            return groups.sorted { $0.key < $1.key }
        case .favourite:
            let groups = Dictionary(grouping: sortedCocktails) { $0.isFavourite ? "Favourites" : "All Cocktails" }
            return groups.sorted { $0.key > $1.key }
        case .source:
            let groups = Dictionary(grouping: sortedCocktails) { $0.source.localizedName }
            return groups.sorted { $0.key < $1.key }
        case .base:
            let groups = Dictionary(grouping: sortedCocktails) { $0.baseGroup }
            return groups.sorted { l, r in
                if l.key == "No Base" { return false }
                if r.key == "No Base" { return true }
                return l.key < r.key
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Cocktails")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { showSettings = true } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Picker("Group By", selection: $grouping) {
                                ForEach(CocktailGrouping.allCases) { option in
                                    Label(option.localizedName, systemImage: option.systemImage)
                                        .tag(option)
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .symbolVariant(grouping == .none ? .none : .fill)
                        }
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: addNewCocktail) {
                            Label("Add Cocktail", systemImage: "plus")
                        }
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
                .sheet(isPresented: $showSettings) { SettingsView() }
                .sheet(item: $activeCocktailSheet) { sheet in
                    switch sheet {
                    case .view(let c):
                        NavigationStack {
                            CocktailDetailView(cocktail: c)
                        }
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                    case .new(let draft):
                        NavigationStack {
                            CocktailEditView(draft: draft)
                        }
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                    case .edit(let c):
                        NavigationStack {
                            CocktailEditView(cocktail: c)
                        }
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                    }
                }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ForEach(groupedCocktails, id: \.0) { groupName, cocktails in
                    VStack(alignment: .leading, spacing: 12) {
                        if grouping != .none {
                            Text(groupName)
                                .font(.title3.bold())
                                .fontDesign(.rounded)
                                .padding(.horizontal)
                        }

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(cocktails) { cocktail in
                                CocktailGridCell(cocktail: cocktail, onDelete: { cocktailToDelete = cocktail }) {
                                    activeCocktailSheet = .view(cocktail)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private func addNewCocktail() {
        activeCocktailSheet = .new(CocktailDraft())
    }
}

#Preview {
    CocktailTab()
        .modelContainer(PreviewSampleData.container)
}
