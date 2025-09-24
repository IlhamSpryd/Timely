import 'package:http/http.dart' as http;
import 'package:timely/api/endpoint.dart';
import 'package:timely/models/detailtraining_model.dart';
import 'package:timely/models/listallbatches_model.dart';
import 'package:timely/models/traininglist_model.dart';
import 'package:timely/services/auth_services.dart';

class TrainingService {
  final AuthService _authService = AuthService();

  Future<ListTrainingModel> getTrainings() async {
    final token = await _authService.getToken();

    final response = await http.get(
      Uri.parse(Endpoint.training),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return listTrainingModelFromJson(response.body);
    } else {
      throw Exception('Failed to get trainings: ${response.body}');
    }
  }

  Future<AllbatchesModel> getBatches() async {
    final token = await _authService.getToken();

    final response = await http.get(
      Uri.parse(Endpoint.batches),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return allbatchesModelFromJson(response.body);
    } else {
      throw Exception('Failed to get batches: ${response.body}');
    }
  }

  Future<DetailTrainingModel> getTrainingDetail(int trainingId) async {
    final token = await _authService.getToken();

    final response = await http.get(
      Uri.parse('${Endpoint.detailTraining}/$trainingId'),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return detailTrainingModelFromJson(response.body);
    } else {
      throw Exception('Failed to get training detail: ${response.body}');
    }
  }
}
