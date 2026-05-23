import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var store
    @Query private var cocktails: [Cocktail]
    @Query(sort: \Ingredient.name) private var ingredients: [Ingredient]

    @State private var showClearConfirmation = false
    @State private var showPaywall = false
    @State private var celebrate = false

    var body: some View {
        NavigationStack {
            ScrollView {
                GlassEffectContainer {
                    VStack(spacing: 28) {
                        Grid(horizontalSpacing: 16) {
                            GridRow {
                                statCard(title: "Cocktails", value: "\(cocktails.count)", icon: "wineglass.fill", color: .purple)
                                statCard(title: "Ingredients", value: "\(ingredients.count)", icon: "leaf.fill", color: .green)
                            }
                        }
                        
                        
                        upgradeSection
                        importSection
                        aboutSection
                        dataSection
                        
                        
                        HStack {
                            Spacer()
                            Text(Bundle.main.fullVersionString)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .overlay { if celebrate { ConfettiView() } }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Clear Data", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                Button("Clear Unused Ingredients", role: .destructive) { clearUnusedIngredients() }
                Button("Delete Imported Cocktails", role: .destructive) { deleteImportedCocktails() }
                Button("Delete Everything", role: .destructive) { deleteEverything() }
            } message: {
                Text("Choose what to delete. This cannot be undone.")
            }
        }
    }

    // MARK: - Sections

    private var upgradeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Unlimited")
            VStack(spacing: 0) {
                if store.isUnlimited {
                    row(icon: "infinity", color: .purple,
                        title: "Unlimited Cocktails",
                        subtitle: "Thanks for your support",
                        trailing: AnyView(
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                        ))
                } else {
                    Button { showPaywall = true } label: {
                        row(icon: "infinity", color: .purple,
                            title: "Unlimited Cocktails",
                            subtitle: "Unlock more than \(StoreManager.freeCocktailLimit) cocktails")
                    }
                    .buttonStyle(.plain)
                    
                    Divider().padding(.leading, 62)
                    
                    Button {
                        Task {
                            let wasUnlimited = store.isUnlimited
                            await store.restore()
                            if !wasUnlimited && store.isUnlimited {
                                celebrate = true
                                try? await Task.sleep(for: .seconds(3.5))
                                celebrate = false
                            }
                        }
                    } label: {
                        row(icon: "arrow.clockwise", color: .gray,
                            title: "Restore Purchases",
                            subtitle: "Already bought? Restore here",
                            trailing: store.purchaseInFlight ? AnyView(ProgressView().scaleEffect(0.8)) : nil)
                    }
                    .buttonStyle(.plain)
                    .disabled(store.purchaseInFlight)
                }
            }
            .glassEffect(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var importSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Libraries")

            NavigationLink(destination: RecipeLibrariesView()) {
                row(icon: "square.and.arrow.down.fill", color: .blue,
                    title: "Import Library",
                    subtitle: "Browse and add cocktail collections")
            }
            .buttonStyle(.plain)
            .glassEffect(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("More")

            VStack(spacing: 0) {
                Link(destination: URL(string: "https://mo-geb.com")!) {
                    row(icon: "globe", color: .cyan,
                        title: "Website",
                        subtitle: "mo-geb.com",
                    )
                }

                Divider().padding(.leading, 62)

                Link(destination: URL(string: "https://mo-geb.com/projects/cocktails/terms")!) {
                    row(icon: "doc.text", color: .blue,
                        title: "Terms of Service",
                        subtitle: "Read the terms of service",
                    )
                }
                
                Divider().padding(.leading, 62)

                Link(destination: URL(string: "https://mo-geb.com/projects/cocktails/privacy")!) {
                    row(icon: "book", color: .indigo,
                        title: "Privacy Policy",
                        subtitle: "Read the privacy policy",
                    )
                }
                
                Divider().padding(.leading, 62)

                
                Link(destination: URL(string: "mailto:support@mo-geb.com")!) {
                    row(icon: "envelope.fill", color: .purple,
                        title: "Contact Support",
                        subtitle: "support@mo-geb.com",
                    )
                }
            }
            .glassEffect(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Data")

            Button { showClearConfirmation = true } label: {
                row(icon: "trash.fill", color: .red,
                    title: "Clear Data",
                    subtitle: "Remove cocktails or ingredients")
            }
            .buttonStyle(.plain)
            .glassEffect(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionHeader(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.subheadline.bold())
            .fontDesign(.rounded)
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
    }

    @ViewBuilder
    private func row(icon: String, color: Color, title: LocalizedStringKey, subtitle: LocalizedStringKey, trailing: AnyView? = nil) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let trailing {
                trailing
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private func statCard(title: LocalizedStringKey, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(.title, design: .rounded).bold())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Data actions

    private func clearUnusedIngredients() {
        for ingredient in ingredients where ingredient.usages?.isEmpty ?? true {
            modelContext.delete(ingredient)
        }
        try? modelContext.save()
    }

    private func deleteImportedCocktails() {
        for cocktail in cocktails where cocktail.source != .custom {
            modelContext.delete(cocktail)
        }
        try? modelContext.save()
    }

    private func deleteEverything() {
        cocktails.forEach { modelContext.delete($0) }
        ingredients.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
}

#Preview(traits: .sampleData) {
    NavigationStack {
        SettingsView()
            .environment(StoreManager())
    }
}
