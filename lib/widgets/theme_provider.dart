import 'package:flutter/material.dart';
import 'package:timely/utils/theme_helper.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode;

  ThemeProvider({required ThemeMode initialTheme}) : _themeMode = initialTheme;

  ThemeMode get themeMode => _themeMode;

  Future<void> setTheme(ThemeMode themeMode) async {
    _themeMode = themeMode;
    await ThemeHelper.saveTheme(themeMode);
    notifyListeners();
  }

  bool get isDarkMode {
    return _themeMode == ThemeMode.dark;
  }
}
