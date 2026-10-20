/// Ads and the one-off "Remove ads" purchase (issue #27).
///
/// Ads use the Google Mobile Ads SDK (AdMob) with the UMP consent form.
/// Everything here is off unless the app is built with
/// `--dart-define=ADS_ENABLED=true`. Debug and profile builds only ever use
/// Google's sample IDs; the real AdMob IDs are used by release builds only.
/// The purchase is still a stub (Play Billing comes later).
/// See docs/monetisation.md.
library;

import 'package:flutter/foundation.dart';

/// Master switch. Release builds have ads on by default from 0.1.5 (David
/// OK'd ads + Remove ads for internal testing, 20 Oct 2026); debug, profile
/// and test builds have them off unless built with ADS_ENABLED=true.
/// Build release with --dart-define=ADS_ENABLED=false to ship without ads.
const bool adsEnabled = bool.fromEnvironment(
  'ADS_ENABLED',
  defaultValue: kReleaseMode,
);

/// Google's published sample AdMob IDs. They always serve test ads, so
/// tapping them can't get an account flagged. Real IDs go in only when the
/// AdMob account exists, and only for release builds.
class TestAdIds {
  const TestAdIds._();

  static const publisher = 'ca-app-pub-3940256099942544';
  static const androidAppId = '$publisher~3347511713';
  static const banner = '$publisher/6300978111';
  static const interstitial = '$publisher/1033173712';
}

/// The real AdMob IDs for Nice Pro Portions. Public (they ship inside the
/// app), but only ever used by release builds so nobody taps live ads while
/// testing. The app ID also lives in android/app/build.gradle.kts
/// (manifest placeholder, release build type only).
class LiveAdIds {
  const LiveAdIds._();

  static const publisher = 'ca-app-pub-4030959040832472';
  static const androidAppId = '$publisher~2202340044';
  static const homeBanner = '$publisher/5047995231';
}

/// The banner unit for [placement], or null when it has no unit (no ad).
/// [release] is only overridable for tests.
String? bannerUnitId(AdPlacement placement, {bool release = kReleaseMode}) {
  switch (placement) {
    case AdPlacement.homeBanner:
      return release ? LiveAdIds.homeBanner : TestAdIds.banner;
    case AdPlacement.doneBanner:
      // No live unit yet: test builds show the sample banner, release none.
      return release ? null : TestAdIds.banner;
  }
}

/// Play product ID to create for the one-off purchase (not created yet).
const removeAdsProductId = 'remove_ads';

/// Where an ad may appear. There is deliberately no value for the workout,
/// rest or timer screens: ads never show during a workout.
enum AdPlacement { homeBanner, doneBanner }
