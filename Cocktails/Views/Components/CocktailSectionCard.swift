import SwiftUI

struct CocktailSectionCard<Header: View, Content: View>: View {
    @ViewBuilder var header: () -> Header
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header()
            Divider()
            content()
        }
        .padding(20)
        .glassEffect(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

extension CocktailSectionCard where Header == Text {
    init(title: LocalizedStringKey, @ViewBuilder content: @escaping () -> Content) {
        self.header = { Text(title).font(.title3.bold()).fontDesign(.rounded) }
        self.content = content
    }
}
