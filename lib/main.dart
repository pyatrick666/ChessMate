import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/app_open_ad_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.initialize();

  runApp(const ChessMateApp());
}

class ChessMateApp extends StatefulWidget {
  const ChessMateApp({super.key});

  @override
  State<ChessMateApp> createState() => _ChessMateAppState();
}

class _ChessMateAppState extends State<ChessMateApp>
    with WidgetsBindingObserver {
  final AppOpenAdManager _appOpenAdManager = AppOpenAdManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appOpenAdManager.load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appOpenAdManager.showIfAvailable();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appOpenAdManager.dispose();
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
