import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var cocktails: [Cocktail]
    @Query(sort: \Ingredient.name) private var ingredients: [Ingredient]

    @State private var showClearConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        statCard(title: "Cocktails", value: "\(cocktails.count)", icon: "wineglass.fill", color: .purple)
                        statCard(title: "Ingredients", value: "\(ingredients.count)", icon: "leaf.fill", color: .green)
                    }
                    
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

    private var importSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Libraries")

            NavigationLink(destination: ImportLibrariesView()) {
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
            sectionHeader("About")

            VStack(spacing: 0) {
                Link(destination: URL(string: "https://mo-geb.com")!) {
                    row(icon: "globe", color: .indigo,
                        title: "Website",
                        subtitle: "mo-geb.com",
                        trailing: .externalLink)
                }

                Divider().padding(.leading, 62)

                Link(destination: URL(string: "mailto:support@mo-geb.com")!) {
                    row(icon: "envelope.fill", color: .teal,
                        title: "Contact Support",
                        subtitle: "support@mo-geb.com",
                        trailing: .externalLink)
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
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.bold())
            .fontDesign(.rounded)
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
    }

    private enum TrailingIndicator { case chevron, externalLink }

    @ViewBuilder
    private func row(icon: String, color: Color, title: String, subtitle: String,
                     trailing: TrailingIndicator = .chevron) -> some View {
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

            Image(systemName: trailing == .chevron ? "chevron.right" : "arrow.up.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
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
    }
}
