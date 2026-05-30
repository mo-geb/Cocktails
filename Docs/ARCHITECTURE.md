# Architecture

A short tour of how the app is put together.

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

Under `Cocktails/Enums/`, grouped into subfolders:

**`Cocktail/`**
- `GlassType` — `rocks`, `highball`, `martini`, `flute`, `copperMug`, `hurricane`, `tiki`, `wine`, `shot`, `other`
- `PreparationMethod` — `stir`, `shake`, `build`, `blend`, `roll`
- `IceType` — `cubed`, `crushed`, `clearBlock`, `none`
- `RecipeSource` — `custom`, `clutterfree`, `ebsInter2023`, `ibaUnforgettables`, `shared`

**`Ingredient/`**
- `IngredientRole` — `core`, `garnish`
- `IngredientType` — `spirit`, `liqueur`, `fortifiedWine`, `syrup`, `juice`, `bitters`, `mixer`, `fruit`, `herb`, `spice`, `vegetable`, `other`
- `MeasurementUnit` — `ml`, `oz`, `dash`, `bsp`, `piece`, `part`, `leaf`, `fill`, `none`

**`State/`** (UI flow enums)
- `ActiveTab`, `SearchTab`, `AppSheet` (settings / import library / received recipes), `ActiveCocktailSheet`, `ActiveIngredientSheet`, `CocktailGrouping` (persisted to `UserDefaults`)

**Top-level**
- `DisplayImageSource` — discriminated union used by the image-providing protocols
- `GridColumns` — adaptive grid layout helper

## State management

`AppState` is a single `@Observable` class living in `Cocktails/App/AppState.swift`. It holds:

- `selectedTab` and a derived `preferredSearchTab` (remembers whether the user was on Cocktails or Ingredients before switching to Search)
- sheet presentation state: `activeSheet` (`AppSheet`: settings / import library / received `.cocktail` URL), `activeCocktailSheet`, `activeIngredientSheet`, `showPaywall`, `showOnboarding` (gated on the `hasSeenOnboarding` `UserDefaults` flag)
- deletion targets pending confirmation: `cocktailToDelete`, `ingredientToDelete`
- `cocktailGrouping` persisted to `UserDefaults`

It also exposes intent methods (`openSettings()`, `openImportLibrary()`, `openReceivedRecipes(_:)`, `dismissOnboarding()`, `addCocktail()`, etc.) that views call instead of mutating state directly.

Views read it via `@Environment(AppState.self)` and `@Bindable`.

## Views

Organized under `Cocktails/Views/`:

- top level — `MainTabView`, `SettingsView`, `PaywallView`, `OnboardingView`
- `Tabs/` — `CocktailTab`, `IngredientTab`, `SearchView`, `MakeableCocktailsView`
- `Detail/` — `CocktailDetailView`, `CocktailEditView`, `IngredientEditView`, `IngredientPickerView`
- `Import/` — `RecipeLibrariesView`, `LibraryCocktailsView`, `ReceivedRecipesView`
- `Components/` — `CocktailSectionCard`, `CocktailGradientBackground`, `ConfettiView`, `FeatureRow`, `IngredientImagePickerSheet`, and a `Cells/` subfolder (`CocktailGridCell`, `CocktailPreviewCell`, `IngredientGridCell`, `LibraryCell`)

`#Preview(traits: .sampleData)` is used throughout; the trait pulls from `PreviewContent/PreviewSampleData.swift`.

## Recipe import & sharing

Both flows live in `Cocktails/Services/`.

**`CocktailImporter.swift`** decodes the bundled JSON files in `Resources/Recipes/` (`ingredients.json`, `ebsInter2023_cocktails.json`, `ibaUnforgettables_cocktails.json`, `clutterfree_cocktails.json`) into DTOs and merges them into the SwiftData store. Import is idempotent: existing cocktails and ingredients with matching identifiers are skipped, and unmapped ingredient references are returned in an `ImportResult` for surfacing in the UI.

**`CocktailTransferable.swift`** defines `SharedCocktailPackage` (cocktails + the ingredients they depend on) and a `Transferable` conformance that serializes to a `.cocktail` JSON file via `FileRepresentation`. The same package can be re-imported through `CocktailImporter.importSharedCocktail(package:)`.

The UTI is declared in `Info.plist` under `UTExportedTypeDeclarations` and `CFBundleDocumentTypes`, conforming to `public.data` + `public.json`.

## Image handling

Two protocols (`CocktailImageProviding`, `IngredientImageProviding`) expose a `displayImage: DisplayImageSource`, returning either a user-supplied `UIImage`, a named asset from the catalog, or a placeholder. Custom user photos are stored as `Data` with `@Attribute(.externalStorage)` so they live outside the SQLite store. The detail view extracts a dominant color from the image for the gradient background.

## Monetization

- `Product.storekit` defines a single non-consumable IAP, `com.mo.Cocktails.unlimited`, $3.99.
- `StoreManager` (`Cocktails/Services/StoreManager.swift`) is an `@Observable` service injected into the environment via `CocktailsApp`. It handles product loading, purchase, restore, and a `Transaction.updates` listener that keeps `isUnlimited` in sync.
- `CocktailTab` enforces the 10-cocktail free cap via `store.canAddMore(currentCount:)` before presenting the new-cocktail sheet — hitting the limit redirects to `PaywallView` instead.
- `PaywallView` is fully wired to `StoreManager`: it shows live pricing, drives the purchase call, and dismisses itself on successful unlock.

## Onboarding & review prompts

- `OnboardingView` is shown full-screen on first launch, gated by `AppState.showOnboarding` (backed by the `hasSeenOnboarding` `UserDefaults` flag); `dismissOnboarding()` flips it permanently.
- `ReviewManager` (`Cocktails/Services/ReviewManager.swift`) is a stateless enum that tracks how many cocktail detail views have been opened and returns `true` at milestone counts (10, 50, 100) so the caller can trigger `requestReview`. State is persisted in `UserDefaults`.

## Localization

`Localizable.xcstrings` is the canonical string catalog. The `Scripts/translate_strings.py` tool (see `Docs/BUILD.md`) reads it, finds strings marked `new` or `needs_review`, and fills in translations via OpenAI, DeepL, or Google. Format placeholders (`%@`, `%lld`, `%1$@`) and CLDR plural rules are preserved.

Ingredient names are localized by a separate convention: `Ingredient.localizedName` looks up `"ingredient.\(id)"` in the catalog and falls back to the stored `name`.

## Known gaps before submission

1. Privacy nutrition labels need to be filled out in App Store Connect.

The `IPHONEOS_DEPLOYMENT_TARGET = 26.0` is intentional (matches the Xcode 26 / iOS 26 SDK the project was created against), not a blocker.
