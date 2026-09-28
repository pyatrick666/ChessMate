import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Handles Google UMP consent before any ad requests are made.
class AdsConsentManager {
  AdsConsentManager._();

  static Future<bool> initialize() async {
    final consentInfo = ConsentInformation.instance;
    final params = ConsentRequestParameters();

    try {
      await _requestConsentInfoUpdate(consentInfo, params);
      await _loadAndShowConsentFormIfRequired();

      final canRequestAds = await consentInfo.canRequestAds();
      debugPrint(
        'ChessMate AdMob consent ready. canRequestAds=$canRequestAds',
      );
      return canRequestAds;
    } catch (error) {
      debugPrint('ChessMate AdMob consent error: $error');

      // UMP may retain a valid previous consent decision after a transient
      // network/update error, so check the authoritative flag once more.
      try {
        return await consentInfo.canRequestAds();
      } catch (_) {
        return false;
      }
    }
  }

  static Future<void> _requestConsentInfoUpdate(
    ConsentInformation consentInfo,
    ConsentRequestParameters params,
  ) {
    final completer = Completer<void>();

    consentInfo.requestConsentInfoUpdate(
      params,
      () => completer.complete(),
      (error) => completer.completeError(error),
    );

    return completer.future;
  }

  static Future<void> _loadAndShowConsentFormIfRequired() {
    final completer = Completer<void>();

    ConsentForm.loadAndShowConsentFormIfRequired(
      (error) {
        if (error != null) {
          completer.completeError(error);
        } else {
          completer.complete();
        }
      },
    );

    return completer.future;
  }
}
