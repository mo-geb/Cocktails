# Build & toolchain

How to build, run, sign, and use the auxiliary tooling.

## Requirements

- macOS with the latest stable Xcode that supports your `IPHONEOS_DEPLOYMENT_TARGET`
- Apple Developer account (team `3UC3S478RS` is currently set in the project; change it to yours if forking)
- Python 3.11+ and [`uv`](https://docs.astral.sh/uv/) for the `Scripts/` tooling
- An OpenAI API key if you want to use `translate_strings.py` or the icon-generation scripts

## Xcode

Open `Cocktails.xcodeproj` and select the `Cocktails` scheme. The app builds for iPhone and iPad.

### Deployment target

`IPHONEOS_DEPLOYMENT_TARGET` is `26.0`. That's the current Xcode/iOS SDK baseline this project was created against (Xcode 26.x, `objectVersion = 77`, `CreatedOnToolsVersion = 26.2`). It means the app will only install on devices running that iOS major release or newer. If you want a wider install base, lower the value in Xcode → project → `Cocktails` target → General → Minimum Deployments → iOS — but be aware that some APIs in use (e.g. the newest SwiftUI glass effects) may require fallbacks.

Change it via Xcode → project → `Cocktails` target → General → Minimum Deployments → iOS.

### Versioning

- `MARKETING_VERSION` (CFBundleShortVersionString): `2026.1`
- `CURRENT_PROJECT_VERSION` (CFBundleVersion): `3`

Bump `CURRENT_PROJECT_VERSION` for every TestFlight upload; bump `MARKETING_VERSION` for public releases.

### Signing

Automatic signing is enabled. To build locally:

1. Xcode → target → Signing & Capabilities → set Team to yours.
2. Change `PRODUCT_BUNDLE_IDENTIFIER` from `com.mo.Cocktails` to one in your namespace if you intend to install on a device.
3. The entitlements file references the iCloud container `iCloud.com.mo.Cocktails`; update that to match your bundle identifier.

### Capabilities currently declared

- iCloud (CloudKit) — container `iCloud.com.mo.Cocktails` is declared in `Cocktails.entitlements`. The entitlement is present but sync is not yet active: `ModelContainer` is configured with a plain `ModelConfiguration` (no `cloudKitContainerIdentifier`), so SwiftData is storing data locally only. To wire up sync, pass the container identifier to `ModelConfiguration`.
- Push Notifications (APS environment: development) — declared alongside CloudKit; not otherwise used by app code yet.

## StoreKit testing

`Cocktails/Resources/Product.storekit` configures a single non-consumable product `com.mo.Cocktails.unlimited` at $3.99. To test purchase flows once they are wired:

1. Xcode → Edit Scheme → Run → Options → StoreKit Configuration → select `Product.storekit`.
2. Run on the simulator. Purchases go through the local StoreKit testing harness, not Apple's servers.
3. Manage transactions via Xcode → Debug → StoreKit → Manage Transactions.

The same product ID must be configured in App Store Connect before TestFlight.

## Running on device

1. Connect device, trust the computer.
2. Select the device in Xcode's scheme bar.
3. Build & run. First-run will require you to trust the developer certificate in Settings → General → VPN & Device Management.

## Python tooling (`Scripts/`)

Set up a virtual environment with `uv`:

```bash
cd Scripts
uv sync
```

Then export your OpenAI key (required for translation and icon generation):

```bash
export OPENAI_API_KEY="sk-..."
```

### Translations

`translate_strings.py` syncs `Cocktails/Resources/Localizable.xcstrings`. It only touches strings marked `new` or `needs_review` and preserves format specifiers and CLDR plural rules.

```bash
# Add a new language stub
uv run translate_strings.py --lang fr --add

# Fill in missing translations for one language
uv run translate_strings.py --lang de

# Run across every incomplete language
uv run translate_strings.py --all

# Preview without writing
uv run translate_strings.py --lang de --dry-run
```

Backends: OpenAI (default, `gpt-4o`), DeepL (`--backend deepl`), Google free (`--backend google`). DeepL needs `DEEPL_API_KEY`.

### Icon generation

These scripts call the OpenAI image API to generate the bundled glyph-style icons used in `Assets.xcassets`. They write PNGs to disk; you then drag them into the asset catalog.

```bash
# Report which cocktail / ingredient images referenced by the bundled JSON are missing from Assets.xcassets
uv run generate_missing.py --report

# Generate everything missing
uv run generate_missing.py --cocktails
uv run generate_missing.py --ingredients

# One-off generation
uv run cocktail.py "Old Fashioned" --glass rocks --garnish "orange zest" --image old_fashioned
uv run glass.py highball
uv run ingredient.py "Calvados" --type spirit --image calvados
```

`_common.py` holds the shared OpenAI client config, prompt templates, and the file-writing helper.

## Common pitfalls

- **Schema migrations**: SwiftData migrations are not configured. If you change a `@Model` schema, bump the schema version and add a `VersionedSchema` migration plan — otherwise existing installs will lose data.
- **Bundled recipe JSON**: when adding entries to `Resources/Recipes/*.json`, make sure every ingredient referenced has a matching id in `ingredients.json`, or `CocktailImporter` will list it under `unmappedIngredients`.
- **Asset names**: the asset catalog groups (`Cocktail/`, `Ingredient/`, `Glass/`, `Ice/`, `Method/`, `Source/`) are referenced by string. Renaming an asset without updating the corresponding enum or JSON id will silently fall back to the placeholder image.
