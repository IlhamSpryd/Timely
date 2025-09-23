import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/api/auth_api.dart';
import 'package:timely/models/login_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final AuthApi _authApi = AuthApi();

  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUserEmail = 'userEmail';
  static const String _keyUserName = 'userName';
  static const String _keyAuthToken = 'authToken';
  static const String _keyHasSeenOnboarding = 'hasSeenOnboarding';
  static const String _keyUserData = 'userData';

  // 🔹 LOGIN - Menggunakan AuthApi
  Future<bool> login(String email, String password) async {
    try {
      final loginResponse = await _authApi.login(email, password);

      if (loginResponse.data != null) {
        final token = loginResponse.data!.token ?? "";
        final userEmail = loginResponse.data!.user?.email ?? "";
        final userName = loginResponse.data!.user?.name ?? "User";

        await _saveLoginData(userEmail, token, userName, loginResponse);
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // 🔹 Save login data dengan lebih lengkap
  Future<void> _saveLoginData(
    String email,
    String token,
    String name,
    LoginModel loginResponse,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyAuthToken, token);

    // Simpan data user lengkap sebagai JSON string
    await prefs.setString(_keyUserData, jsonEncode(loginResponse.toJson()));
  }

  // 🔹 Save login data (untuk digunakan oleh AuthRepository)
  Future<void> saveLogin(String email, String token, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyAuthToken, token);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyAuthToken);
    await prefs.remove(_keyUserData);
  }

  Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAuthToken);
  }

  // 🔹 Get full user data
  Future<LoginModel?> getFullUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataJson = prefs.getString(_keyUserData);
    if (userDataJson != null) {
      return LoginModel.fromJson(json.decode(userDataJson));
    }
    return null;
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
