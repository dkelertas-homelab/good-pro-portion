# Ads and Remove ads (scaffolding)

Issue #27. The code paths exist but are **off by default**. No ad or billing SDK is bundled yet, so release builds have no ads, no ad SDK and no extra permissions.

## What's in the code

| Piece | File | Notes |
|---|---|---|
| Master switch | `lib/monetisation/ads_config.dart` | `--dart-define=ADS_ENABLED=true` turns it on. Default off. |
| Test ad IDs | same | Google's published sample IDs only (`ca-app-pub-3940256099942544…`). A test fails if any other AdMob ID appears in `lib/`. |
| Placements | same (`AdPlacement`) | Home banner and done-screen banner. There's no value for the workout, rest or timer screens, by design. |
| Ad slot | `lib/monetisation/ad_slot.dart` | Off: nothing in release, "Ad placeholder" in debug. On: a labelled test slot that hides once Remove ads is owned. |
| Remove ads | `lib/monetisation/purchases.dart`, `remove_ads_card.dart` | `PurchaseService` interface plus a stub that "buys" by setting a local flag. Product ID `remove_ads`. One-off, with Restore. |

To try it on a test build: `flutter run --dart-define=ADS_ENABLED=true`.

## Before real ads (David)

1. AdMob account and app, then real app and unit IDs.
2. Play Console:
   - Create the one-off product `remove_ads` and set the price.
   - Fill in the ads declaration and update the data safety form.
3. Privacy policy page on d11s.space that covers ads.
4. Code, once 1–3 exist:
   - Add `google_mobile_ads` and the UMP consent form, with the app ID in `AndroidManifest.xml`.
   - Add `in_app_purchase` and a Play Billing `PurchaseService`.
   - Pass the real IDs only to release builds.
   - Keep the test IDs for debug builds.
