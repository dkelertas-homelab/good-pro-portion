# Ads and Remove ads

Issue #27. Real AdMob banner ads with Google's UMP consent form, plus a one-off Remove ads purchase through Google Play Billing. **Off by default**: release builds are built without `ADS_ENABLED` until David OKs turning ads on.

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
| Remove ads | `lib/monetisation/play_billing.dart`, `purchases.dart`, `remove_ads_card.dart` | Google Play Billing via `in_app_purchase` (`com.android.vending.BILLING` permission). Non-consumable product `remove_ads`. Queries the product and shows its Play price, buys, listens to the purchase stream (purchased, restored, pending, cancelled, error) and acknowledges every purchase with `completePurchase` (Play refunds unacknowledged ones after 3 days). Ownership is cached in SharedPreferences (`remove_ads_owned`) so ads stay off offline. Settings → Remove ads has Restore purchase. If Play or the product is missing, the card says "Not available right now" with no buy button. No server-side verification (cosmetic entitlement); refunds aren't revoked locally. `StubPurchaseService` stays for tests. Tests use a fake store (`test/play_billing_test.dart`). |

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
   - Monetise → Products → In-app products: create `remove_ads` (one-off), set the price and activate it. Play only lets you create products after an AAB with the BILLING permission (0.1.5+6 or later) has been uploaded to a track.
   - Licence testing: add David's Google account so test purchases aren't charged. Install from the internal-testing track (Play-signed); sideloaded debug builds show "Not available".
   - Payments profile is already set up (AdMob/Play merchant).
4. Privacy policy page on d11s.space that covers AdMob ads and consent: draft text in `docs/privacy-policy-ads.md`.
5. Build release with `ADS_ENABLED=true` once David OKs it (the Remove ads card is hidden/disabled while ads are off).
