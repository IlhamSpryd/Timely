class StringHelper {
  static String getInitials(String name) {
    final parts = name.trim().split(" ");
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    } else {
      return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
          .toUpperCase();
    }
  }
}
