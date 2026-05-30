# Cocktails

A native iOS app for building and managing a personal cocktail library. Track which ingredients you have on hand, see at a glance which drinks you can make, and import curated recipe collections (IBA Unforgettables, EBS Inter 2023, ClutterFree) or your own custom creations.

Built with SwiftUI and SwiftData. iPhone-first; iPad supported.

- Bundle identifier: `com.mo.Cocktails`
- Marketing version: `2026.2` (build `7`)
- Target SDK: iOS (see `Docs/BUILD.md` for the deployment-target note)
- Languages: English (source), German

## Highlights

- Personal cocktail library backed by SwiftData
- Ingredient pantry with a "stocked" toggle and a live "makeable cocktails" counter
- Curated bundled recipe libraries (IBA Unforgettables, EBS Inter 2023, ClutterFree)
- Share recipes between users as `.cocktail` files (JSON, registered UTType)
- Photo picker for custom cocktail and ingredient images, plus a generated asset library
- Localization-ready via `.xcstrings`, with a Python tooling pipeline for translations and asset generation

## Quick start

```bash
git clone <repo-url>
cd Cocktails
open Cocktails.xcodeproj
```

Pick an iPhone simulator (or your signed device) and run. For Python tooling under `Scripts/`, see `Docs/BUILD.md`.

## Repository layout

```
Cocktails/                      # Xcode project root
├── Cocktails.xcodeproj/        # Xcode project
├── Cocktails/                  # App target source
│   ├── App/                    # App entry point & AppState definition
│   │   ├── CocktailsApp.swift  # Main entrypoint, SwiftData model container setup
│   │   └── AppState.swift      # App-wide Observable state
│   ├── Info.plist              # Document types, UTI for .cocktail, configuration
│   ├── Cocktails.entitlements  # iCloud (CloudKit), remote notifications
│   ├── Models/                 # SwiftData @Model entities & temporary schemas
│   ├── Enums/                  # Domain-specific enums (IngredientType, Glass, etc.)
│   ├── Views/                  # SwiftUI user interface (tabs, components, details, settings)
│   ├── Services/               # Core services (Importer, Transferable, StoreManager, ReviewManager)
│   ├── Extensions/             # Bundle, Collection, UIImage, and View helpers
│   ├── PreviewContent/         # Assets & test data utilized for Xcode Canvas Previews
│   └── Resources/              # Localizations (.xcstrings), assets, StoreKit configuration, JSON recipes
├── Docs/                       # Project documentation and specifications
├── DesignAssets/               # Design assets (Pixelmator source files & App Store exports)
└── Scripts/                    # Python workflow automation (Translation, missing asset generators)
```

## Documentation index

- [Docs/ARCHITECTURE.md](Docs/ARCHITECTURE.md) — runtime architecture, data model, and user flows
- [Docs/BUILD.md](Docs/BUILD.md) — Xcode setup, signing, and Python automation toolchain
- [DesignAssets/AppStore/](DesignAssets/AppStore/) — screenshot specs, review notes, and marketing assets

## Status

Under active development. The StoreKit purchase flow, free-tier enforcement, paywall, first-launch onboarding, and review prompt are fully wired. The remaining pre-submission item is filling in privacy nutrition labels in App Store Connect — see `Docs/ARCHITECTURE.md` → "Known gaps".
