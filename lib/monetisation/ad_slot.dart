import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_config.dart';
import 'ads_service.dart';
import 'purchases.dart';

/// Builds the actual ad for a unit ID. Swappable so tests don't need the SDK.
typedef AdBuilder = Widget Function(BuildContext context, String unitId);

/// A reserved ad space on a non-workout screen.
///
/// - Ads off (the default): nothing in release builds; a dashed
///   "Ad placeholder" in debug builds so layouts can be checked.
/// - Ads on: a real AdMob banner (sample unit in debug, live unit in release)
///   once consent allows it, hidden once the user owns Remove ads.
class AdSlot extends StatelessWidget {
  const AdSlot({
    super.key,
    required this.placement,
    this.enabled = adsEnabled,
    this.showPlaceholder = kDebugMode,
    this.service,
    this.canRequestAds,
    this.adBuilder,
  });

  final AdPlacement placement;
  final bool enabled;
  final bool showPlaceholder;
  final PurchaseService? service;
  final ValueListenable<bool>? canRequestAds;
  final AdBuilder? adBuilder;

  static const height = 56.0;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return showPlaceholder
          ? _box(context, 'Ad placeholder')
          : const SizedBox.shrink();
    }
    final unitId = bannerUnitId(placement);
    if (unitId == null) return const SizedBox.shrink();
    return ValueListenableBuilder<bool>(
      valueListenable: (service ?? purchases).adFree,
      builder: (context, adFree, _) => adFree
          ? const SizedBox.shrink()
          : ValueListenableBuilder<bool>(
              valueListenable:
                  canRequestAds ?? AdsService.instance.canRequestAds,
              builder: (context, can, _) => !can
                  ? const SizedBox.shrink()
                  : Semantics(
                      label: 'Advertisement',
                      child: KeyedSubtree(
                        key: ValueKey('ad-slot-${placement.name}'),
                        child: (adBuilder ?? _banner)(context, unitId),
                      ),
                    ),
            ),
    );
  }

  static Widget _banner(BuildContext context, String unitId) =>
      BannerAdView(unitId: unitId);

  Widget _box(BuildContext context, String text) => Container(
    key: ValueKey('ad-slot-${placement.name}'),
    height: height,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

/// A standard 320×50 AdMob banner. Takes no space until an ad has loaded,
/// and stays empty if none fills (no error shown to the user).
class BannerAdView extends StatefulWidget {
  const BannerAdView({super.key, required this.unitId});

  final String unitId;

  @override
  State<BannerAdView> createState() => _BannerAdViewState();
}

class _BannerAdViewState extends State<BannerAdView> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: widget.unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Banner failed: ${err.code} ${err.message}');
          ad.dispose();
          _ad = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return Center(
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
