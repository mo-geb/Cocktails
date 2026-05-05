import SwiftUI
import SwiftData

struct InventoryTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Ingredient.name) private var ingredients: [Ingredient]
    @Query private var cocktails: [Cocktail]

    var body: some View {
        NavigationStack {
            List {
                ForEach(ingredients) { ingredient in
                    HStack {
                        ingredient.displayImage.view(placeholder: ingredient.type.imageName)
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                        
                        Text(ingredient.name)
                    }
                }
            }
            .navigationTitle("Inventory")
        }
    }

}

#Preview {
    InventoryTab()
        .modelContainer(PreviewSampleData.container)
}
