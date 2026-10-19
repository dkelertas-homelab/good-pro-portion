import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'ads_config.dart';
import 'purchases.dart';

/// A reserved ad space on a non-workout screen.
///
/// - Ads off (the default): nothing in release builds; a dashed
///   "Ad placeholder" in debug builds so layouts can be checked.
/// - Ads on: a labelled test slot (no SDK yet), hidden once the user owns
///   Remove ads.
class AdSlot extends StatelessWidget {
  const AdSlot({
    super.key,
    required this.placement,
    this.enabled = adsEnabled,
    this.showPlaceholder = kDebugMode,
    this.service,
  });

  final AdPlacement placement;
  final bool enabled;
  final bool showPlaceholder;
  final PurchaseService? service;

  static const height = 56.0;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return showPlaceholder
          ? _box(context, 'Ad placeholder')
          : const SizedBox.shrink();
    }
    return ValueListenableBuilder<bool>(
      valueListenable: (service ?? purchases).adFree,
      builder: (context, adFree, _) => adFree
          ? const SizedBox.shrink()
          : Semantics(
              label: 'Advertisement',
              child: _box(context, 'Test ad · ${TestAdIds.banner}'),
            ),
    );
  }

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
