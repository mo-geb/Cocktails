import SwiftUI
import SwiftData

struct IngredientPickerView: View {
    @Query(sort: \Ingredient.name) private var allIngredients: [Ingredient]
    @Binding var selection: IngredientDraft

    var onPicked: () -> Void = {}

    @State private var searchText = ""
    @State private var pendingName: String?

    private var filtered: [Ingredient] {
        guard !searchText.isEmpty else { return allIngredients }
        return allIngredients.filter { $0.localizedName.localizedStandardContains(searchText) }
    }

    private var groupedIngredients: [(IngredientType, [Ingredient])] {
        let groups = Dictionary(grouping: filtered) { $0.type }
        return IngredientType.allCases.compactMap { type in
            guard let items = groups[type], !items.isEmpty else { return nil }
            return (type, items)
        }
    }

    private var showAddSuggestion: Bool {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        return !filtered.contains {
            $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if searchText.isEmpty {
                    ForEach(groupedIngredients, id: \.0) { type, items in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(type.localizedName)
                                .font(.title3.bold())
                                .fontDesign(.rounded)
                                .padding(.horizontal)

                            LazyVGrid(columns: GridColumns.ingredients, spacing: 10) {
                                ForEach(items) { ingredient in
                                    pickerCell(for: ingredient)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else {
                    LazyVGrid(columns: GridColumns.ingredients, spacing: 10) {
                        ForEach(filtered) { ingredient in
                            pickerCell(for: ingredient)
                        }
                        if showAddSuggestion {
                            addCell
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search ingredients")
        .navigationTitle("Select Ingredient")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $pendingName) { name in
            IngredientEditView(suggestedName: name) { created in
                selection = IngredientDraft(from: created)
                onPicked()
            }
        }
    }

    // MARK: - Add Cell

    private var addCell: some View {
        Button {
            pendingName = searchText.trimmingCharacters(in: .whitespaces)
        } label: {
            addIngredientCell(name: searchText.trimmingCharacters(in: .whitespaces))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Picker Cell

    private func pickerCell(for ingredient: Ingredient) -> some View {
        let isSelected = selection.id == ingredient.id

        return Button {
            selection = IngredientDraft(from: ingredient)
            onPicked()
        } label: {
            VStack(spacing: 0) {
                ingredient.displayImage.view(placeholder: ingredient.type.imageName)
                    .scaledToFit()
                    .padding(4)

                Text(ingredient.localizedName)
                    .font(.caption.bold())
                    .fontDesign(.rounded)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
            }
            .padding(.all, 4)
            .frame(maxWidth: .infinity)
            .aspectRatio(0.85, contentMode: .fit)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.tint, lineWidth: 2)
                }
            }
            .glassEffect(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview(traits: .sampleData) {
    @Previewable @State var selection = IngredientDraft()
    NavigationStack {
        IngredientPickerView(selection: $selection)
    }
}
