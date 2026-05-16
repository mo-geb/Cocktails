# App Store metadata

Drafts for every field App Store Connect will ask for. English (en-US) and German (de-DE). Character limits are Apple's; counts are approximate — verify in App Store Connect.

---

## App name (30 chars)

- **EN**: `Cocktails — Recipe Library` (26)
- **DE**: `Cocktails — Rezeptsammlung` (26)

Alternatives if "Cocktails" alone is taken:

- `Cocktails: Home Bar` (19)
- `Cocktails — Pantry & Recipes` (28)
- `Cocktail Pantry` (15)

## Subtitle (30 chars)

- **EN**: `Your home bar, organised.` (25)
- **DE**: `Deine Hausbar, übersichtlich.` (29)

Alternates:

- `Build, stock, share recipes.` (28) / `Rezepte sammeln & teilen.` (25)
- `What can I make tonight?` (23) / `Was kann ich heute mixen?` (25)

## Promotional text (170 chars, editable any time without re-review)

- **EN** (149): `Build your home bar, mark what you've got, and see which cocktails you can make right now. Import classic libraries or share your own creations.`
- **DE** (158): `Bau deine Hausbar auf, markiere was du da hast und sieh sofort, welche Cocktails du mixen kannst. Importiere Klassiker oder teile eigene Rezepte.`

## Description (4 000 chars)

### English

```
Cocktails is a clean, native home for your recipe collection. Build your library, stock your pantry, and see at a glance which drinks you can mix tonight.

WHAT YOU CAN DO

— Save your own cocktail recipes with photos, ingredients, garnishes, and prep notes.
— Track your home bar. Mark ingredients as stocked and the app shows you exactly which cocktails are ready to make.
— Import curated libraries: the IBA Unforgettables, the EBS International 2023 list, and the ClutterFree collection — pick the recipes you want, leave the rest.
— Share recipes as .cocktail files. Send a drink to a friend, receive theirs back, import what you like.
— Search across everything. Filter your cocktails or your pantry instantly.
— Organise the way you think. Group by glass, base spirit, preparation method, source, or favourites.
— Beautiful, native design. Built with SwiftUI for iPhone and iPad. No tracking, no ads.

WHY YOU'LL LIKE IT

— Fast. Your library lives on-device. Nothing to log into.
— Honest. One small one-time purchase unlocks unlimited recipes — no subscriptions, ever.
— Yours. Custom photos, custom notes, and full export/import of anything you create.

WHAT'S INCLUDED FREE

— Up to 10 saved cocktails
— Full ingredient pantry with stocked-status tracking
— Full search and grouping
— Receive shared cocktails

UNLOCK FULL (one-time purchase)

— Unlimited saved cocktails
— Import any of the bundled recipe libraries
— Export and share without limit

Cocktails is built for people who actually mix at home, not for bars. If you've ever stood in front of a shelf wondering what you can do with what you have — this is for you.
```

### Deutsch

```
Cocktails ist die übersichtliche, native Heimat deiner Rezeptsammlung. Bau deine Bibliothek auf, fülle deine Hausbar und sieh auf einen Blick, was du heute Abend mixen kannst.

DAS KANNST DU MACHEN

— Eigene Cocktailrezepte speichern, mit Foto, Zutaten, Garnitur und Notizen zur Zubereitung.
— Hausbar verwalten. Markiere Zutaten als vorhanden – die App zeigt dir genau, welche Cocktails du jetzt mixen kannst.
— Kuratierte Sammlungen importieren: die IBA Unforgettables, die EBS International 2023 und die ClutterFree-Auswahl. Such dir aus, was du willst.
— Rezepte teilen als .cocktail-Datei. Schick einen Drink an Freunde, importiere ihre zurück.
— Alles durchsuchen. Cocktails oder Zutaten sofort filtern.
— Sortieren wie du denkst: nach Glas, Spirituose, Zubereitung, Quelle oder Favoriten.
— Schönes, natives Design. Mit SwiftUI gebaut für iPhone und iPad. Kein Tracking, keine Werbung.

WARUM ES SICH LOHNT

— Schnell. Deine Bibliothek liegt auf dem Gerät. Kein Login.
— Ehrlich. Ein kleiner, einmaliger Kauf schaltet unbegrenzt frei – kein Abo, niemals.
— Dein Eigentum. Eigene Fotos, eigene Notizen, vollständiger Export aller selbst angelegten Rezepte.

GRATIS ENTHALTEN

— Bis zu 10 gespeicherte Cocktails
— Volle Zutatenverwaltung mit Bestandsanzeige
— Komplette Suche und Sortierung
— Geteilte Cocktails empfangen

VOLLZUGRIFF (einmaliger Kauf)

— Unbegrenzte Cocktails
— Zugriff auf alle mitgelieferten Rezeptbibliotheken
— Beliebig exportieren und teilen

Cocktails ist für Leute gemacht, die zuhause wirklich mixen. Wenn du schon mal vor deinem Regal standest und dich gefragt hast, was geht mit dem, was da steht – ist diese App für dich.
```

## Keywords (100 chars, comma-separated)

Optimize for relevance over volume. Don't repeat words already in the title/subtitle — Apple indexes those automatically.

- **EN** (99): `home bar,mixology,drinks,recipes,ingredients,pantry,bartender,iba,classic,gin,rum,whiskey,tequila`
- **DE** (98): `hausbar,mixen,drinks,rezepte,zutaten,vorrat,barkeeper,iba,klassiker,gin,rum,whisky,tequila,mixology`

## Support URL (required)

Suggestion: `https://mo-geb.com/cocktails/support`

You'll need a page that lists at least a contact email and a privacy policy link. A single-page Notion or GitHub Pages site is fine.

## Marketing URL (optional)

`https://mo-geb.com/cocktails`

## Privacy policy URL (required)

`https://mo-geb.com/cocktails/privacy` — see template in `Docs/AppStore/PRIVACY_POLICY_NOTES.md` (not yet written; flag this before submission).

## Category

- **Primary**: Food & Drink
- **Secondary**: Lifestyle

## Age rating

4+. The app contains no drug, alcohol, or tobacco *references* in the rating sense (depictions of cocktails are fine at 4+); confirm by walking through App Store Connect's age-rating questionnaire and answering "No" to all "Frequent/Intense" prompts.

## Pricing

- **App**: Free
- **In-app purchase**: `com.mo.Cocktails.unlimited` — Non-consumable, Tier 4 (~$3.99 USD / 3,99 € EUR). Configure parity pricing for major markets.

## "What's New" template

Use per release. Keep it under 4 000 chars; in practice 2–5 short bullet lines reads best.

### 2026.1 (initial release)

```
First release.

— Personal cocktail library with photos, ingredients, and notes
— Home-bar pantry: mark what you have, see what you can make
— Curated recipe libraries: IBA Unforgettables, EBS International 2023, ClutterFree
— Share cocktails as .cocktail files
— English and German
```

### Template for future releases

```
— [User-visible feature in one line]
— [Fix or improvement in one line]
— [Anything noteworthy under the hood, in one line]

Feedback welcome: [support email]
```

## Localizations to declare

- English (United States) — primary
- German (Germany)

Anything else can be added later via `Scripts/translate_strings.py --lang <code> --add` followed by an App Store Connect locale.

## Copyright

`© 2026 Moritz G.` (replace with the legal name on the developer account).

## Routing / app preview

- **Routing app coverage**: not applicable.
- **App previews**: optional but high-impact. See `Docs/AppStore/MARKETING.md` for a 15-30 second script.
