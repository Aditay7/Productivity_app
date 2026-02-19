import 'package:intl/intl.dart';

/// Utility class for date operations
class DateUtils {
  /// Get current date as ISO string (YYYY-MM-DD)
  static String today() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// Get current datetime as ISO string
  static String now() {
    return DateTime.now().toIso8601String();
  }

  /// Parse ISO date string to DateTime
  static DateTime? parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Check if date2 is exactly one day after date1
  static bool isNextDay(DateTime date1, DateTime date2) {
    final nextDay = DateTime(date1.year, date1.month, date1.day + 1);
    return isSameDay(nextDay, date2);
  }

  /// Calculate days between two dates
  static int daysBetween(DateTime date1, DateTime date2) {
    final d1 = DateTime(date1.year, date1.month, date1.day);
    final d2 = DateTime(date2.year, date2.month, date2.day);
    return d2.difference(d1).inDays;
  }

  /// Format date for display (e.g., "Jan 15, 2024")
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format datetime for display (e.g., "Jan 15, 2024 3:30 PM")
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy h:mm a').format(dateTime);
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Get relative date string (Today, Yesterday, or formatted date)
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    if (isToday(date)) return 'Today';

    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (isSameDay(date, yesterday)) return 'Yesterday';

    return formatDate(date);
  }
}
