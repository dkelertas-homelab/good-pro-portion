/// Ads and the one-off "Remove ads" purchase (issue #27).
///
/// Scaffolding only: no ad or billing SDK is bundled yet. Everything here is
/// off unless the app is built with `--dart-define=ADS_ENABLED=true`, and
/// even then it only shows labelled test slots and a stubbed purchase.
/// See docs/monetisation.md for what's needed before real ads.
library;

/// Master switch. Off by default; release builds ship without ads.
const bool adsEnabled = bool.fromEnvironment('ADS_ENABLED');

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

/// Play product ID to create for the one-off purchase (not created yet).
const removeAdsProductId = 'remove_ads';

/// Where an ad may appear. There is deliberately no value for the workout,
/// rest or timer screens: ads never show during a workout.
enum AdPlacement { homeBanner, doneBanner }
