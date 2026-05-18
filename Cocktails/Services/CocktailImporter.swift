import Foundation
import SwiftData
import OSLog

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

    @discardableResult
    func importIngredients() throws -> ImportResult {
        let url = try getIngredientsURL()
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

    @discardableResult
    func reimportAllCocktails() throws -> ImportResult {
        let bundleSources = RecipeSource.allCases.filter { !$0.filePrefix.isEmpty }

        let allCocktails = try context.fetch(FetchDescriptor<Cocktail>())
        var namesBySource: [RecipeSource: [String]] = [:]
        for cocktail in allCocktails where bundleSources.contains(cocktail.source) {
            namesBySource[cocktail.source, default: []].append(cocktail.name)
            context.delete(cocktail)
        }
        try context.save()

        var totalCocktails = 0
        var totalIngredients = 0
        for source in bundleSources {
            guard let names = namesBySource[source], !names.isEmpty else { continue }
            let result = try importSelectedCocktails(names: names, from: source)
            totalCocktails += result.cocktailsInserted
            totalIngredients += result.ingredientsInserted
        }

        return ImportResult(ingredientsInserted: totalIngredients, ingredientsSkipped: 0, cocktailsInserted: totalCocktails, unmappedIngredientRefs: [])
    }

    @discardableResult
    func importAll(from source: RecipeSource) throws -> ImportResult {
        let ingredientsURL = try getIngredientsURL()
        let cocktailsURL = try getCocktailsURL(for: source)

        let ingredientDTOs = try parse([IngredientDTO].self, from: ingredientsURL, label: "ingredients")
        let cocktailDTOs = try parse([CocktailDTO].self, from: cocktailsURL, label: "cocktails")

        logger.info("Parsed \(ingredientDTOs.count) ingredients, \(cocktailDTOs.count) cocktails from '\(source.filePrefix)'")

        return try processImport(cocktailDTOs: cocktailDTOs, ingredientDTOs: ingredientDTOs, source: source)
    }

    /// 4. Import cocktails from a shared .cocktail file
    @discardableResult
    func importSharedCocktail(from data: Data) throws -> ImportResult {
        let package: SharedCocktailPackage
        do {
            package = try JSONDecoder().decode(SharedCocktailPackage.self, from: data)
        } catch let decodingError as DecodingError {
            throw ImportError.decodingError("shared cocktail", decodingError)
        }
        return try importSharedCocktail(package: package)
    }

    @discardableResult
    func importSharedCocktail(package: SharedCocktailPackage) throws -> ImportResult {
        logger.info("Importing \(package.cocktails.count) shared cocktail(s)")
        return try processImport(cocktailDTOs: package.cocktails, ingredientDTOs: package.ingredients, source: .shared)
    }

    /// 3. Import selected cocktails, pulling in only the ingredients they need that are not already in the store
    @discardableResult
    func importSelectedCocktails(names: [String], from source: RecipeSource) throws -> ImportResult {
        let ingredientsURL = try getIngredientsURL()
        let cocktailsURL = try getCocktailsURL(for: source)

        let ingredientDTOs = try parse([IngredientDTO].self, from: ingredientsURL, label: "ingredients")
        let allCocktailDTOs = try parse([CocktailDTO].self, from: cocktailsURL, label: "cocktails")

        let selectedCocktails = allCocktailDTOs.filter { names.contains($0.name) }
        logger.info("Selected \(selectedCocktails.count)/\(allCocktailDTOs.count) cocktails by name filter")

        return try processImport(cocktailDTOs: selectedCocktails, ingredientDTOs: ingredientDTOs, source: source)
    }

    // MARK: - Core Logic

    @discardableResult
    private func processImport(cocktailDTOs: [CocktailDTO], ingredientDTOs: [IngredientDTO], source: RecipeSource) throws -> ImportResult {
        var existingIngredients = try fetchExistingIngredientsMap()
        logger.info("Store already has \(existingIngredients.count) ingredients")

        // Skip cocktails that already exist for this source (by name) — prevents duplicates on re-import
        let allExisting = (try? context.fetch(FetchDescriptor<Cocktail>())) ?? []
        let existingNamesForSource = Set(allExisting.filter { $0.source == source }.map { $0.name })
        let originalCount = cocktailDTOs.count
        let cocktailDTOs = cocktailDTOs.filter { !existingNamesForSource.contains($0.name) }
        let skippedDuplicates = originalCount - cocktailDTOs.count
        if skippedDuplicates > 0 {
            logger.info("Skipping \(skippedDuplicates) already-imported cocktails for source '\(source.filePrefix)'")
        }

        let neededIngredientIDs = Set(cocktailDTOs.flatMap { dto in
            dto.ingredients.map { $0.ingredientId } + (dto.garnishes ?? []).map { $0.ingredientId }
        })
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

            for (index, ingDTO) in dto.ingredients.enumerated() {
                let unit = ingDTO.unit ?? .none

                let recipeIngredient = RecipeIngredient(
                    amount: ingDTO.amount,
                    unit: unit,
                    note: ingDTO.note ?? "",
                    role: .core,
                    sortOrder: index
                )

                if let mappedIngredient = existingIngredients[ingDTO.ingredientId] {
                    recipeIngredient.ingredient = mappedIngredient
                } else {
                    unmappedRefs.append((cocktail: dto.name, ingredientName: ingDTO.ingredientId))
                    logger.warning("  ⚠️ \(dto.name): no Ingredient found for id '\(ingDTO.ingredientId)'")
                }

                recipeIngredients.append(recipeIngredient)
            }

            for (index, garnishDTO) in (dto.garnishes ?? []).enumerated() {
                let unit = garnishDTO.unit ?? .none

                let recipeIngredient = RecipeIngredient(
                    amount: garnishDTO.amount,
                    unit: unit,
                    note: garnishDTO.note ?? "",
                    role: .garnish,
                    sortOrder: index
                )

                if let mappedIngredient = existingIngredients[garnishDTO.ingredientId] {
                    recipeIngredient.ingredient = mappedIngredient
                } else {
                    unmappedRefs.append((cocktail: dto.name, ingredientName: garnishDTO.ingredientId))
                    logger.warning("  ⚠️ \(dto.name): no Ingredient found for id '\(garnishDTO.ingredientId)'")
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

    private func getIngredientsURL() throws -> URL {
        guard let url = Bundle.main.url(forResource: "ingredients", withExtension: "json") else {
            logger.error("File not found in bundle: ingredients.json")
            throw ImportError.fileNotFound("ingredients")
        }
        logger.debug("Resolved file: \(url.lastPathComponent)")
        return url
    }

    private func getCocktailsURL(for source: RecipeSource) throws -> URL {
        let fileName = "\(source.filePrefix)_cocktails"
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

// MARK: - Available Images

extension CocktailImporter {
    static let availableIngredientImageNames: [String] = {
        guard let url = Bundle.main.url(forResource: "ingredients", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dtos = try? JSONDecoder().decode([IngredientDTO].self, from: data)
        else { return [] }
        return dtos.map(\.id).sorted()
    }()
}
