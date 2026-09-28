import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'services/ads_consent_manager.dart';
import 'theme/app_theme.dart';
import 'widgets/app_open_ad_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final canRequestAds = await AdsConsentManager.initialize();

  if (canRequestAds) {
    await MobileAds.instance.initialize();
  } else {
    debugPrint('ChessMate: ads disabled because consent is not available.');
  }

  runApp(ChessMateApp(adsEnabled: canRequestAds));
}

class ChessMateApp extends StatefulWidget {
  const ChessMateApp({super.key, required this.adsEnabled});

  final bool adsEnabled;

  @override
  State<ChessMateApp> createState() => _ChessMateAppState();
}

class _ChessMateAppState extends State<ChessMateApp>
    with WidgetsBindingObserver {
  AppOpenAdManager? _appOpenAdManager;
  bool _hasBeenBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.adsEnabled) {
      _appOpenAdManager = AppOpenAdManager()..load();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _hasBeenBackgrounded = true;
      return;
    }

    if (state == AppLifecycleState.resumed && _hasBeenBackgrounded) {
      _appOpenAdManager?.showIfAvailable();
      _hasBeenBackgrounded = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appOpenAdManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ChessMate',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
