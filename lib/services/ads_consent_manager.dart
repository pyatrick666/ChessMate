import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Handles Google UMP consent before any ad requests are made.
class AdsConsentManager {
  AdsConsentManager._();

  static Future<bool> initialize() async {
    final consentInfo = ConsentInformation.instance;
    final params = ConsentRequestParameters();

    try {
      await consentInfo.requestConsentInfoUpdate(params);
      await ConsentForm.loadAndShowConsentFormIfRequired();

      final canRequestAds = await consentInfo.canRequestAds();
      debugPrint(
        'ChessMate AdMob consent ready. canRequestAds=$canRequestAds',
      );
      return canRequestAds;
    } catch (error) {
      debugPrint('ChessMate AdMob consent error: $error');

      try {
        return await consentInfo.canRequestAds();
      } catch (_) {
        return false;
      }
    }
  }
}
