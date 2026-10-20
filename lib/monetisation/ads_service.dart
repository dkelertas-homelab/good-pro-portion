import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_config.dart';

/// Consent (UMP) and SDK start-up. Only touched when [adsEnabled].
///
/// Order follows Google's guidance: refresh consent info every launch, show
/// the form if it's required (EEA/UK), then start the SDK and allow ad
/// requests only if UMP says we can.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  /// True once consent allows ad requests and the SDK has started.
  final ValueNotifier<bool> canRequestAds = ValueNotifier(false);

  /// True when the user must be offered a "Privacy options" entry.
  final ValueNotifier<bool> privacyOptionsRequired = ValueNotifier(false);

  bool _started = false;

  Future<void> init() async {
    if (!adsEnabled || _started) return;
    _started = true;
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired((err) {
        if (err != null) debugPrint('Consent form: ${err.message}');
        if (!done.isCompleted) done.complete();
      }),
      (err) {
        // Offline or similar: fall back to whatever consent was stored.
        debugPrint('Consent info update failed: ${err.message}');
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future;
    await _refresh();
  }

  Future<void> _refresh() async {
    final can = await ConsentInformation.instance.canRequestAds();
    privacyOptionsRequired.value =
        await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
    if (can && !canRequestAds.value) {
      await MobileAds.instance.initialize();
    }
    canRequestAds.value = can;
  }

  /// Settings → Privacy options (lets EEA/UK users change their choice).
  Future<void> showPrivacyOptions() async {
    await ConsentForm.showPrivacyOptionsForm((err) {
      if (err != null) debugPrint('Privacy options: ${err.message}');
    });
    await _refresh();
  }
}
