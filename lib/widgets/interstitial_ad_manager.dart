import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdManager {
  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  Timer? _retryTimer;
  int _retrySeconds = 10;

  static const String _realAdUnitId =
      'ca-app-pub-4813245225944962/6566172601';
  static const String _testAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  String get _adUnitId => kDebugMode ? _testAdUnitId : _realAdUnitId;
  bool get _usingTestAds => kDebugMode;

  void load() {
    if (_isLoading || _interstitialAd != null) return;

    _retryTimer?.cancel();
    _isLoading = true;

    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _retrySeconds = 10;
          _interstitialAd = ad;

          debugPrint(
            'ChessMate interstitial loaded (' +
            (_usingTestAds ? 'TEST' : 'LIVE') +
            ').',
          );
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _interstitialAd = null;

          debugPrint(
            'ChessMate interstitial failed (' +
            (_usingTestAds ? 'TEST' : 'LIVE') +
            '): ' +
            error.toString(),
          );

          _scheduleRetry();
        },
      ),
    );
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();

    final delay = _retrySeconds;
    _retrySeconds = (_retrySeconds * 2).clamp(10, 300);
    _retryTimer = Timer(Duration(seconds: delay), load);
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
      onAdShowedFullScreenContent: (_) {
        debugPrint('ChessMate interstitial shown.');
      },
      onAdImpression: (_) {
        debugPrint('ChessMate interstitial impression recorded.');
      },
      onAdClicked: (_) {
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
    _retryTimer?.cancel();
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
