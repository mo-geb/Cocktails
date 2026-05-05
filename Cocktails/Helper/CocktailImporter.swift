import Foundation
import SwiftData
import OSLog

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

// MARK: - Import Result

struct ImportResult {
    let ingredientsInserted: Int
    let ingredientsSkipped: Int
    let cocktailsInserted: Int
    let unmappedIngredientRefs: [(cocktail: String, ingredientName: String)]

    var summary: String {
        var lines = [
            "Cocktails inserted: \(cocktailsInserted)",
            "Ingredients inserted: \(ingredientsInserted)",
            "Ingredients already present (skipped): \(ingredientsSkipped)"
        ]
        if !unmappedIngredientRefs.isEmpty {
            lines.append("⚠️ Unresolved ingredient refs: \(unmappedIngredientRefs.count)")
            for ref in unmappedIngredientRefs {
                lines.append("  • \(ref.cocktail) → \"\(ref.ingredientName)\"")
            }
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Importer

private let logger = Logger(subsystem: "dev.mog.cocktails", category: "CocktailImporter")

@MainActor
final class CocktailImporter {

    enum ImportError: LocalizedError {
        case fileNotFound(String)
        case decodingError(String, Error)

        var errorDescription: String? {
            switch self {
            case .fileNotFound(let name):
                return "File not found in bundle: \(name).json"
            case .decodingError(let label, let underlying):
                return "Failed to decode '\(label)': \(underlying.localizedDescription)"
            }
        }
    }

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Use Cases

    /// 1. Import ONLY ingredients from a given source
    @discardableResult
    func importIngredients(from source: RecipeSource) throws -> ImportResult {
        let url = try getURL(for: source, suffix: "_ingredients")
        let dtos = try parse([IngredientDTO].self, from: url, label: "ingredients")
        var existingIngredients = try fetchExistingIngredientsMap()

        logger.info("Found \(dtos.count) ingredient DTOs; \(existingIngredients.count) already in store")

        var inserted = 0
        var skipped = 0
        for dto in dtos {
            if existingIngredients[dto.id] == nil {
                let ingredient = Ingredient(name: dto.name, type: dto.type)
                ingredient.id = dto.id
                context.insert(ingredient)
                existingIngredients[dto.id] = ingredient
                inserted += 1
                logger.debug("  + Inserted ingredient: \(dto.id) (\(dto.name))")
            } else {
                skipped += 1
                logger.debug("  ~ Skipped existing ingredient: \(dto.id)")
            }
        }

        logger.info("Saving — inserted \(inserted), skipped \(skipped)")
        try context.save()

        let result = ImportResult(ingredientsInserted: inserted, ingredientsSkipped: skipped, cocktailsInserted: 0, unmappedIngredientRefs: [])
        logger.info("Import complete:\n\(result.summary)")
        return result
    }

    /// 2. Import ALL cocktails and ALL ingredients at once for a given source
    @discardableResult
    func importAll(from source: RecipeSource) throws -> ImportResult {
        let ingredientsURL = try getURL(for: source, suffix: "_ingredients")
        let cocktailsURL = try getURL(for: source, suffix: "_cocktails")

        let ingredientDTOs = try parse([IngredientDTO].self, from: ingredientsURL, label: "ingredients")
        let cocktailDTOs = try parse([CocktailDTO].self, from: cocktailsURL, label: "cocktails")

        logger.info("Parsed \(ingredientDTOs.count) ingredients, \(cocktailDTOs.count) cocktails from '\(source.filePrefix)'")

        return try processImport(cocktailDTOs: cocktailDTOs, ingredientDTOs: ingredientDTOs, importAllIngredients: true, source: source)
    }

    /// 3. Import selected cocktails with ONLY their necessary ingredients for a given source
    @discardableResult
    func importSelectedCocktails(names: [String], from source: RecipeSource) throws -> ImportResult {
        let ingredientsURL = try getURL(for: source, suffix: "_ingredients")
        let cocktailsURL = try getURL(for: source, suffix: "_cocktails")

        let ingredientDTOs = try parse([IngredientDTO].self, from: ingredientsURL, label: "ingredients")
        let allCocktailDTOs = try parse([CocktailDTO].self, from: cocktailsURL, label: "cocktails")

        let selectedCocktails = allCocktailDTOs.filter { names.contains($0.name) }
        logger.info("Selected \(selectedCocktails.count)/\(allCocktailDTOs.count) cocktails by name filter")

        return try processImport(cocktailDTOs: selectedCocktails, ingredientDTOs: ingredientDTOs, importAllIngredients: false, source: source)
    }

    // MARK: - Core Logic

    @discardableResult
    private func processImport(cocktailDTOs: [CocktailDTO], ingredientDTOs: [IngredientDTO], importAllIngredients: Bool, source: RecipeSource) throws -> ImportResult {
        var existingIngredients = try fetchExistingIngredientsMap()
        logger.info("Store already has \(existingIngredients.count) ingredients")

        let neededIngredientIDs: Set<String>
        if importAllIngredients {
            neededIngredientIDs = Set(ingredientDTOs.map { $0.id })
        } else {
            neededIngredientIDs = Set(cocktailDTOs.flatMap { $0.ingredients.map { $0.ingredientName } })
        }
        logger.info("Need \(neededIngredientIDs.count) ingredient IDs for this import")

        // 1. Insert needed ingredients that do not exist yet
        var ingredientsInserted = 0
        var ingredientsSkipped = 0
        for dto in ingredientDTOs where neededIngredientIDs.contains(dto.id) {
            if existingIngredients[dto.id] == nil {
                let ingredient = Ingredient(name: dto.name, type: dto.type)
                ingredient.id = dto.id
                context.insert(ingredient)
                existingIngredients[dto.id] = ingredient
                ingredientsInserted += 1
                logger.debug("  + Inserted ingredient: \(dto.id) (\(dto.name))")
            } else {
                ingredientsSkipped += 1
            }
        }
        logger.info("Ingredients — inserted: \(ingredientsInserted), skipped: \(ingredientsSkipped)")

        // Warn about any ingredient IDs referenced by cocktails but absent from the ingredients file
        let definedIDs = Set(ingredientDTOs.map { $0.id })
        let undefinedIDs = neededIngredientIDs.subtracting(definedIDs)
        if !undefinedIDs.isEmpty {
            logger.warning("⚠️ \(undefinedIDs.count) ingredient ID(s) referenced in cocktails but missing from ingredients file: \(undefinedIDs.sorted().joined(separator: ", "))")
        }

        // 2. Insert Cocktails
        var unmappedRefs: [(cocktail: String, ingredientName: String)] = []
        for dto in cocktailDTOs {
            logger.debug("Processing cocktail: \(dto.name)")
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
                } else {
                    unmappedRefs.append((cocktail: dto.name, ingredientName: ingDTO.ingredientName))
                    logger.warning("  ⚠️ \(dto.name): no Ingredient found for id '\(ingDTO.ingredientName)'")
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

        logger.info("Saving \(cocktailDTOs.count) cocktails…")
        try context.save()

        let result = ImportResult(
            ingredientsInserted: ingredientsInserted,
            ingredientsSkipped: ingredientsSkipped,
            cocktailsInserted: cocktailDTOs.count,
            unmappedIngredientRefs: unmappedRefs
        )
        logger.info("Import complete:\n\(result.summary)")
        return result
    }

    // MARK: - Helpers

    private func getURL(for source: RecipeSource, suffix: String) throws -> URL {
        let fileName = "\(source.filePrefix)\(suffix)"
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            logger.error("File not found in bundle: \(fileName).json")
            throw ImportError.fileNotFound(fileName)
        }
        logger.debug("Resolved file: \(url.lastPathComponent)")
        return url
    }

    private func parse<T: Decodable>(_ type: T.Type, from url: URL, label: String) throws -> T {
        logger.debug("Parsing \(label) from \(url.lastPathComponent)")
        let data = try Data(contentsOf: url)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch let decodingError as DecodingError {
            let detail = decodingErrorDetail(decodingError)
            logger.error("Decoding '\(label)' failed: \(detail)")
            throw ImportError.decodingError(label, decodingError)
        }
    }

    private func decodingErrorDetail(_ error: DecodingError) -> String {
        switch error {
        case .typeMismatch(let type, let ctx):
            return "Type mismatch — expected \(type) at \(ctx.codingPath.map(\.stringValue).joined(separator: ".")): \(ctx.debugDescription)"
        case .valueNotFound(let type, let ctx):
            return "Missing value — expected \(type) at \(ctx.codingPath.map(\.stringValue).joined(separator: ".")): \(ctx.debugDescription)"
        case .keyNotFound(let key, let ctx):
            return "Missing key '\(key.stringValue)' at \(ctx.codingPath.map(\.stringValue).joined(separator: ".")): \(ctx.debugDescription)"
        case .dataCorrupted(let ctx):
            return "Data corrupted at \(ctx.codingPath.map(\.stringValue).joined(separator: ".")): \(ctx.debugDescription)"
        @unknown default:
            return error.localizedDescription
        }
    }

    private func fetchExistingIngredientsMap() throws -> [String: Ingredient] {
        let ingredients = try context.fetch(FetchDescriptor<Ingredient>())
        return Dictionary(uniqueKeysWithValues: ingredients.map { ($0.id, $0) })
    }
}

