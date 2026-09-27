import 'package:flutter/foundation.dart';

import '../models/game_settings.dart';

class SettingsProvider extends ChangeNotifier {
  GameSettings _settings = const GameSettings();
  bool _darkMode = false;

  GameSettings get settings => _settings;
  bool get darkMode => _darkMode;

  void setMode(GameMode mode) {
    _settings = _settings.copyWith(mode: mode);
    notifyListeners();
  }

  void setDifficulty(Difficulty difficulty) {
    _settings = _settings.copyWith(difficulty: difficulty);
    notifyListeners();
  }

  void setOrientation(BoardOrientation orientation) {
    _settings = _settings.copyWith(orientation: orientation);
    notifyListeners();
  }

  void toggleTheme() {
    _darkMode = !_darkMode;
    notifyListeners();
  }
}
