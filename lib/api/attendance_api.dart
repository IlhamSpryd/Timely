import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:timely/services/auth_services.dart';
import 'package:timely/models/checkin_model.dart';
import 'package:timely/models/checkout_model.dart';
import 'package:timely/models/absen_today.dart';
import 'package:timely/models/absen_stats.dart';
import 'package:timely/models/historyabsen_model.dart';
import 'package:timely/models/izin_model.dart';
import 'package:timely/models/deleteabsen_model.dart';
import 'package:timely/api/endpoint.dart';

class AbsenService {
  final AuthService _authService = AuthService();

  Future<CheckinModel> checkIn(
    double lat,
    double lng,
    String address,
    String location,
  ) async {
    final token = await _authService.getToken();

    final response = await http.post(
      Uri.parse(Endpoint.checkIn),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "check_in_lat": lat,
        "check_in_lng": lng,
        "check_in_address": address,
        "check_in_location": location,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return checkinModelFromJson(response.body);
    } else {
      throw Exception('Failed to check in: ${response.body}');
    }
  }

  Future<CheckoutModel> checkOut(
    double lat,
    double lng,
    String address,
    String location,
  ) async {
    final token = await _authService.getToken();

    final response = await http.post(
      Uri.parse(Endpoint.checkOut),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "check_out_lat": lat,
        "check_out_lng": lng,
        "check_out_address": address,
        "check_out_location": location,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return checkoutModelFromJson(response.body);
    } else {
      throw Exception('Failed to check out: ${response.body}');
    }
  }

  Future<AbsenTodayModel> getTodayAbsen() async {
    final token = await _authService.getToken();

    final response = await http.get(
      Uri.parse(Endpoint.absenToday),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return absenTodayModelFromJson(response.body);
    } else {
      throw Exception('Failed to get today absen: ${response.body}');
    }
  }

  Future<AbsenStatsModel> getAbsenStats() async {
    final token = await _authService.getToken();

    final response = await http.get(
      Uri.parse(Endpoint.absenStats),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return absenStatsModelFromJson(response.body);
    } else {
      throw Exception('Failed to get absen stats: ${response.body}');
    }
  }

  Future<HistoryAbsenModel> getHistoryAbsen() async {
    final token = await _authService.getToken();

    final response = await http.get(
      Uri.parse(Endpoint.history),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return historyAbsenModelFromJson(response.body);
    } else {
      throw Exception('Failed to get history: ${response.body}');
    }
  }

  Future<IzinModel> izin(String alasanIzin) async {
    final token = await _authService.getToken();

    final response = await http.post(
      Uri.parse(Endpoint.izin),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"alasan_izin": alasanIzin}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return izinModelFromJson(response.body);
    } else {
      throw Exception('Failed to submit izin: ${response.body}');
    }
  }

  Future<DeleteAbsenModel> deleteAbsen(int absenId) async {
    final token = await _authService.getToken();

    final response = await http.delete(
      Uri.parse('${Endpoint.deleteAbsen}/$absenId'),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return deleteAbsenModelFromJson(response.body);
    } else {
      throw Exception('Failed to delete absen: ${response.body}');
    }
  }
}
