import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    heroSection
                    featuresSection
                    actionSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: store.isUnlimited) { _, unlimited in
                if unlimited { dismiss() }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") { dismiss() }
                }
            }
        }
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
        .glassEffect(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            featureRow(icon: "infinity", color: .purple, title: "Unlimited cocktails", subtitle: "Add and import as many as you want")
            featureRow(icon: "square.and.arrow.down.fill", color: .blue, title: "Full library access", subtitle: "Import complete cocktail collections")
            featureRow(icon: "star.fill", color: .orange, title: "One-time purchase", subtitle: "Pay once, yours forever — no subscription")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .glassEffect(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var actionSection: some View {
        VStack(spacing: 12) {
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
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(store.product == nil || store.purchaseInFlight)

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
            return "Unlock Unlimited · \(price)"
        }
        return "Unlock Unlimited"
    }

    // MARK: - Helpers

    private func featureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
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
