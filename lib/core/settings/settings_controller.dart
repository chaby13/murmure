import 'package:flutter/material.dart';

import '../theme/murmure_colors.dart';

/// Préférences de l'utilisateur. Elles ne sont pas encore persistées entre
/// deux lancements (arrivera avec STORE-01).
class SettingsController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ReaderMode _readerMode = ReaderMode.light;

  ThemeMode get themeMode => _themeMode;
  ReaderMode get readerMode => _readerMode;

  set themeMode(ThemeMode value) {
    if (value == _themeMode) return;
    _themeMode = value;
    notifyListeners();
  }

  set readerMode(ReaderMode value) {
    if (value == _readerMode) return;
    _readerMode = value;
    notifyListeners();
  }
}
