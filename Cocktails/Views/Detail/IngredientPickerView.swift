import SwiftUI
import SwiftData

struct IngredientPickerView: View {
    @Query(sort: \Ingredient.name) private var allIngredients: [Ingredient]
    @Binding var selection: IngredientDraft

    var onPicked: () -> Void = {}

    var detent: Binding<PresentationDetent> = .constant(.medium)

    @State private var searchText = ""
    @State private var pending: PendingIngredient?

    private var filtered: [Ingredient] {
        guard !searchText.isEmpty else { return allIngredients }
        return allIngredients.filter { $0.localizedName.localizedStandardContains(searchText) }
    }

    private var groupedIngredients: [(IngredientType, [Ingredient])] {
        filtered.groupedByType()
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
            LazyVGrid(columns: GridColumns.ingredients, spacing: 10) {
                if searchText.isEmpty {
                    ForEach(groupedIngredients, id: \.0) { type, items in
                        Section {
                            ForEach(items) { ingredient in
                                pickerCell(for: ingredient)
                            }
                        } header: {
                            Text(type.localizedName)
                                .sectionTitleStyle()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 8)
                        }
                    }
                } else {
                    Section {
                        ForEach(filtered) { ingredient in
                            pickerCell(for: ingredient)
                        }
                        if showAddSuggestion {
                            addCell
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical)
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search ingredients")
        .navigationTitle("Select Ingredient")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $pending) { item in
            NavigationStack {
                IngredientEditView(suggestedName: item.name) { created in
                    selection = IngredientDraft(from: created)
                    pending = nil
                    onPicked()
                }
            }
            .presentationDetents([.medium, .large], selection: detent)
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Add Cell

    private var addCell: some View {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        return Button {
            pending = PendingIngredient(name: trimmed)
        } label: {
            addIngredientCell(name: trimmed)
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
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color(.separator),
                                  lineWidth: isSelected ? 2.5 : 1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - PendingIngredient

    private struct PendingIngredient: Identifiable {
        let id = UUID()
        let name: String
    }
}

#Preview(traits: .sampleData) {
    @Previewable @State var selection = IngredientDraft()
    NavigationStack {
        IngredientPickerView(selection: $selection)
    }
}
