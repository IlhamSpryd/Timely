import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:timely/models/login_model.dart';
import 'package:timely/models/register_models.dart';

class AuthApi {
  final String baseUrl = "https://appabsensi.mobileprojp.com/api";

  // login
  Future<LoginModel> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      return loginModelFromJson(response.body);
    } else {
      throw Exception('Failed to login: ${response.body}');
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
      Uri.parse('$baseUrl/register'),
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
      throw Exception('Failed to register: ${response.body}');
    }
  }
}
