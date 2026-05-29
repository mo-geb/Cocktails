import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var store

    @State private var celebrate = false

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
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
            .navigationTitle("Go Unlimited")
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
            Image("Glass/Filled/martini")
                .resizable()
                .scaledToFit()
                .frame(width: 108, height: 108)

            VStack(spacing: 8) {
                Text("Go Unlimited")
                    .font(.title2.bold())
                    .fontDesign(.rounded)

                Text("Your bar, no limits. Save as many cocktails as you like with a single purchase.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .glassCard()
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 28) {
            FeatureRow(icon: "infinity", color: .purple, title: "Unlimited cocktails", subtitle: "Add and import as many as you want")
            FeatureRow(icon: "square.and.arrow.down.fill", color: .blue, title: "Full library access", subtitle: "Import complete cocktail collections")
            FeatureRow(icon: "heart.fill", color: .pink, title: "Support indie development", subtitle: "Made by one person who loves cocktails")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .glassCard()
    }

    private var actionSection: some View {
        VStack(spacing: 16) {
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

                Text("One-time purchase · No subscription")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if store.product != nil || !store.isLoadingProduct {
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
    }

    private var purchaseLabel: String {
        if let price = store.product?.displayPrice {
            return String(localized: "Unlock Unlimited · \(price)", comment: "Paywall purchase button — price inserted by the OS")
        }
        return String(localized: "Unlock Unlimited", comment: "Paywall purchase button — no price available")
    }

}

#Preview {
    PaywallView()
        .environment(StoreManager())
}
