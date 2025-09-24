class Endpoint {
  static const String baseURL = "https://appabsensi.mobileprojp.com/api";

  // Auth
  static const String register = "$baseURL/register";
  static const String login = "$baseURL/login";
  static const String forgotPassword = "$baseURL/forgot-password";
  static const String resetPassword = "$baseURL/reset-password";

  // Absen
  static const String checkIn = "$baseURL/absen/check-in";
  static const String checkOut = "$baseURL/absen/check-out";
  static const String absenToday = "$baseURL/absen/today";
  static const String absenStats = "$baseURL/absen/stats";
  static const String history = "$baseURL/absen/history";
  static const String izin = "$baseURL/izin";
  static const String deleteAbsen = "$baseURL/delete-absen";

  // Profile
  static const String profile = "$baseURL/profile";
  static const String profilePhoto = "$baseURL/profile/photo";
  static const String updateProfile = "$baseURL/profile";

  // Training & Batch
  static const String training = "$baseURL/trainings";
  static const String batches = "$baseURL/batches";
  static const String detailTraining = "$baseURL/trainings";

  // Device Token
  static const String deviceToken = "$baseURL/device-token";

  // Users
  static const String allUsers = "$baseURL/users";
}
