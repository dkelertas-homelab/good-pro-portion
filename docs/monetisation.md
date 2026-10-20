# Ads and Remove ads

Issue #27. Real AdMob banner ads with Google's UMP consent form, plus a one-off Remove ads purchase (still a stub). **Off by default**: release builds are built without `ADS_ENABLED` until David OKs turning ads on.

## IDs

| What | Debug / profile builds | Release builds |
|---|---|---|
| App ID (`AndroidManifest.xml` meta-data `com.google.android.gms.ads.APPLICATION_ID`, set per build type in `android/app/build.gradle.kts`) | `ca-app-pub-3940256099942544~3347511713` (Google sample) | `ca-app-pub-4030959040832472~2202340044` |
| Home banner (`home_banner`) | `ca-app-pub-3940256099942544/6300978111` (Google sample) | `ca-app-pub-4030959040832472/5047995231` |
| Done-screen banner | sample banner | none (no live unit yet) |

Debug builds can never request a live ad, so tapping ads while testing can't get the account flagged. Tests check this. The app ID meta-data is always present (the SDK crashes without it), even when ads are off.

## What's in the code

| Piece | File | Notes |
|---|---|---|
| Master switch | `lib/monetisation/ads_config.dart` | `--dart-define=ADS_ENABLED=true` turns ads on. Default off. |
| IDs | same (`TestAdIds`, `LiveAdIds`, `bannerUnitId`) | Live IDs used only when `kReleaseMode`. |
| Consent + SDK start | `lib/monetisation/ads_service.dart` | Every launch: UMP consent info update, shows the form if required (EEA/UK), then starts the SDK only if `canRequestAds`. Settings shows "Ad privacy options" when UMP says it's required. |
| Ad slot | `lib/monetisation/ad_slot.dart` | Off: nothing in release, "Ad placeholder" in debug. On: a 320×50 banner, hidden until consent allows ads, if no ad fills, or once Remove ads is owned. Never on workout, rest or timer screens. |
| Remove ads | `lib/monetisation/purchases.dart`, `remove_ads_card.dart` | Stub that "buys" by setting a local flag. Product ID `remove_ads`. One-off, with Restore. Play Billing is the next step. |

To try it: `flutter run --dart-define=ADS_ENABLED=true` (debug, sample ads).

## app-ads.txt

File: `docs/app-ads.txt`. Host it at `https://d11s.space/app-ads.txt` (site root), and set `d11s.space` as the developer website on the Play store listing:

```
google.com, pub-4030959040832472, DIRECT, f08c47fec0942fa0
```

## Still to do (David)

1. AdMob:
   - Set up the GDPR consent message: Privacy & messaging → European regulations → create a message for the app and publish it. Without it the UMP form has nothing to show EEA/UK users, and ads there won't serve.
   - Once the app is live on Play, link it to the store listing in AdMob (App settings), then AdMob verifies app-ads.txt.
2. Host app-ads.txt on d11s.space (above).
3. Play Console:
   - App content → Ads: "Yes, my app contains ads".
   - Data safety: the Mobile Ads SDK collects device or other IDs (advertising ID), approximate location, app interactions and diagnostics, shared with Google for advertising and analytics; data is encrypted in transit. Update the form before shipping an ads build.
   - Create the one-off product `remove_ads` and set the price.
4. Privacy policy page on d11s.space that covers AdMob ads and consent: draft text in `docs/privacy-policy-ads.md`.
5. Code, later: `in_app_purchase` and a Play Billing `PurchaseService`; then build release with `ADS_ENABLED=true` once David OKs it.
