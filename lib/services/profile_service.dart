// profile_service.dart
import 'package:http/http.dart' as http;
import 'package:timely/api/endpoint.dart';
import 'package:timely/models/getprofile_model.dart';
import 'package:timely/services/auth_services.dart';

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

  Future<void> updateProfilePhoto(String imagePath) async {
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

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile photo: ${response.body}');
    }
  }
}
