import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  AdSize? _adSize;
  bool _isLoaded = false;
  bool _isLoading = false;
  Timer? _retryTimer;
  int _retrySeconds = 10;

  static const String _realAdUnitId =
      'ca-app-pub-4813245225944962/2387254443';
  static const String _testAdUnitId =
      'ca-app-pub-3940256099942544/9214589741';

  // Production builds always use the real ChessMate unit.
  static const bool _forceTestAds = false;

  String get _adUnitId =>
      (kDebugMode || _forceTestAds) ? _testAdUnitId : _realAdUnitId;
  bool get _usingTestAds => kDebugMode || _forceTestAds;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null && !_isLoading) {
      _loadBanner();
    }
  }

  Future<void> _loadBanner() async {
    if (_isLoading || !mounted) return;

    _isLoading = true;
    _retryTimer?.cancel();

    final width = MediaQuery.sizeOf(context).width.truncate();
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);

    if (!mounted || size == null) {
      _isLoading = false;
      return;
    }

    await _bannerAd?.dispose();
    _bannerAd = null;
    _adSize = size;
    _isLoaded = false;

    final banner = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isLoading = false;
          _retrySeconds = 10;

          debugPrint(
            'ChessMate banner loaded (' +
            (_usingTestAds ? 'TEST' : 'LIVE') +
            '): ' +
            ad.responseInfo.toString(),
          );

          if (!mounted) {
            ad.dispose();
            return;
          }

          setState(() {
            _bannerAd = ad as BannerAd;
            _adSize = size;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint(
            'ChessMate banner failed (' +
            (_usingTestAds ? 'TEST' : 'LIVE') +
            '): ' +
            error.toString(),
          );

          ad.dispose();
          _bannerAd = null;
          _isLoaded = false;
          _isLoading = false;
          _scheduleRetry();
        },
        onAdImpression: (_) {
          debugPrint('ChessMate banner impression recorded.');
        },
        onAdClicked: (_) {
          debugPrint('ChessMate banner clicked.');
        },
      ),
    );

    _bannerAd = banner;
    await banner.load();
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();

    final delay = _retrySeconds;
    _retrySeconds = (_retrySeconds * 2).clamp(10, 300);
    _retryTimer = Timer(Duration(seconds: delay), _loadBanner);
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    final size = _adSize;

    if (!_isLoaded || ad == null || size == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: size.width.toDouble(),
      height: size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}