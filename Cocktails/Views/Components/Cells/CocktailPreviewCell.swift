import SwiftUI

struct CocktailPreviewCell: View {
    let dto: CocktailDTO
    let isSelected: Bool
    let isImported: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
                    Spacer()

                    dto.displayImage.view(placeholder: dto.glass.imageNameFilled)
                        .scaledToFit()
                        .padding(.horizontal, 40)

                    Spacer()

                    VStack(spacing: 6) {
                        Text(dto.name)
                            .font(.subheadline.bold())
                            .fontDesign(.rounded)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)

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
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.tertiarySystemFill), in: Capsule())
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 14)
                }

                Image(systemName: isImported || isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isImported ? .secondary : (isSelected ? Color.accentColor : Color.primary.opacity(0.3)))
                    .accessibilityLabel(accessibilityStateLabel)
                    .contentTransition(.symbolEffect(.replace))
                    .animation(.default, value: isImported || isSelected)
                    .padding(6)
            }
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity)
            .aspectRatio(0.85, contentMode: .fit)
            .accessibilityElement(children: .combine)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                if isImported {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.thinMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(isSelected ? Color.accentColor : Color(.separator),
                                      lineWidth: isSelected ? 2.5 : 1)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isImported)
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
}
