import AppIntents
import SwiftData

/// Answers "what can I make?" without opening the app — Siri/Spotlight speak the
/// result and Shortcuts receives the names for chaining.
struct MakeableCocktailsIntent: AppIntent {
    static let title: LocalizedStringResource = "What Can I Make?"
    static let description = IntentDescription(
        "Find out which cocktails you can make with your stocked ingredients."
    )

    @Dependency private var modelContainer: ModelContainer

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<[String]> {
        let descriptor = FetchDescriptor<Cocktail>(sortBy: [SortDescriptor(\.name)])
        let cocktails = (try? modelContainer.mainContext.fetch(descriptor)) ?? []
        let names = cocktails.filter(\.isMakeable).map(\.name)

        let dialog: IntentDialog
        switch names.count {
        case 0:
            dialog = "You can't make any cocktails yet. Stock some ingredients first."
        case 1...5:
            dialog = "You can make \(names.formatted(.list(type: .and)))."
        default:
            let preview = Array(names.prefix(3)).formatted(.list(type: .and))
            dialog = "You can make \(names.count) cocktails, including \(preview)."
        }

        return .result(value: names, dialog: dialog)
    }
}

/// Opens the app straight into the new-cocktail editor.
struct AddCocktailIntent: AppIntent {
    static let title: LocalizedStringResource = "Add a Cocktail"
    static let description = IntentDescription("Start adding a new cocktail to your bar.")
    static let openAppWhenRun = true

    @Dependency private var appState: AppState

    @MainActor
    func perform() async throws -> some IntentResult {
        appState.selectedTab = .cocktails
        appState.addCocktail()
        return .result()
    }
}

struct CocktailShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: MakeableCocktailsIntent(),
            phrases: [
                "What can I make in \(.applicationName)",
                "What can I make with \(.applicationName)",
                "What cocktails can I make in \(.applicationName)",
                "What cocktails can I make with \(.applicationName)",
                "Which cocktails can I make in \(.applicationName)",
                "Makeable cocktails in \(.applicationName)"
            ],
            shortTitle: "What Can I Make?",
            systemImageName: "wineglass"
        )
        AppShortcut(
            intent: AddCocktailIntent(),
            phrases: [
                "Add a cocktail in \(.applicationName)",
                "Add a cocktail to \(.applicationName)"
            ],
            shortTitle: "Add Cocktail",
            systemImageName: "plus"
        )
    }
}
