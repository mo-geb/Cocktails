import SwiftUI

struct CocktailImageView: View {
    let cocktail: Cocktail
    
    var body: some View {
        Group {
            switch cocktail.displayImage {
            case .custom(let uiImage):
                Image(uiImage: uiImage)
                    .resizable()
            case .system(let name):
                Image(name)
                    .resizable()
            case .placeholder:
                Image(cocktail.glass.imageNameFilled)
                    .resizable()
            }
        }
    }
}

struct CocktailDraftImageView: View {
    let cocktail: CocktailDraft
    
    var body: some View {
        Group {
            switch cocktail.displayImage {
            case .custom(let uiImage):
                Image(uiImage: uiImage)
                    .resizable()
            case .system(let name):
                Image(name)
                    .resizable()
            case .placeholder:
                Image(cocktail.glass.imageNameFilled)
                    .resizable()
            }
        }
    }
}

struct IngredientImageView: View {
    let ingredient: Ingredient
    
    var body: some View {
        Group {
            switch ingredient.displayImage {
            case .custom(let uiImage):
                Image(uiImage: uiImage)
                    .resizable()
            case .system(let name):
                Image(name)
                    .resizable()
            case .placeholder:
                Image(ingredient.type.imageName)
                    .resizable()
            }
        }
    }
}

struct IngredientDraftImageView: View {
    let ingredient: IngredientDraft
    
    var body: some View {
        Group {
            switch ingredient.displayImage {
            case .custom(let uiImage):
                Image(uiImage: uiImage)
                    .resizable()
            case .system(let name):
                Image(name)
                    .resizable()
            case .placeholder:
                Image(ingredient.type.imageName)
                    .resizable()
            }
        }
    }
}
