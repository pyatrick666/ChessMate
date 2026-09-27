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
  bool _isLoaded = false;

  // ChessMate production banner.
  static const String _realAdUnitId =
      'ca-app-pub-4813245225944962/2387254443';

  // Google's Android banner test unit.
  static const String _testAdUnitId =
      'ca-app-pub-3940256099942544/9214589741';

  String get _adUnitId => kDebugMode ? _testAdUnitId : _realAdUnitId;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    final banner = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint(
            'ChessMate banner loaded (${kDebugMode ? 'TEST' : 'LIVE'}).',
          );

          if (!mounted) return;

          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint(
            'ChessMate banner failed '
            '(${kDebugMode ? 'TEST' : 'LIVE'}): $error',
          );

          ad.dispose();

          if (!mounted) return;

          setState(() {
            _bannerAd = null;
            _isLoaded = false;
          });
        },
        onAdImpression: (ad) {
          debugPrint('ChessMate banner impression recorded.');
        },
        onAdClicked: (ad) {
          debugPrint('ChessMate banner clicked.');
        },
        onAdOpened: (ad) {
          debugPrint('ChessMate banner opened.');
        },
        onAdClosed: (ad) {
          debugPrint('ChessMate banner closed.');
        },
      ),
    );

    banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
