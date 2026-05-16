# Architecture

A short tour of how the app is put together. Pair this with `Docs/PROJECT_STRUCTURE_REVIEW.md` for suggested layout changes.

## Stack

- **UI**: SwiftUI, single `TabView` root
- **Persistence**: SwiftData (local store; CloudKit container declared but not yet used)
- **Sharing**: `Transferable` + a custom `UTType` (`com.mo.Cocktails.recipe`, file extension `.cocktail`)
- **In-app purchase**: StoreKit 2, one-time non-consumable (configured in `Cocktails/Resources/Product.storekit`)
- **Localization**: `Localizable.xcstrings` (English source, German fully translated)
- **Image pipeline**: bundled assets in `Assets.xcassets` plus optional user-supplied images stored as `Data` via `@Attribute(.externalStorage)`

## Entry point

`CocktailsApp.swift` is the `@main` `App`. It:

- builds a `ModelContainer` for the schema `[Cocktail, RecipeIngredient, Ingredient]`
- injects an `AppState` (`@Observable`) into the environment
- presents `MainTabView`

`MainTabView` owns the three primary tabs (Cocktails, Ingredients, Search), handles the Settings sheet, and routes `.onOpenURL` deep links (incoming `.cocktail` files) into `ReceivedRecipesView`.

## Data model

Three SwiftData entities, all defined under `Cocktails/Models/`:

**`Cocktail`** — recipe header (`name`, `glass`, `method`, `ice`, `source`, `isFavourite`, `notes`, optional `imageData` + `imageName`) with a cascade-delete relationship to `[RecipeIngredient]`.

**`RecipeIngredient`** — join entity carrying `amount`, `unit`, `note`, `role` (`core` / `garnish`), `sortOrder`, and references back to a `Cocktail` and an `Ingredient`.

**`Ingredient`** — pantry item (`id`, `name`, `type`, `isStocked`, optional `imageName`) with an inverse `usages: [RecipeIngredient]` collection.

Every model has a sibling `*Draft` struct used by the editor sheets so edits are cancellable and only committed on save.

Helper extensions on `Cocktail` expose `coreIngredients`, `garnishIngredients`, and a computed `baseGroup` (priority: spirit → liqueur → fortified wine) for grouping.

## Domain enums

Under `Cocktails/Enums/`. Each has a `localizedName` and, where relevant, an `imageName` mapping into the asset catalog.

- `GlassType` — `rocks`, `highball`, `martini`, `flute`, `copperMug`, `hurricane`, `tiki`, `wine`, `shot`, `other`
- `PreparationMethod` — `stir`, `shake`, `build`, `blend`, `roll`
- `IceType` — `cubed`, `crushed`, `clearBlock`, `none`
- `RecipeSource` — `custom`, `clutterfree`, `ebsInter2023`, `ibaUnforgettables`, `shared`
- `IngredientRole` — `core`, `garnish`
- `IngredientType` — `spirit`, `liqueur`, `fortifiedWine`, `syrup`, `juice`, `bitters`, `mixer`, `fruit`, `herb`, `spice`, `vegetable`, `other`
- `MeasurementUnit` — `ml`, `oz`, `dash`, `bsp`, `piece`, `part`, `leaf`, `fill`, `none`
- `CocktailGrouping` — `none`, `favourite`, `source`, `glass`, `method`, `base` (persisted to `UserDefaults`)
- UI flow enums: `ActiveTab`, `SearchTab`, `ActiveCocktailSheet`, `ActiveIngredientSheet`, `DisplayImageSource`

## State management

`AppState` is a single `@Observable` class living in `Cocktails/AppState.swift`. It holds:

- `selectedTab` and a derived `preferredSearchTab` (remembers whether the user was on Cocktails or Ingredients before switching to Search)
- sheet presentation state: `activeCocktailSheet`, `activeIngredientSheet`, `showSettings`
- deletion targets pending confirmation: `cocktailToDelete`, `ingredientToDelete`
- `pendingImportURL` for inbound `.cocktail` files
- `cocktailGrouping` persisted to `UserDefaults`

Views read it via `@Environment(AppState.self)` and `@Bindable`.

## Views

Organized under `Cocktails/Views/` into four buckets:

- `Tabs/` — `CocktailTab`, `IngredientsTab`, `SearchView` (plus `MainTabView.swift` lives one level up)
- `DetailedViews/` — `CocktailDetailView`, `CocktailEditView`, `IngredientEditView`, `IngredientPickerView`, `MakeableCocktailsView`
- `Settings/` — `SettingsView`, `PaywallView`, `RecipeLibrariesView`, `LibraryCocktailsView`, `ReceivedRecipesView`
- `Components/` — `CocktailGridCell`, `IngredientGridCell`, `CocktailPreviewCard`, `LibraryCard`, `CardPressStyle`, `IngredientImagePickerSheet`

`#Preview(traits: .sampleData)` is used throughout; the trait pulls from `Helper/PreviewSampleData.swift`.

## Recipe import & sharing

Both flows live in `Cocktails/Helper/`.

**`CocktailImporter.swift`** decodes the bundled JSON files in `Resources/Recipes/` (`ingredients.json`, `ebsInter2023_cocktails.json`, `ibaUnforgettables_cocktails.json`, `clutterfree_cocktails.json`) into DTOs and merges them into the SwiftData store. Import is idempotent: existing cocktails and ingredients with matching identifiers are skipped, and unmapped ingredient references are returned in an `ImportResult` for surfacing in the UI.

**`CocktailTransferable.swift`** defines `SharedCocktailPackage` (cocktails + the ingredients they depend on) and a `Transferable` conformance that serializes to a `.cocktail` JSON file via `FileRepresentation`. The same package can be re-imported through `CocktailImporter.importSharedCocktail(package:)`.

The UTI is declared in `Info.plist` under `UTExportedTypeDeclarations` and `CFBundleDocumentTypes`, conforming to `public.data` + `public.json`.

## Image handling

Two protocols (`CocktailImageProviding`, `IngredientImageProviding`) expose a `displayImage: DisplayImageSource`, returning either a user-supplied `UIImage`, a named asset from the catalog, or a placeholder. Custom user photos are stored as `Data` with `@Attribute(.externalStorage)` so they live outside the SQLite store. The detail view extracts a dominant color from the image for the gradient background.

## Monetization (current state)

- `Product.storekit` defines a single non-consumable IAP, `com.mo.Cocktails.unlimited`, $3.99.
- `PaywallView` renders the upgrade UI and references the 10-cocktail free-tier limit.
- **Not yet wired**: there is no `StoreKit` purchase flow, no purchase-state listener, and no enforcement of the 10-cocktail cap anywhere in `CocktailEditView` or `CocktailImporter`. The paywall buttons are stubs.

This is the single largest pre-submission gap.

## Localization

`Localizable.xcstrings` is the canonical string catalog. The `Scripts/translate_strings.py` tool (see `Docs/BUILD.md`) reads it, finds strings marked `new` or `needs_review`, and fills in translations via OpenAI, DeepL, or Google. Format placeholders (`%@`, `%lld`, `%1$@`) and CLDR plural rules are preserved.

Ingredient names are localized by a separate convention: `Ingredient.localizedName` looks up `"ingredient.\(id)"` in the catalog and falls back to the stored `name`.

## Known gaps before submission

1. **StoreKit purchase + restore wiring and free-tier enforcement** (see `PaywallView`). This is the only remaining blocker.
2. Privacy nutrition labels need to be filled out in App Store Connect (see `Docs/AppStore/REVIEW_NOTES.md`).

Other items previously listed here (stray binary, unused entitlements, `.DS_Store` cruft) were resolved by the cleanup pass — see `Docs/PROJECT_STRUCTURE_REVIEW.md` for what was done. The `IPHONEOS_DEPLOYMENT_TARGET = 26.0` is intentional (matches the Xcode 26 / iOS 26 SDK the project was created against), not a blocker.
