import SwiftUI

struct LibraryCard: View {
    let source: RecipeSource
    let counts: LibraryCounts

    @Environment(\.colorScheme) private var colorScheme
    @State private var accentColor: Color?

    var body: some View {
        ZStack(alignment: .bottom) {
            if let accentColor {
                LinearGradient(
                    colors: [accentColor, accentColor.opacity(0.15)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .saturation(1.9)
                .blendMode(colorScheme == .dark ? .screen : .normal)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                        .fontDesign(.rounded)
                        .padding(.bottom, 8)

                    HStack(spacing: 5) {
                        Image("Glass/Filled/martini")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                        Text("\(counts.cocktails)")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .glassEffect()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.8, contentMode: .fit)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onAppear {
            if let uiImage = UIImage(named: source.imageName) {
                accentColor = uiImage.dominantColor().map { Color($0) }
            }
        }
    }
}

#Preview {
    ScrollView {
        LazyVGrid(columns: GridColumns.libraries, spacing: 16) {
            LibraryCard(source: .ebsInter2023, counts: LibraryCounts(cocktails: 42))
            LibraryCard(source: .custom, counts: LibraryCounts(cocktails: 7))
        }
        .padding()
    }
}
