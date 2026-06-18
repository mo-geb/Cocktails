import SwiftUI
import SwiftData

struct CocktailTab: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(StoreManager.self) private var store
    @Query(sort: \Cocktail.name) private var cocktails: [Cocktail]

    @State private var isSelecting = false
    @State private var selection = Set<UUID>()
    @State private var showDeleteConfirm = false
    @State private var viewedCocktail: Cocktail?
    @Namespace private var zoomNamespace

    private var selectedCocktails: [Cocktail] {
        cocktails.filter { selection.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle(isSelecting ? selectionTitle : "Cocktails")
                .toolbar { toolbarContent }
                .cocktailZoomDestination($viewedCocktail, in: zoomNamespace)
                .alert("Delete Cocktails", isPresented: $showDeleteConfirm) {
                    Button("Delete", role: .destructive) { deleteSelected() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Delete \(selection.count) cocktail\(selection.count == 1 ? "" : "s")? This cannot be undone.")
                }
        }
    }

    private var selectionTitle: String {
        selection.isEmpty ? "Select Cocktails" : "\(selection.count) Selected"
    }

    private func startSelecting() {
        isSelecting = true
        selection = []
    }

    private func stopSelecting() {
        isSelecting = false
        selection = []
    }

    @ViewBuilder
    private var mainContent: some View {
        if cocktails.isEmpty {
            ContentUnavailableView {
                Label("No Cocktails", systemImage: "wineglass")
            } description: {
                Text("Import a library or tap + to add your first cocktail.")
            } actions: {
                Button("Import Library") { appState.openImportLibrary() }
                    .buttonStyle(.glassProminent)
            }
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 28) {
                    ForEach(groupedCocktails) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center, spacing: 4) {
                                if let imageName = group.imageName {
                                    Image(imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 28, height: 28)
                                }
                                Text(group.name)
                            }
                            .sectionTitleStyle()
                            .padding(.horizontal)

                            LazyVGrid(columns: GridColumns.cocktails, spacing: 12) {
                                ForEach(group.items) { cocktail in
                                    CocktailGridCell(
                                        cocktail: cocktail,
                                        isSelected: selection.contains(cocktail.id),
                                        isSelecting: isSelecting,
                                        onDelete: isSelecting ? nil : { appState.confirmDeleteCocktail(cocktail) }
                                    ) {
                                        if isSelecting {
                                            selection.toggle(cocktail.id)
                                        } else {
                                            viewedCocktail = cocktail
                                        }
                                    }
                                    .matchedTransitionSource(id: cocktail.id, in: zoomNamespace)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        @Bindable var appState = appState

        if isSelecting {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { stopSelecting() }
            }
            
            ToolbarItem(placement: .automatic) {
                if let shareItem = CocktailTransferable(cocktails: selectedCocktails) {
                    ShareLink(item: shareItem, preview: SharePreview(shareItem.fileName))
                } else {
                    Button {} label: { Label("Share", systemImage: "square.and.arrow.up") }
                        .disabled(true)
                }
            }
            
            ToolbarSpacer()

            ToolbarItem(placement: .automatic) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(.red)
                .disabled(selection.isEmpty)
            }
        } else {
            ToolbarItem(placement: .topBarLeading) {
                Button { appState.openSettings() } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: startSelecting) {
                        Label("Select Cocktails", systemImage: "checkmark.circle")
                    }
                    Divider()
                    Menu {
                        Picker("Group By", selection: $appState.cocktailGrouping) {
                            ForEach(CocktailGrouping.allCases) { option in
                                Label(option.localizedName, systemImage: option.systemImage)
                                    .tag(option)
                            }
                        }
                    } label: {
                        Label("Group By", systemImage: "rectangle.3.group")
                    }
                } label: {
                    Label("Options", systemImage: "ellipsis")
                        .symbolVariant(appState.cocktailGrouping == .none ? .none : .fill)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: addNewCocktail) {
                    Label("Add Cocktail", systemImage: "plus")
                }
            }
        }
    }

    private func deleteSelected() {
        for cocktail in selectedCocktails {
            modelContext.delete(cocktail)
        }
        stopSelecting()
    }

    private func addNewCocktail() {
        guard store.canAddMore(currentCount: cocktails.count) else {
            appState.openPaywall()
            return
        }
        appState.addCocktail()
    }
    
    private struct CocktailGroup: Identifiable {
        let name: String
        let imageName: String?
        let items: [Cocktail]
        var id: String { name }
    }

    private var groupedCocktails: [CocktailGroup] {
        let grouping = appState.cocktailGrouping
        return Dictionary(grouping: cocktails) { grouping.key(for: $0) }
            .sorted { ($0.key.sortRank, $0.key.name) < ($1.key.sortRank, $1.key.name) }
            .map { key, items in
                CocktailGroup(name: key.name, imageName: key.imageName, items: items)
            }
    }
}

#Preview(traits: .sampleData) {
    CocktailTab()
        .environment(AppState())
        .environment(StoreManager())
}

#Preview("Empty") {
    CocktailTab()
        .environment(AppState())
        .environment(StoreManager())
        .modelContainer(for: Cocktail.self, inMemory: true)
}
