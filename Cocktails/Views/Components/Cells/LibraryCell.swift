import SwiftUI

struct LibraryCell: View {
    let source: RecipeSource
    let counts: LibraryCounts

    @State private var accentColor: Color?

    var body: some View {
        ZStack(alignment: .bottom) {
            if let accentColor {
                LinearGradient(
                    colors: [
                        accentColor.adaptiveTint(lightOpacity: 0.35, darkOpacity: 0.5),
                        accentColor.adaptiveTint(lightOpacity: 0.1, darkOpacity: 0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }

            VStack(spacing: 0) {
                Image(source.imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 12)
                    .padding(.bottom, -16)

                VStack(spacing: 0) {
                    Text(source.localizedName)
                        .font(.headline)
                        .padding(.bottom, 8)

                    HStack(spacing: 5) {
                        Image("Glass/Filled/martini")
                            .resizable()
                            .scaledToFit()
                            .scaledFrame(12, relativeTo: .caption2)
                        Text("\(counts.cocktails)")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background((accentColor ?? .gray).adaptiveTint(lightOpacity: 0.3, darkOpacity: 0.45), in: Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.8, contentMode: .fit)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onAppear {
            if let uiImage = UIImage(named: source.imageName) {
                accentColor = uiImage.dominantColor().map { Color($0) }
            }
        }
    }
}

#Preview {
    ScrollView {
        AdaptiveGrid(.libraries) {
            LibraryCell(source: .ebsInter2023, counts: LibraryCounts(cocktails: 42))
            LibraryCell(source: .custom, counts: LibraryCounts(cocktails: 7))
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
