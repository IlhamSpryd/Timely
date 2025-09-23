import 'package:flutter/material.dart';
import 'theme_helper.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeProvider({ThemeMode initialTheme = ThemeMode.system})
    : _themeMode = initialTheme;

  ThemeMode get themeMode => _themeMode;

  void setTheme(ThemeMode newTheme) {
    _themeMode = newTheme;
    ThemeHelper.saveTheme(newTheme);
    notifyListeners();
  }
}
