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
            AdaptiveGrid(.ingredients) {
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
        .background(Color(.systemGroupedBackground))
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
            IngredientCard(name: ingredient.localizedName) {
                ingredient.displayImage.view(placeholder: ingredient.type.imageName)
                    .scaledToFit()
                    .padding(4)
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 2.5)
                }
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
