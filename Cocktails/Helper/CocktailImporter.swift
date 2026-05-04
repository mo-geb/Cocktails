// MARK: - DTOs

struct IngredientDTO: Codable {
    let name: String
    let type: String
}

struct CocktailDTO: Codable {
    let name: String
    let glass: String
    let method: String
    let ice: String
    let ingredients: [RecipeIngredientDTO]
    let notes: String
}

struct RecipeIngredientDTO: Codable {
    let ingredientName: String
    let amount: Double?
    let unit: String?
    let note: String?
}

