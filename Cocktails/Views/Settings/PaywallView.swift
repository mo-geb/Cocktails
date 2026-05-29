import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var store

    @State private var celebrate = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Ambient background gradient to showcase glass refraction
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    // Wrap sections in a GlassEffectContainer to allow fluid blending/morphing
                    GlassEffectContainer(spacing: 24) {
                        VStack(spacing: 24) {
                            heroSection
                            featuresSection
                            actionSection
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                    }
                    .containerRelativeFrame(.vertical, alignment: .center)
                }
            }
            .overlay { if celebrate { ConfettiView() } }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: store.isUnlimited) { _, unlimited in
                guard unlimited else { return }
                celebrate = true
                Task {
                    try? await Task.sleep(for: .seconds(1.8))
                    dismiss()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") { dismiss() }
                }
            }
            .task {
                await store.loadProductIfNeeded()
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                .purple.opacity(0.12),
                .blue.opacity(0.08),
                .orange.opacity(0.12)
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
                Text("Unlimited Cocktails")
                    .font(.title2.bold())
                    .fontDesign(.rounded)
                
                Text("You've reached the free limit of \(StoreManager.freeCocktailLimit) cocktails. Upgrade once to save as many as you like.")
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
        VStack(alignment: .leading, spacing: 20) {
            featureRow(icon: "infinity", color: .purple, title: "Unlimited cocktails", subtitle: "Add and import as many as you want")
            featureRow(icon: "square.and.arrow.down.fill", color: .blue, title: "Full library access", subtitle: "Import complete cocktail collections")
            featureRow(icon: "star.fill", color: .orange, title: "One-time purchase", subtitle: "Pay once, yours forever — no subscription")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .glassCard()
    }

    private var actionSection: some View {
        VStack(spacing: 12) {
            if store.product == nil {
                if store.isLoadingProduct {
                    ProgressView("Loading purchase details...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 8) {
                        Text("Could not load purchase details.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        
                        Button("Retry") {
                            Task {
                                await store.loadProduct()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            } else {
                Button {
                    Task { await store.purchase() }
                } label: {
                    Group {
                        if store.purchaseInFlight {
                            ProgressView()
                        } else {
                            Text(purchaseLabel).font(.body.bold())
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .disabled(store.purchaseInFlight)
            }

            Button {
                Task { await store.restore() }
            } label: {
                Text("Restore Purchases")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .disabled(store.purchaseInFlight)
        }
    }

    private var purchaseLabel: String {
        if let price = store.product?.displayPrice {
            return String(localized: "Unlock Unlimited · \(price)", comment: "Paywall purchase button — price inserted by the OS")
        }
        return String(localized: "Unlock Unlimited", comment: "Paywall purchase button — no price available")
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
    PaywallView()
        .environment(StoreManager())
}
