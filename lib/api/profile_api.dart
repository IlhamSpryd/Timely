import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:timely/services/auth_services.dart';
import 'package:timely/models/getprofile_model.dart';
import 'package:timely/models/editprofile_model.dart';
import 'package:timely/models/editphotoprofile.dart';
import 'package:timely/api/endpoint.dart';

class ProfileService {
  final AuthService _authService = AuthService();

  Future<GetProfileModel> getProfile() async {
    final token = await _authService.getToken();

    final response = await http.get(
      Uri.parse(Endpoint.profile),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return getProfileModelFromJson(response.body);
    } else {
      throw Exception('Failed to get profile: ${response.body}');
    }
  }

  Future<EditProfileModel> updateProfile({
    required String name,
    required String email,
    required int batchId,
    required int trainingId,
    required String jenisKelamin,
  }) async {
    final token = await _authService.getToken();

    final response = await http.put(
      Uri.parse(Endpoint.updateProfile),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "name": name,
        "email": email,
        "batch_id": batchId,
        "training_id": trainingId,
        "jenis_kelamin": jenisKelamin,
      }),
    );

    if (response.statusCode == 200) {
      return editProfileModelFromJson(response.body);
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  Future<EditPhotoProfileModel> updateProfilePhoto(String imagePath) async {
    final token = await _authService.getToken();

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(Endpoint.profilePhoto),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('profile_photo', imagePath),
    );

    var response = await http.Response.fromStream(await request.send());

    if (response.statusCode == 200) {
      return editPhotoProfileModelFromJson(response.body);
    } else {
      throw Exception('Failed to update profile photo: ${response.body}');
    }
  }
}
