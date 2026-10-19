import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PurchaseOutcome { purchased, cancelled, failed }

/// The one-off "Remove ads" purchase. No subscriptions.
abstract class PurchaseService {
  /// True once the user owns Remove ads. Ads hide while this is true.
  ValueListenable<bool> get adFree;

  /// Price as the store formats it, or null if unknown.
  String? get priceLabel;

  Future<void> init();
  Future<PurchaseOutcome> buyRemoveAds();

  /// Re-checks ownership, e.g. after a reinstall or on a new phone.
  Future<bool> restore();
}

/// Stand-in until Play Billing is wired up: "buying" just sets a local flag,
/// so the flows can be tried on a test build without a store product.
class StubPurchaseService implements PurchaseService {
  StubPurchaseService([this._prefs]);

  static const _key = 'stub_remove_ads_owned';
  SharedPreferences? _prefs;
  final _adFree = ValueNotifier<bool>(false);

  @override
  ValueListenable<bool> get adFree => _adFree;

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

/// The app-wide purchase service. Only used when ads are enabled
/// (see ads_config.dart). Swap for the Play Billing one when it's wired up.
final PurchaseService purchases = StubPurchaseService();
