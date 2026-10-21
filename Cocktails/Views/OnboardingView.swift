import SwiftUI

/// Apple-style welcome screen: large title, plain feature list, and the
/// actions pinned to the bottom.
struct OnboardingView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                VStack(spacing: 20) {
                    Image("Cocktail/espresso_martini")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .accessibilityHidden(true)

                    Text("Welcome to ClutterFree Cocktails")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 48)

                VStack(alignment: .leading, spacing: 28) {
                    feature(icon: "leaf.fill", color: .green,
                            title: "Stock your bar instantly",
                            subtitle: "Import the preset ingredients, then tick off what's in your bar")
                    feature(icon: "square.and.arrow.down.fill", color: .mint,
                            title: "Get recipes or create your own",
                            subtitle: "Browse curated cocktail libraries or build your own recipes from scratch")
                    feature(icon: "wineglass.fill", color: .purple,
                            title: "See what you can make",
                            subtitle: "Select the ingredients you have and discover which cocktails you can mix right now")
                }
                .padding(.horizontal, 8)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        // The button stays pinned at the bottom, as in Apple's welcome screens.
        .safeAreaInset(edge: .bottom) {
            Button {
                appState.dismissOnboarding()
            } label: {
                Text("Get Started")
                    .font(.body.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
    }

    /// An Apple welcome-screen feature row: a large tinted symbol, no tile.
    private func feature(icon: String, color: Color, title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
        HStack(alignment: .center, spacing: 18) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(color)
                .scaledFrame(48, relativeTo: .largeTitle)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
