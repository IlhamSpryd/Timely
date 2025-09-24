import 'package:http/http.dart' as http;
import 'package:timely/api/endpoint.dart';
import 'package:timely/models/alldatauser_model.dart';
import 'package:timely/services/auth_services.dart';

class UserService {
  final AuthService _authService = AuthService();

  Future<AllDataUserModel> getAllUsers() async {
    final token = await _authService.getToken();

    final response = await http.get(
      Uri.parse(Endpoint.allUsers),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return allDataUserModelFromJson(response.body);
    } else {
      throw Exception('Failed to get users: ${response.body}');
    }
  }
}
