import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            // Ambient colorful background to showcase glass refraction
            backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                // Wrap sections in a GlassEffectContainer to allow fluid blending/morphing
                GlassEffectContainer(spacing: 24) {
                    VStack(spacing: 24) {
                        heroSection
                        featuresSection
                        getStartedButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                }
                .containerRelativeFrame(.vertical, alignment: .center)
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                .purple.opacity(0.12),
                .mint.opacity(0.08),
                .green.opacity(0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Sections

    private var heroSection: some View {
        VStack(spacing: 20) {
            Image("Glass/Empty/martini")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)

            VStack(spacing: 8) {
                Text("Welcome to Cocktails")
                    .font(.title2.bold())
                    .fontDesign(.rounded)

                Text("Your personal bar book. Here's what you can do to get started.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .glassCard()
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 28) {
            featureRow(
                icon: "leaf.fill",
                color: .green,
                title: "Stock your bar instantly",
                subtitle: "Go to Settings → Import Library and import all preset ingredients to get started"
            )
            featureRow(
                icon: "square.and.arrow.down.fill",
                color: .mint,
                title: "Get recipes or create your own",
                subtitle: "Browse curated cocktail libraries or build your own recipes from scratch"
            )
            featureRow(
                icon: "wineglass.fill",
                color: .purple,
                title: "See what you can make",
                subtitle: "Select the ingredients you have and discover which cocktails you can mix right now"
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .glassCard()
    }

    private var getStartedButton: some View {
        Button {
            appState.dismissOnboarding()
        } label: {
            Text("Get Started")
                .font(.body.bold())
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
    }

    // MARK: - Helpers

    private func featureRow(icon: String, color: Color, title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.bold())
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
