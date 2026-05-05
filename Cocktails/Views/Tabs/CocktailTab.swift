import SwiftUI
import SwiftData

struct CocktailTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cocktails: [Cocktail]
    
    @State private var activeCocktailSheet: ActiveCocktailSheet?
    @State private var grouping: CocktailGrouping = .none
    @State private var showSettings = false
    
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
                    ToolbarItem(placement: .primaryAction) {
                        HStack(spacing: 16) {
                            Menu {
                                Picker("Group By", selection: $grouping) {
                                    ForEach(CocktailGrouping.allCases) { option in
                                        Label(option.localizedName, systemImage: option.systemImage)
                                            .tag(option)
                                    }
                                }
                            } label: {
                                Image(systemName: grouping == .none ? "line.3.horizontal.decrease.circle" : grouping.systemImage)
                                    .symbolVariant(grouping == .none ? .none : .fill)
                            }

                            Button(action: addNewCocktail) {
                                Label("Add Cocktail", systemImage: "plus")
                            }
                        }
                    }
                }
                .background(Color(.systemGroupedBackground))
                .sheet(isPresented: $showSettings) { SettingsView() }
                .sheet(item: $activeCocktailSheet) { sheet in
                    switch sheet {
                    case .view(let c):
                        NavigationStack {
                            CocktailDetailView(cocktail: c)
                        }
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                    default: EmptyView()
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
                                CocktailGridCell(cocktail: cocktail) {
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
