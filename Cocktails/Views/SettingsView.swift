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
    @State private var linkButtonWidth: CGFloat = 100

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Grid(horizontalSpacing: 12) {
                        GridRow {
                            statCard(icon: "wineglass.fill", color: .purple, value: cocktails.count, title: "Cocktails")
                            statCard(icon: "leaf.fill", color: .green, value: ingredients.count, title: "Ingredients")
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0))
                }

                upgradeSection
                importSection
                dataSection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .fullScreenCover(isPresented: $showPaywall) { PaywallView() }
            .restoreOutcomeAlert(store)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var upgradeSection: some View {
        Section("Unlimited") {
            if store.isUnlimited {
                HStack {
                    settingsLabel(icon: "infinity", color: .green,
                                  title: "Unlimited Cocktails",
                                  subtitle: "Thanks for your support")
                    Spacer()
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                }
            } else {
                Button { showPaywall = true } label: {
                    settingsLabel(icon: "infinity", color: .purple,
                                  title: "Unlimited Cocktails",
                                  subtitle: "Unlock more than \(StoreManager.freeCocktailLimit) cocktails")
                }

                Button {
                    Task { await store.restore() }
                } label: {
                    HStack {
                        settingsLabel(icon: "arrow.clockwise", color: .gray,
                                      title: "Restore Purchases",
                                      subtitle: "Already bought? Restore here")
                        if store.restoreInFlight {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(store.restoreInFlight)
            }
        }
    }

    private var importSection: some View {
        Section("Libraries") {
            NavigationLink(destination: RecipeLibrariesView()) {
                settingsLabel(icon: "square.and.arrow.down.fill", color: .mint,
                              title: "Import Library",
                              subtitle: "Browse and add cocktail collections")
            }
        }
    }

    private var aboutSection: some View {
        Section {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    linkButton(url: Links.website, icon: "globe", title: "Website")
                    linkButton(url: Links.terms, icon: "doc.text", title: "Terms")
                    linkButton(url: Links.privacy, icon: "hand.raised", title: "Privacy")
                }
                .background {
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { linkButtonWidth = (geo.size.width - 24) / 3 }
                            .onChange(of: geo.size.width) { _, newWidth in
                                linkButtonWidth = (newWidth - 24) / 3
                            }
                    }
                }

                HStack(spacing: 12) {
                    linkButton(url: Links.guide, icon: "book", title: "Guide")
                        .frame(width: linkButtonWidth)
                    linkButton(url: Links.support, icon: "envelope", title: "Support")
                        .frame(width: linkButtonWidth)
                }
                .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 8, trailing: 20))
        } header: {
            Text("More")
        } footer: {
            Text(Bundle.main.fullVersionString)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
    }

    private func linkButton(url: URL, icon: String, title: LocalizedStringKey) -> some View {
        Link(destination: url) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(.tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var dataSection: some View {
        Section {
            Button { showClearConfirmation = true } label: {
                settingsLabel(icon: "trash.fill", color: .red,
                              title: "Clear Data",
                              subtitle: "Remove cocktails or ingredients")
            }
            .confirmationDialog("Clear Data", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                Button("Clear Unused Ingredients", role: .destructive) { clearUnusedIngredients() }
                Button("Delete Imported Cocktails", role: .destructive) { deleteImportedCocktails() }
                Button("Delete Everything", role: .destructive) { deleteEverything() }
            } message: {
                Text("Choose what to delete. This cannot be undone.")
            }
        } header: {
            Text("Data")
        }
    }

    // MARK: - Row helpers

    private func iconTile(_ icon: String, _ color: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(color.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    private func settingsLabel(icon: String, color: Color, title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
        HStack(spacing: 12) {
            iconTile(icon, color)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .foregroundStyle(Color.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
        }
    }

    private func statCard(icon: String, color: Color, value: Int, title: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("\(value)")
                    .font(.system(.title, design: .rounded).bold())
                    .monospacedDigit()
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
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

    // MARK: - URLs

    private enum Links {
        static let website    = URL(string: "https://mo-geb.com/apps/cocktails")!
        static let terms      = URL(string: "https://mo-geb.com/apps/cocktails/terms")!
        static let privacy    = URL(string: "https://mo-geb.com/apps/cocktails/privacy")!
        static let guide      = URL(string: "https://mo-geb.com/apps/cocktails/guide")!
        static let support    = URL(string: "mailto:support@mo-geb.com")!
    }
}

#Preview("Unlimited", traits: .sampleData) {
    SettingsView()
        .environment(StoreManager(isUnlimited: true))
}

#Preview("Free", traits: .sampleData) {
    SettingsView()
        .environment(StoreManager(isUnlimited: false))
}
