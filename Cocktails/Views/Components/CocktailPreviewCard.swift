import SwiftUI

struct CocktailPreviewCard: View {
    let dto: CocktailDTO
    let isSelected: Bool
    let isImported: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

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
                            .minimumScaleFactor(0.85)

                        HStack(spacing: 0) {
                            HStack(spacing: 5) {
                                Image(dto.ice.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 12, height: 12)
                                Text(dto.ice.localizedName)
                            }
                            .frame(maxWidth: .infinity)

                            Divider().frame(height: 12)

                            HStack(spacing: 5) {
                                Image(dto.method.customImageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 12, height: 12)
                                Text(dto.method.localizedName)
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

                Image(systemName: isImported || isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isImported ? .secondary : (isSelected ? Color.accentColor : Color.primary.opacity(0.3)))
                    .padding(10)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(0.85, contentMode: .fit)
            .glassEffect(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                if isImported {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.6))
                } else if isSelected {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 2.5)
                }
            }
        }
        .buttonStyle(CardPressStyle(scale: 1.06))
        .disabled(isImported)
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
            CocktailPreviewCard(dto: dto, isSelected: false, isImported: false) {}
            CocktailPreviewCard(dto: dto, isSelected: true, isImported: false) {}
            CocktailPreviewCard(dto: dto, isSelected: false, isImported: true) {}
        }
        .padding()
    }
}
