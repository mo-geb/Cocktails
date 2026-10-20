import SwiftUI

struct CocktailPreviewCell: View {
    let dto: CocktailDTO
    let isSelected: Bool
    let isImported: Bool
    let onTap: () -> Void

    @State private var bgColor: Color? = nil

    private let cornerRadius: CGFloat = 22
    private let wellArtSize: CGFloat = 116
    private let wellVerticalPadding: CGFloat = 11

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                well
                    .padding(.bottom, 8)

                Text(dto.name)
                    .font(.headline)
                    .fontDesign(.rounded)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Image(dto.ice.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 11, height: 11)
                        .accessibilityHidden(true)
                    Text(dto.ice.localizedName)
                    Text("·").foregroundStyle(.tertiary)
                    Image(dto.method.customImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 11, height: 11)
                        .accessibilityHidden(true)
                    Text(dto.method.localizedName)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
            .padding(8)
            .padding(.bottom, 6)
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .task(id: dto.name) {
                let image = dto.displayImage
                let placeholder = dto.glass.imageNameFilled
                bgColor = await Task.detached(priority: .background) {
                    image.dominantColor(placeholderName: placeholder)
                }.value
            }
            .overlay {
                if isImported {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.thinMaterial)
                } else if isSelected {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 2.5)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isImported)
    }

    @ViewBuilder
    private var well: some View {
        CocktailArtWell(
            image: dto.displayImage,
            placeholder: dto.glass.imageNameFilled,
            tint: bgColor,
            artSize: wellArtSize,
            verticalPadding: wellVerticalPadding
        )
        .overlay(alignment: .topTrailing) {
            Image(systemName: isImported || isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isImported ? .secondary : (isSelected ? Color.accentColor : Color.primary.opacity(0.3)))
                .accessibilityLabel(accessibilityStateLabel)
                .contentTransition(.symbolEffect(.replace))
                .animation(.default, value: isImported || isSelected)
                .padding(8)
        }
    }

    private var accessibilityStateLabel: Text {
        if isImported { Text("Imported") }
        else if isSelected { Text("Selected") }
        else { Text("Not selected") }
    }
}

#Preview {
    let dto = CocktailDTO(
        name: "Espresso Martini",
        imageName: nil,
        glass: .martini,
        method: .shake,
        ice: .none,
        ingredients: [],
        garnishes: nil,
        notes: nil
    )
    ScrollView {
        LazyVGrid(columns: GridColumns.cocktails, spacing: 12) {
            CocktailPreviewCell(dto: dto, isSelected: false, isImported: false) {}
            CocktailPreviewCell(dto: dto, isSelected: true, isImported: false) {}
            CocktailPreviewCell(dto: dto, isSelected: false, isImported: true) {}
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
