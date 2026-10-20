import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'play_billing.dart';

enum PurchaseOutcome {
  purchased,
  cancelled,
  failed,

  /// Payment is pending (e.g. cash at a shop); ads go once Play confirms.
  pending,

  /// Billing or the product isn't available (no Play, not set up yet).
  unavailable,
}

/// The one-off "Remove ads" purchase. No subscriptions.
abstract class PurchaseService {
  /// True once the user owns Remove ads. Ads hide while this is true.
  ValueListenable<bool> get adFree;

  /// True when the product can be bought right now.
  ValueListenable<bool> get available;

  /// Price as the store formats it, or null if unknown.
  String? get priceLabel;

  Future<void> init();
  Future<PurchaseOutcome> buyRemoveAds();

  /// Re-checks ownership, e.g. after a reinstall or on a new phone.
  Future<bool> restore();
}

/// Local stand-in: "buying" just sets a flag. Used by tests and available for
/// trying the flows without a Play product.
class StubPurchaseService implements PurchaseService {
  StubPurchaseService([this._prefs]);

  static const _key = 'stub_remove_ads_owned';
  SharedPreferences? _prefs;
  final _adFree = ValueNotifier<bool>(false);

  @override
  ValueListenable<bool> get adFree => _adFree;

  final _available = ValueNotifier<bool>(true);

  @override
  ValueListenable<bool> get available => _available;

  @override
  String? get priceLabel => 'Test';

  @override
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _adFree.value = _prefs!.getBool(_key) ?? false;
  }

  @override
  Future<PurchaseOutcome> buyRemoveAds() async {
    await init();
    await _prefs!.setBool(_key, true);
    _adFree.value = true;
    return PurchaseOutcome.purchased;
  }

  @override
  Future<bool> restore() async {
    await init();
    return _adFree.value;
  }

  /// Test builds only: forget the stub purchase.
  Future<void> reset() async {
    await init();
    await _prefs!.remove(_key);
    _adFree.value = false;
  }
}

/// The app-wide purchase service (Google Play Billing). Only used when ads
/// are enabled (see ads_config.dart).
final PurchaseService purchases = PlayPurchaseService();
