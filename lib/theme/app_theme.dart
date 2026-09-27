import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF4F46E5),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF818CF8),
        scaffoldBackgroundColor: const Color(0xFF101218),
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
      );
}
