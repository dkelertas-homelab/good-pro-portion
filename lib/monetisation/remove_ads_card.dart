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
    return ListenableBuilder(
      listenable: Listenable.merge([_svc.adFree, _svc.available]),
      builder: (context, _) => _card(context, primary),
    );
  }

  static const _messages = {
    PurchaseOutcome.failed: "That didn't go through. Nothing was charged.",
    PurchaseOutcome.pending:
        'Payment pending. Ads switch off once Google Play confirms it.',
    PurchaseOutcome.unavailable:
        "Remove ads isn't available right now. Try again later.",
  };

  Widget _card(BuildContext context, Color primary) {
    final adFree = _svc.adFree.value;
    final available = _svc.available.value;
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Text('✨', style: TextStyle(fontSize: 22)),
            title: const Text('Remove ads'),
            subtitle: Text(
              adFree
                  ? 'Thanks! Ads are off on this phone.'
                  : available
                  ? 'One-off purchase · no subscription'
                  : 'Not available right now',
            ),
            trailing: adFree
                ? Icon(Icons.check_circle, color: primary)
                : !available
                ? null
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
                            final msg = _messages[r];
                            if (msg != null) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text(msg)));
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
    );
  }
}
