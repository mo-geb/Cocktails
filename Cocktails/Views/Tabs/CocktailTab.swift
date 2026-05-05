import SwiftUI
import SwiftData

struct CocktailTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cocktails: [Cocktail]
    
    @State private var activeCocktailSheet: ActiveCocktailSheet?
    @State private var grouping: CocktailGrouping = .none
    
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

struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.06 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct CocktailGridCell: View {
    let cocktail: Cocktail
    let onTap: () -> Void

    @State private var backgroundColor: Color?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                if let backgroundColor {
                    LinearGradient(
                        colors: [backgroundColor, backgroundColor.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .saturation(1.9)
                    .blendMode(colorScheme == .dark ? .screen : .normal)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }

                VStack(spacing: 0) {
                    Spacer()

                    cocktail.displayImage.view(placeholder: cocktail.glass.imageNameFilled)
                        .scaledToFit()
                        .padding(.horizontal, 40)

                    Spacer()

                    VStack(spacing: 6) {
                        Text(cocktail.name.isEmpty ? "Unnamed Cocktail" : cocktail.name)
                            .font(.subheadline.bold())
                            .fontDesign(.rounded)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)

                        HStack(spacing: 4) {
                            Image(cocktail.source.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                            Text(cocktail.source.localizedName)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)

                        HStack(spacing: 0) {
                            HStack(spacing: 5) {
                                Image(cocktail.ice.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 12, height: 12)
                                Text(cocktail.ice.localizedName)
                            }
                            .frame(maxWidth: .infinity)

                            Divider().frame(height: 12)

                            HStack(spacing: 5) {
                                Image(cocktail.method.customImageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 12, height: 12)
                                Text(cocktail.method.localizedName)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .glassEffect()
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 14)
                }

                if cocktail.isFavourite {
                    Image(systemName: "star.fill")
                        .font(.title)
                        .foregroundStyle(.yellow)
                        .padding(12)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(0.78, contentMode: .fit)
            .glassEffect(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(CardPressStyle())
        .contextMenu {
            Button {
                cocktail.isFavourite.toggle()
            } label: {
                Label(
                    cocktail.isFavourite ? "Remove from Favourites" : "Add to Favourites",
                    systemImage: cocktail.isFavourite ? "star.slash" : "star"
                )
            }
        }
        .onAppear {
            backgroundColor = cocktail.displayImage.dominantColor(placeholderName: cocktail.glass.imageNameFilled)
        }
    }
}
