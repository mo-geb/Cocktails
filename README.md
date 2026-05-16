# Cocktails

A native iOS app for building and managing a personal cocktail library. Track which ingredients you have on hand, see at a glance which drinks you can make, and import curated recipe collections (IBA Unforgettables, EBS Inter 2023, ClutterFree) or your own custom creations.

Built with SwiftUI and SwiftData. iPhone-first; iPad supported.

- Bundle identifier: `com.mo.Cocktails`
- Marketing version: `2026.1` (build `3`)
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
│   ├── CocktailsApp.swift      # @main entrypoint, model container
│   ├── AppState.swift          # @Observable app-wide state
│   ├── Info.plist              # Document types, UTI for .cocktail
│   ├── Cocktails.entitlements  # iCloud (CloudKit), remote notifications
│   ├── Models/                 # SwiftData @Model types + Draft structs
│   ├── Enums/                  # Domain enums (glass, method, ice, etc.)
│   ├── Views/                  # SwiftUI views (tabs, detail, components, settings)
│   ├── Helper/                 # Importer, Transferable, extensions, preview data
│   └── Resources/              # Asset catalog, .xcstrings, .storekit, bundled recipe JSON
├── Docs/                       # Project documentation (this folder)
├── DesignAssets/               # Source-of-truth design files (e.g., CocktailsIcon.pxd)
└── Scripts/                    # Python tooling (translations, icon generation)
```

## Documentation index

- `Docs/ARCHITECTURE.md` — runtime architecture, data model, key flows
- `Docs/BUILD.md` — Xcode and Python toolchain setup, signing, StoreKit
- `Docs/CONTRIBUTING.md` — coding conventions, branch/PR practice
- `Docs/PROJECT_STRUCTURE_REVIEW.md` — recommendations for cleaning up the file layout
- `Docs/AppStore/` — submission-ready copy, screenshot specs, review notes, marketing assets

## Status

Under active development. The paywall UI is in place but the StoreKit purchase flow and the 10-cocktail free-tier enforcement are not yet wired — this is the only remaining blocker before App Store submission. See `Docs/ARCHITECTURE.md` → "Known gaps" and the checklist in `Docs/AppStore/REVIEW_NOTES.md`.
