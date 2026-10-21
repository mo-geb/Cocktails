import SwiftUI

/// A cocktail's artwork on a drink-tinted panel. Custom photos fill the panel;
/// illustrations are fitted and nudged up, since their visual weight sits low
/// (glass base, shadow) and a geometric center reads as too low.
struct CocktailArtWell: View {
    let image: DisplayImageSource
    let placeholder: String
    let tint: Color?
    var artSize: CGFloat = 116
    var verticalPadding: CGFloat = 11

    var body: some View {
        ZStack {
            if image.isCustom {
                image.view(placeholder: placeholder)
                    .scaledToFill()
            } else {
                image.view(placeholder: placeholder)
                    .scaledToFit()
                    .frame(height: artSize)
                    .offset(y: -artSize * 0.05)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(height: artSize + verticalPadding * 2)
        .background((tint ?? .gray).adaptiveTint(lightOpacity: 0.2, darkOpacity: 0.35))
        .clipShape(ConcentricRectangle(corners: .concentric(minimum: 14), isUniform: true))
    }
}
