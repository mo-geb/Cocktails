import SwiftUI
import SwiftData

struct CocktailTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cocktails: [Cocktail]
    
    @State private var activeCocktailSheet: ActiveCocktailSheet?
    @State private var grouping: CocktailGrouping = .none
    
    let columns = [GridItem(.adaptive(minimum: 150))]
    
    private var groupedCocktails: [(String, [Cocktail])] {
        let sortedCocktails = cocktails.sorted { $0.name < $1.name }
        switch grouping {
        case .none:
            return [("", sortedCocktails)]
        case .glass:
            let groups = Dictionary(grouping: sortedCocktails) { $0.glass.rawValue }
            return groups.sorted { $0.key < $1.key }
        case .method:
            let groups = Dictionary(grouping: sortedCocktails) { $0.method.rawValue }
            return groups.sorted { $0.key < $1.key }
        case .ice:
            let groups = Dictionary(grouping: sortedCocktails) { $0.ice.rawValue }
            return groups.sorted { $0.key < $1.key }
        }
    }
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Cocktails")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        HStack(spacing: 16) {
                            Menu {
                                Picker("Group By", selection: $grouping) {
                                    ForEach(CocktailGrouping.allCases) { option in
                                        Label(option.rawValue, systemImage: option.systemImage)
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
            VStack(alignment: .leading, spacing: 24) {
                ForEach(groupedCocktails, id: \.0) { groupName, cocktails in
                    VStack(alignment: .leading, spacing: 12) {
                        if grouping != .none {
                            Text(groupName)
                                .font(.title3.bold())
                                .fontDesign(.rounded)
                                .padding(.horizontal)
                        }
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(cocktails) { cocktail in
                                Button {
                                    activeCocktailSheet = .view(cocktail)
                                } label: {
                                    gridCell(for: cocktail)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    @ViewBuilder
    private func gridCell(for cocktail: Cocktail) -> some View {
        VStack(spacing: 12) {
            Group {
                if let data = cocktail.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
                    Image(cocktail.glass.imageNameFilled)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                }
            }
            .padding(.top, 20)
            
            VStack(spacing: 6) {
                Text(cocktail.name.isEmpty ? "Unnamed Cocktail" : cocktail.name)
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Image(cocktail.method.customImageName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                    Text(cocktail.method.rawValue)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .glassEffect(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func addNewCocktail() {
        activeCocktailSheet = .new(CocktailDraft())
    }
}

#Preview {
    CocktailTab()
        .modelContainer(PreviewSampleData.container)
}
