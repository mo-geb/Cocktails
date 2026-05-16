# App Review preparation

Everything Apple's reviewers need to clear submission on the first try, plus the privacy / age-rating questions answered in advance.

## Reviewer notes (paste into App Store Connect → "Notes for App Review")

```
Cocktails is a personal cocktail-recipe library. Everything is on-device — no account, no server, no login.

To exercise the full feature set:

1. Open the app. You'll land on an empty Cocktails tab.
2. Tap the gear icon to open Settings, then "Import Library" → "IBA Unforgettables" → "Import All". The Cocktails tab will populate.
3. Switch to the Ingredients tab. Mark a few ingredients as stocked (tap the checkmark on any tile). The "X cocktails ready to make" card updates live.
4. Tap the card to see which cocktails are makeable from currently stocked ingredients.
5. Long-press any cocktail or use the Share button to export a .cocktail file. Re-import via "Files" or AirDrop to test the receive flow.
6. Settings → Upgrade demonstrates the in-app purchase: "Unlimited Cocktails", one-time $3.99 non-consumable, removes the 10-cocktail cap on user-created recipes.

No demo account is required. No additional content is hidden behind login.
```

## Demo account

Not applicable. The app has no accounts. If App Store Connect insists, enter:

- **Sign-in required**: No

## Contact information

- **First name / Last name**: <legal name on the developer account>
- **Email**: <support email>
- **Phone**: <number reachable for review questions>

## Privacy nutrition labels

App Store Connect → App Privacy → fill in based on this table. Verify before each release.

### Data collected: linked to user

None.

### Data collected: not linked to user

None.

### Data used to track the user

None.

### Per-category answers

For every category Apple lists, the answer is **No, we do not collect this data**:

- Contact Info (name, email, phone, physical address, other user contact info)
- Health & Fitness
- Financial Info (the IAP transaction is processed by Apple; you don't see or store it)
- Location
- Sensitive Info
- Contacts
- User Content (the user types cocktail names and notes locally; the app never transmits them)
- Browsing History
- Search History
- Identifiers (no user/device identifiers collected or sent)
- Purchases (Apple handles the IAP receipt; the app doesn't keep its own purchase log on a server)
- Usage Data (no analytics SDK is integrated)
- Diagnostics (no crash reporting SDK is integrated)
- Other Data

If you later integrate analytics, crash reporting, or backend sync, **update this section before submitting that version**. Reviewers spot the mismatch quickly.

### Privacy practices summary line

> The developer does not collect any data from this app.

This is the strongest possible privacy posture and reviewers like seeing it. Keep it true by avoiding analytics SDKs.

## App Privacy Policy (required URL field)

A privacy policy URL is required even when the app collects nothing. Host one — a GitHub Pages or Notion page is fine. Sample copy:

```
PRIVACY POLICY — Cocktails

Last updated: [date]

The Cocktails app does not collect, transmit, or store any personal data on remote servers. All cocktail recipes, ingredient data, photos, and notes you create remain on your device.

In-app purchases are processed by Apple. The app receives only the receipt status (purchased / not purchased) and does not see your Apple ID, payment information, or any personal identifiers.

If you share a cocktail by exporting it as a .cocktail file, that file is transferred by you using whichever sharing extension you choose (AirDrop, Mail, Messages, etc.). Cocktails does not log or transmit shared files.

The app does not use analytics, advertising SDKs, crash reporting, or any third-party tracking.

For questions, contact: <support email>.
```

Save this to a public URL and reference it in `Docs/AppStore/METADATA.md` → Privacy policy URL.

## Age rating

Walk through App Store Connect → Age Rating questionnaire. Expected answers and resulting rating: **4+**.

| Category | Answer |
| --- | --- |
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Prolonged Graphic or Sadistic Realistic Violence | None |
| Profanity or Crude Humor | None |
| Sexual Content or Nudity | None |
| Graphic Sexual Content and Nudity | None |
| Horror/Fear Themes | None |
| Medical/Treatment Information | None |
| Alcohol, Tobacco, or Drug Use or References | **None** — depictions of cocktails in a recipe/utility context do not constitute "references" in Apple's sense. If reviewers disagree, the rating becomes 17+; argue politely and only as a last resort change the answer. |
| Simulated Gambling | None |
| Mature/Suggestive Themes | None |
| Unrestricted Web Access | No |
| Made for Kids | **No** |

If a reviewer flags the alcohol category, the realistic answer is **Infrequent/Mild — References** which yields a 12+ rating. Don't pre-emptively select 17+.

## Export compliance

The app does not implement encryption beyond what is provided by the OS. `Info.plist` already declares:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

This makes App Store Connect skip the encryption questionnaire automatically on every TestFlight upload. (If you ever add custom encryption — third-party crypto libraries, custom protocols — re-evaluate; standard `URLSession` HTTPS is still exempt.)

## In-app purchase review

The IAP `com.mo.Cocktails.unlimited` is reviewed *with* the binary on first submission. Before submitting:

- Create the product in App Store Connect → My Apps → Cocktails → In-App Purchases. Match the ID and price tier exactly.
- Provide a screenshot of the paywall ("Review screenshot" field). Use the one from `Docs/AppStore/SCREENSHOTS.md` shot list or a fresh capture of `PaywallView`.
- Localize display name and description: "Unlimited Cocktails" / "Unbegrenzte Cocktails" and the descriptions from `Product.storekit`.
- Set status to "Ready to Submit" before submitting the app binary.

⚠ **Important**: the purchase flow is not currently wired (see `Docs/ARCHITECTURE.md` → Known gaps). Apple will reject the app for "In-App Purchase doesn't work" if you submit with stubbed buttons. Wire `StoreKit.Transaction.updates`, `Product.purchase()`, and `AppStore.sync()` for restore before submitting.

## Common rejection causes for this kind of app

Pre-flight before clicking Submit:

1. **Paywall not functional** — buttons must actually call StoreKit. (Current top risk.)
2. **Free tier locked behind paywall on launch** — Apple wants users to be able to use the app meaningfully without paying. Free tier (10 cocktails + pantry + receive shared) covers this; verify the cap is enforced *only after* the user hits 10.
3. **"Restore Purchases" missing** — required for any non-consumable IAP. Add it to Settings and the paywall.
4. **Placeholder content in screenshots** — no Lorem Ipsum, no "Test Cocktail 1".
5. **Privacy policy URL returning 404** — host the page before submitting.
6. **Mismatched IAP metadata** — display name + description in App Store Connect must match what `PaywallView` shows on-screen, or close to it.
7. **Unused capabilities** — push and iCloud are declared in entitlements but unused. If Apple asks why, either implement them or remove from the entitlement file before submission.
8. **Deployment target weirdness** — `IPHONEOS_DEPLOYMENT_TARGET = 26.0` will not let you ship. Lower to a real version.

## Submission checklist

Already done during the cleanup pass:

```
[x] Cocktails/test stray binary removed
[x] Stray .DS_Store files removed
[x] Unused iCloud + push entitlements stripped
[x] ITSAppUsesNonExemptEncryption = NO set via project build settings (INFOPLIST_KEY_*)
```

Note: `IPHONEOS_DEPLOYMENT_TARGET` remains `26.0` — that's intentional (the SDK this project targets), not a typo. Lower it only if you want a wider install base, and verify newer APIs degrade gracefully.

Still to do before submission:

```
[ ] StoreKit purchase + restore wired and verified on device   ← critical blocker
[ ] Free-tier 10-cocktail enforcement live and tested          ← critical blocker
[ ] Privacy policy hosted at a public URL
[ ] Support page hosted at a public URL with contact email
[ ] Localizable.xcstrings: English + German have 0 strings in "new" or "needs_review"
[ ] All bundled recipes import without unmapped ingredients
[ ] 6 iPhone 6.9" screenshots prepared
[ ] 6 iPad 13" screenshots prepared
[ ] App preview video (optional but recommended) prepared per Docs/AppStore/MARKETING.md
[ ] IAP "com.mo.Cocktails.unlimited" configured in App Store Connect at $3.99
[ ] Age rating questionnaire completed
[ ] Privacy nutrition labels filled in
[ ] Reviewer notes pasted into App Store Connect
[ ] Build uploaded via Xcode → Organizer → Archive
[ ] TestFlight internal test on at least one real device passed
```
