import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/models/login_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _baseUrl = "https://appabsensi.mobileprojp.com/api";
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUserEmail = 'userEmail';
  static const String _keyAuthToken = 'authToken';
  static const String _keyHasSeenOnboarding = 'hasSeenOnboarding';

  // 🔹 LOGIN API
  Future<bool> login(String email, String password) async {
    final url = Uri.parse("$_baseUrl/login");
    final response = await http.post(
      url,
      body: {"email": email, "password": password},
    );

    if (response.statusCode == 200) {
      final loginResponse = LoginModel.fromJson(json.decode(response.body));

      if (loginResponse.data != null) {
        final token = loginResponse.data!.token ?? "";
        final userEmail = loginResponse.data!.user?.email ?? "";

        await saveLogin(userEmail, token);
        return true;
      }
    }
    return false;
  }

  // 🔹 Save login data
  Future<void> saveLogin(String email, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyAuthToken, token);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // 🔹 Logout hanya hapus data login, tidak reset onboarding
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyAuthToken);
  }

  // 🔹 Optional: reset semua data (factory reset app)
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAuthToken);
  }

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSeenOnboarding) ?? false;
  }

  Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenOnboarding, true);
  }
}
