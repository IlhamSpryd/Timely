import 'package:timely/api/auth_api.dart';
import 'package:timely/models/login_model.dart';
import 'package:timely/models/register_models.dart';
import 'package:timely/services/auth_services.dart';

class AuthRepository {
  final AuthApi _api = AuthApi();
  final AuthService _service = AuthService();

  // Login user → API + simpan ke SharedPreferences
  Future<void> login(String email, String password) async {
    final LoginModel response = await _api.login(email, password);

    if (response.data != null && response.data!.user != null) {
      await _service.saveLogin(
        response.data!.user!.email ?? '',
        response.data!.token ?? '',
      );
    } else {
      throw Exception("Invalid login response");
    }
  }

  // Register user → hanya panggil API
  Future<RegisterModel> register({
    required String name,
    required String email,
    required String password,
    required int batchId,
    required int trainingId,
    required String jenisKelamin,
  }) async {
    return await _api.register(
      name: name,
      email: email,
      password: password,
      batchId: batchId,
      trainingId: trainingId,
      jenisKelamin: jenisKelamin,
    );
  }

  // Logout user
  Future<void> logout() async {
    await _service.logout();
  }

  // Cek apakah sudah login
  Future<bool> isLoggedIn() async {
    return _service.isLoggedIn();
  }

  // Ambil email user yang tersimpan
  Future<String?> getCurrentUserEmail() async {
    return _service.getCurrentUserEmail();
  }

  // Ambil token dari local storage
  Future<String?> getToken() async {
    return _service.getToken();
  }

  // Cek apakah onboarding sudah dilihat
  Future<bool> hasSeenOnboarding() async {
    return _service.hasSeenOnboarding();
  }

  // Tandai onboarding sudah dilihat
  Future<void> setOnboardingSeen() async {
    await _service.setOnboardingSeen();
  }
}
