import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:timely/api/endpoint.dart';
import 'package:timely/models/login_model.dart';
import 'package:timely/models/register_models.dart';

class AuthApi {
  Future<LoginModel> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(Endpoint.login),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      return loginModelFromJson(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(
        errorData['message'] ?? 'Login failed: ${response.statusCode}',
      );
    }
  }

  // Register
  Future<RegisterModel> register({
    required String name,
    required String email,
    required String password,
    required int batchId,
    required int trainingId,
    required String jenisKelamin,
  }) async {
    final response = await http.post(
      Uri.parse(Endpoint.register),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "batch_id": batchId,
        "training_id": trainingId,
        "jenis_kelamin": jenisKelamin,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return registerModelFromJson(response.body);
    } else {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['message'] ?? 'Registrasi gagal';

      if (errorData['errors'] != null) {
        final errors = errorData['errors'] as Map<String, dynamic>;
        final firstError = errors.values.first;
        if (firstError is List) {
          throw Exception(firstError.first ?? errorMessage);
        } else {
          throw Exception(firstError.toString());
        }
      } else {
        throw Exception(errorMessage);
      }
    }
  }

  // Forgot Password
  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse(Endpoint.forgotPassword),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    if (response.statusCode != 200) {
      final errorData = json.decode(response.body);
      throw Exception(
        errorData['message'] ?? 'Failed to send reset password email',
      );
    }
  }

  // Reset Password
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse(Endpoint.resetPassword),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "token": token,
        "password": password,
        "password_confirmation": passwordConfirmation,
      }),
    );

    if (response.statusCode != 200) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to reset password');
    }
  }
}
