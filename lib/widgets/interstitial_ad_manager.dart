import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdManager {
  InterstitialAd? _interstitialAd;
  bool _isLoading = false;

  static const String _realAdUnitId =
      'ca-app-pub-4813245225944962/1867370531';

  static const String _testAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  String get _adUnitId => kDebugMode ? _testAdUnitId : _realAdUnitId;

  void load() {
    if (_isLoading || _interstitialAd != null) return;

    _isLoading = true;

    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _interstitialAd = ad;
          debugPrint(
            'ChessMate interstitial loaded '
            '(${kDebugMode ? 'TEST' : 'LIVE'}).',
          );
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _interstitialAd = null;
          debugPrint(
            'ChessMate interstitial failed '
            '(${kDebugMode ? 'TEST' : 'LIVE'}): $error',
          );
        },
      ),
    );
  }

  void show({required VoidCallback onDismissed}) {
    final ad = _interstitialAd;

    if (ad == null) {
      load();
      onDismissed();
      return;
    }

    _interstitialAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('ChessMate interstitial shown.');
      },
      onAdImpression: (ad) {
        debugPrint('ChessMate interstitial impression recorded.');
      },
      onAdClicked: (ad) {
        debugPrint('ChessMate interstitial clicked.');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('ChessMate interstitial failed to show: $error');
        ad.dispose();
        onDismissed();
        load();
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('ChessMate interstitial dismissed.');
        ad.dispose();
        onDismissed();
        load();
      },
    );

    ad.show();
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
