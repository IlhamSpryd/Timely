import 'package:intl/intl.dart';

class DateFormatter {
  /// Format: Rabu, 24 September 2025
  static String formatFullDate(DateTime date) {
    return DateFormat("EEEE, dd MMMM yyyy", "id_ID").format(date);
  }

  /// Format: 24/09/2025
  static String formatShortDate(DateTime date) {
    return DateFormat("dd/MM/yyyy", "id_ID").format(date);
  }

  /// Format: 24 September
  static String formatDayMonth(DateTime date) {
    return DateFormat("dd MMMM", "id_ID").format(date);
  }

  /// Format: 14:35
  static String formatTime(DateTime date) {
    return DateFormat("HH:mm", "id_ID").format(date);
  }

  /// Format: 2025-09-24 (buat API biasanya)
  static String formatApiDate(DateTime date) {
    return DateFormat("yyyy-MM-dd").format(date);
  }
}
