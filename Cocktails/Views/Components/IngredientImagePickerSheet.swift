import SwiftUI

struct IngredientImagePickerSheet: View {
    @Binding var selectedImageName: String?
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(CocktailImporter.availableIngredientImageNames, id: \.self) { name in
                        imageCell(name: name)
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if selectedImageName != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Use Default") {
                            selectedImageName = nil
                            dismiss()
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func imageCell(name: String) -> some View {
        let isSelected = selectedImageName == name
        Button {
            selectedImageName = name
            dismiss()
        } label: {
            Image("Ingredient/" + name)
                .resizable()
                .scaledToFit()
                .padding(8)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2.5)
                )
        }
        .buttonStyle(.plain)
    }
}
