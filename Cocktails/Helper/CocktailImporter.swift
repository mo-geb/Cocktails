import Foundation
import SwiftData

// MARK: - DTOs

struct IngredientDTO: Decodable {
    let id: String
    let name: String
    let type: IngredientType
}

struct RecipeIngredientDTO: Decodable {
    let ingredientName: String
    let amount: Double
    let unit: MeasurementUnit?
    let note: String?
}

struct CocktailDTO: Decodable {
    let name: String
    let imageName: String?
    let glass: GlassType
    let method: PreparationMethod
    let ice: IceType
    let ingredients: [RecipeIngredientDTO]
    let notes: String?
}

// MARK: - Importer

@MainActor
final class CocktailImporter {
    
    enum ImportError: Error {
        case fileNotFound(String)
        case decodingError(Error)
    }
    
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // MARK: - Use Cases
    
    /// 1. Import ONLY ingredients from a given source
    func importIngredients(from source: RecipeSource) throws {
        let url = try getURL(for: source, suffix: "_ingredients")
        let dtos = try parse([IngredientDTO].self, from: url)
        var existingIngredients = try fetchExistingIngredientsMap()
        
        for dto in dtos {
            if existingIngredients[dto.id] == nil {
                let ingredient = Ingredient(name: dto.name, type: dto.type)
                ingredient.id = dto.id
                context.insert(ingredient)
                existingIngredients[dto.id] = ingredient
            }
        }
        
        try context.save()
    }
    
    /// 2. Import ALL cocktails and ALL ingredients at once for a given source
    func importAll(from source: RecipeSource) throws {
        let ingredientsURL = try getURL(for: source, suffix: "_ingredients")
        let cocktailsURL = try getURL(for: source, suffix: "_cocktails")
        
        let ingredientDTOs = try parse([IngredientDTO].self, from: ingredientsURL)
        let cocktailDTOs = try parse([CocktailDTO].self, from: cocktailsURL)
        
        try processImport(cocktailDTOs: cocktailDTOs, ingredientDTOs: ingredientDTOs, importAllIngredients: true, source: source)
    }
    
    /// 3. Import selected cocktails with ONLY their necessary ingredients for a given source
    func importSelectedCocktails(names: [String], from source: RecipeSource) throws {
        let ingredientsURL = try getURL(for: source, suffix: "_ingredients")
        let cocktailsURL = try getURL(for: source, suffix: "_cocktails")
        
        let ingredientDTOs = try parse([IngredientDTO].self, from: ingredientsURL)
        let allCocktailDTOs = try parse([CocktailDTO].self, from: cocktailsURL)
        
        // Filter cocktails based on the selected names
        let selectedCocktails = allCocktailDTOs.filter { names.contains($0.name) }
        
        try processImport(cocktailDTOs: selectedCocktails, ingredientDTOs: ingredientDTOs, importAllIngredients: false, source: source)
    }
    
    // MARK: - Core Logic
    
    private func processImport(cocktailDTOs: [CocktailDTO], ingredientDTOs: [IngredientDTO], importAllIngredients: Bool, source: RecipeSource) throws {
        var existingIngredients = try fetchExistingIngredientsMap()
        
        // Determine which ingredients we actually need to insert
        let neededIngredientIDs: Set<String>
        if importAllIngredients {
            neededIngredientIDs = Set(ingredientDTOs.map { $0.id })
        } else {
            neededIngredientIDs = Set(cocktailDTOs.flatMap { $0.ingredients.map { $0.ingredientName } })
        }
        
        // 1. Insert needed ingredients that do not exist yet
        for dto in ingredientDTOs where neededIngredientIDs.contains(dto.id) {
            if existingIngredients[dto.id] == nil {
                let ingredient = Ingredient(name: dto.name, type: dto.type)
                ingredient.id = dto.id
                context.insert(ingredient)
                existingIngredients[dto.id] = ingredient
            }
        }
        
        // 2. Insert Cocktails
        for dto in cocktailDTOs {
            var recipeIngredients: [RecipeIngredient] = []
            
            for ingDTO in dto.ingredients {
                let unit = ingDTO.unit ?? .piece
                
                let recipeIngredient = RecipeIngredient(
                    amount: ingDTO.amount,
                    unit: unit,
                    note: ingDTO.note ?? ""
                )
                
                if let mappedIngredient = existingIngredients[ingDTO.ingredientName] {
                    recipeIngredient.ingredient = mappedIngredient
                }
                
                recipeIngredients.append(recipeIngredient)
            }
            
            let cocktail = Cocktail(
                name: dto.name,
                notes: dto.notes ?? "",
                glass: dto.glass,
                method: dto.method,
                ice: dto.ice,
                source: source,
                imageName: dto.imageName,
                ingredients: recipeIngredients
            )
            
            for ri in recipeIngredients {
                ri.cocktail = cocktail
            }
            
            context.insert(cocktail)
        }
        
        try context.save()
    }
    
    // MARK: - Helpers
    
    private func getURL(for source: RecipeSource, suffix: String) throws -> URL {
        let fileName = "\(source.filePrefix)\(suffix)"
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw ImportError.fileNotFound(fileName)
        }
        return url
    }
    
    private func parse<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    private func fetchExistingIngredientsMap() throws -> [String: Ingredient] {
        let descriptor = FetchDescriptor<Ingredient>()
        let fetchedIngredients = try context.fetch(descriptor)
        
        var map: [String: Ingredient] = [:]
        for ingredient in fetchedIngredients {
            map[ingredient.id] = ingredient
        }
        return map
    }
}

