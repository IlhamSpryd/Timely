import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeHelper {
  static const String _themeKey = 'theme_mode';

  /// Save theme mode ke SharedPreferences
  static Future<void> saveTheme(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_themeKey, themeMode.index); // 0=system, 1=light, 2=dark
  }

  /// Load theme mode dari SharedPreferences
  static Future<ThemeMode> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex != null && themeIndex >= 0 && themeIndex <= 2) {
      return ThemeMode.values[themeIndex];
    }
    return ThemeMode.system; // default
  }
}
