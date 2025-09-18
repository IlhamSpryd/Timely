class Endpoint {
  static const String baseUrl = "https://appabsensi.mobileprojp.com/api";
  static const String register = "$baseUrl/register";
  static const String login = "$baseUrl/login";
  static const String forgotPassword = "$baseUrl/forgot-password";
  static const String resetPassword = "$baseUrl/reset-password";

  // absen
  static const String checkIn = "$baseUrl/absen-check-in";
  static const String checkOut = "$baseUrl/absen-check-out";
  static const String absenToday = "$baseUrl/absen/today";
  static const String absenStats = "$baseUrl/absen/stats";

  // history
  static const String history = "$baseUrl/history-absen";

  // profile
  static const String profile = "$baseUrl/profile";
  static const String profilePhoto = "$baseUrl/profile/photo";
  static const String updateProfile = "$baseUrl/profile";

  // izin, delete absen
  static const String izin = "$baseUrl/izin";
  static const String deleteAbsen = "$baseUrl/delete-absen";

  // additional endpoints
  static const String training = "$baseUrl/trainings";
  static const String batches = "$baseUrl/batches";
}
