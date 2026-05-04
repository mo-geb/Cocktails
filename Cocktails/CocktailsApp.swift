//
//  CocktailsApp.swift
//  Cocktails
//
//  Created by mo on 19.04.26.
//

import SwiftUI
import SwiftData

@main
struct CocktailsApp: App {    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Cocktail.self,
            RecipeIngredient.self,
            Ingredient.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            print(URL.libraryDirectory.path)
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}

#Preview {
    MainTabView()
        .modelContainer(PreviewSampleData.container)
}
