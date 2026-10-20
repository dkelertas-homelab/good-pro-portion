import 'package:flutter/material.dart';

import 'ads_config.dart';
import 'purchases.dart';

/// Settings → Upgrade. A one-off purchase: no subscription, no timers, no
/// nagging (docs/GUIDE.md, Ads and purchase).
class RemoveAdsCard extends StatefulWidget {
  const RemoveAdsCard({super.key, this.enabled = adsEnabled, this.service});

  final bool enabled;
  final PurchaseService? service;

  @override
  State<RemoveAdsCard> createState() => _RemoveAdsCardState();
}

class _RemoveAdsCardState extends State<RemoveAdsCard> {
  PurchaseService get _svc => widget.service ?? purchases;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _svc.init();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    if (!widget.enabled) {
      return Card(
        child: ListTile(
          leading: const Text('✨', style: TextStyle(fontSize: 22)),
          title: const Text('Remove ads'),
          subtitle: const Text(
            'One-off purchase · no subscription (coming later)',
          ),
          trailing: Text(
            'A\$X.XX',
            style: TextStyle(color: primary, fontWeight: FontWeight.w700),
          ),
          enabled: false,
        ),
      );
    }
    return ValueListenableBuilder<bool>(
      valueListenable: _svc.adFree,
      builder: (context, adFree, _) => Card(
        child: Column(
          children: [
            ListTile(
              leading: const Text('✨', style: TextStyle(fontSize: 22)),
              title: const Text('Remove ads'),
              subtitle: Text(
                adFree
                    ? 'Thanks! Ads are off on this phone.'
                    : 'One-off purchase · no subscription',
              ),
              trailing: adFree
                  ? Icon(Icons.check_circle, color: primary)
                  : FilledButton(
                      // The app theme makes buttons full-width; not here.
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(88, 48),
                      ),
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              final r = await _svc.buyRemoveAds();
                              if (!context.mounted) return;
                              if (r == PurchaseOutcome.failed) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "That didn't go through. Nothing was charged.",
                                    ),
                                  ),
                                );
                              }
                            }),
                      child: Text(_svc.priceLabel ?? 'Buy'),
                    ),
            ),
            if (!adFree)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                          final owned = await _svc.restore();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                owned ? 'Restored. Ads are off.' : 'No earlier purchase found on this account.',
                              ),
                            ),
                          );
                        }),
                  child: const Text('Restore purchase'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
