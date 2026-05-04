import SwiftUI
import SwiftData

struct DebugTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Ingredient.name) private var ingredients: [Ingredient]
    @Query private var cocktails: [Cocktail]
    
    // State to track import errors for the UI
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Statistics Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        statCard(title: "Cocktails", value: "\(cocktails.count)", icon: "wineglass.fill", color: .purple)
                        statCard(title: "Ingredients", value: "\(ingredients.count)", icon: "leaf.fill", color: .green)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Database Controls")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)
                        
                        // MARK: - Action Buttons
                        VStack(spacing: 12) {
                            debugButton(
                                title: "Import EBS Ingredients",
                                subtitle: "Populate dedicated ingredients catalogue",
                                icon: "leaf.fill",
                                color: .green
                            ) {
                                performImport {
                                    try CocktailImporter(context: modelContext)
                                        .importIngredients(from: .ebsInter2023)
                                }
                            }

                            debugButton(
                                title: "Import EBS Library",
                                subtitle: "Populate SwiftData with presets",
                                icon: "square.and.arrow.down.fill",
                                color: .blue
                            ) {
                                performImport {
                                    try CocktailImporter(context: modelContext)
                                        .importAll(from: .ebsInter2023)
                                }
                            }
                            
                            debugButton(
                                title: "Wipe All Data",
                                subtitle: "Delete all cocktails and ingredients",
                                icon: "trash.fill",
                                color: .red
                            ) {
                                wipeData()
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Developer")
            .background(Color(.systemGroupedBackground))
            .alert("Import Failed", isPresented: $showError, actions: {
                    Button("OK", role: .cancel) { }
                }, message: {
                    Text(errorMessage ?? "Unknown error occurred")
                })
        }
    }

    // MARK: - Component Helpers

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

    @ViewBuilder
    private func debugButton(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(color.gradient)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding()
        }
        .buttonStyle(.plain) // Removes the default gray flash
        .glassEffect()
    }
    
    // MARK: - Logic Helpers
    
    private func performImport(_ action: () throws -> Void) {
            do {
                try action()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }

        private func wipeData() {
            // SwiftData handles cascading deletes if your relationships are set up with .cascade
            // Otherwise, deleting the parent (Cocktail) is usually enough
            for cocktail in cocktails {
                modelContext.delete(cocktail)
            }
            for ingredient in ingredients {
                modelContext.delete(ingredient)
            }
            
            try? modelContext.save()
        }
}

#Preview {
    DebugTab()
        .modelContainer(PreviewSampleData.container)
}
