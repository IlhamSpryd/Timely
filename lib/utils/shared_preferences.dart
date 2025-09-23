// import 'package:shared_preferences/shared_preferences.dart';

// class SharedPreferencesHelper {
//   // 🔑 Keys
//   static const String _keyToken = "auth_token";
//   static const String _keyUserName = "user_name";
//   static const String _keyUserEmail = "user_email";
//   static const String _keyUserId = "user_id";
//   static const String _keyOnboardingCompleted = "onboarding_completed";
//   static const String _keyDarkMode = "dark_mode";
//   static const String _keyFavorites = "favorite_books";

//   static Future<void> saveToken(String token) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_keyToken, token);
//   }

//   static Future<String?> getToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_keyToken);
//   }

//   static Future<void> clearToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_keyToken);
//   }

//   static Future<void> saveUser({
//     required int id,
//     required String name,
//     required String email,
//   }) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt(_keyUserId, id);
//     await prefs.setString(_keyUserName, name);
//     await prefs.setString(_keyUserEmail, email);
//   }

//   static Future<int?> getUserId() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getInt(_keyUserId);
//   }

//   static Future<String?> getUserName() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_keyUserName);
//   }

//   static Future<String?> getUserEmail() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_keyUserEmail);
//   }

//   static Future<void> clearUser() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_keyUserId);
//     await prefs.remove(_keyUserName);
//     await prefs.remove(_keyUserEmail);
//   }

//   static Future<void> setDarkMode(bool isDark) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_keyDarkMode, isDark);
//   }

//   static Future<bool> getDarkMode() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getBool(_keyDarkMode) ?? false; // default: light
//   }

//   static Future<void> setOnboardingCompleted(bool completed) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_keyOnboardingCompleted, completed);
//   }

//   static Future<bool> isOnboardingCompleted() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getBool(_keyOnboardingCompleted) ?? false;
//   }

//   static Future<void> saveFavorites(List<String> favorites) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setStringList(_keyFavorites, favorites);
//   }

//   static Future<List<String>> getFavorites() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getStringList(_keyFavorites) ?? [];
//   }

//   static Future<void> addFavorite(String id) async {
//     final prefs = await SharedPreferences.getInstance();
//     final favorites = prefs.getStringList(_keyFavorites) ?? [];
//     if (!favorites.contains(id)) {
//       favorites.add(id);
//       await prefs.setStringList(_keyFavorites, favorites);
//     }
//   }

//   static Future<void> removeFavorite(String id) async {
//     final prefs = await SharedPreferences.getInstance();
//     final favorites = prefs.getStringList(_keyFavorites) ?? [];
//     favorites.remove(id);
//     await prefs.setStringList(_keyFavorites, favorites);
//   }

//   static Future<bool> isFavorite(String id) async {
//     final prefs = await SharedPreferences.getInstance();
//     final favorites = prefs.getStringList(_keyFavorites) ?? [];
//     return favorites.contains(id);
//   }

//   static Future<void> clearAll() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//   }
// }
