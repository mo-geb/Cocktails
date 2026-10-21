import SwiftUI

/// A white SF Symbol on a rounded gradient tile, as used in Settings-style rows.
struct IconTile: View {
    let systemImage: String
    let color: Color
    var size: CGFloat = 40
    var textStyle: Font.TextStyle = .title3
    var weight: Font.Weight = .regular

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(textStyle, weight: weight))
            .foregroundStyle(.white)
            .scaledFrame(size, relativeTo: textStyle)
            .background(color.gradient)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous))
    }
}

/// A tappable card: icon tile, title and subtitle, and a trailing accessory
/// such as a chevron or progress indicator.
struct ActionCard<Trailing: View>: View {
    let systemImage: String
    let color: Color
    let title: Text
    let subtitle: Text
    let action: () -> Void
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                IconTile(systemImage: systemImage, color: color)

                VStack(alignment: .leading, spacing: 2) {
                    title
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    subtitle
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                trailing()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .cardBackground(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }
}
