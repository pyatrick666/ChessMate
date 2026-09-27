import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AppOpenAdManager {
  AppOpenAd? _appOpenAd;
  bool _isLoading = false;
  bool _isShowing = false;

  static const String _realAdUnitId =
      'ca-app-pub-4813245225944962/6566172601';

  static const String _testAdUnitId =
      'ca-app-pub-3940256099942544/9257395921';

  String get _adUnitId => kDebugMode ? _testAdUnitId : _realAdUnitId;

  void load() {
    if (_isLoading || _appOpenAd != null) return;

    _isLoading = true;

    AppOpenAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _appOpenAd = ad;
          debugPrint(
            'ChessMate app open ad loaded (${kDebugMode ? 'TEST' : 'LIVE'}).',
          );
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _appOpenAd = null;
          debugPrint(
            'ChessMate app open ad failed (${kDebugMode ? 'TEST' : 'LIVE'}): $error',
          );
        },
      ),
    );
  }

  void showIfAvailable() {
    if (_isShowing) return;

    final ad = _appOpenAd;
    if (ad == null) {
      load();
      return;
    }

    _appOpenAd = null;
    _isShowing = true;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('ChessMate app open ad shown.');
      },
      onAdImpression: (ad) {
        debugPrint('ChessMate app open ad impression recorded.');
      },
      onAdClicked: (ad) {
        debugPrint('ChessMate app open ad clicked.');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('ChessMate app open ad failed to show: $error');
        _isShowing = false;
        ad.dispose();
        load();
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('ChessMate app open ad dismissed.');
        _isShowing = false;
        ad.dispose();
        load();
      },
    );

    ad.show();
  }

  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }
}
