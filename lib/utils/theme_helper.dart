import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeHelper {
  static const String _themeKey = 'theme_mode';

  /// Save theme mode ke SharedPreferences
  static Future<void> saveTheme(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, themeMode.index);
  }

  /// Load theme mode dari SharedPreferences
  static Future<ThemeMode> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey);
    return (themeIndex != null && themeIndex >= 0 && themeIndex <= 2)
        ? ThemeMode.values[themeIndex]
        : ThemeMode.system; // default
  }
}
