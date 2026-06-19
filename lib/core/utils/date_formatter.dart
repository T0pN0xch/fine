import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date) =>
      DateFormat('d MMM yyyy').format(date);

  static String formatMonthYear(DateTime date) =>
      DateFormat('MMMM yyyy').format(date);

  static String formatShortMonth(DateTime date) =>
      DateFormat('MMM').format(date);

  static String formatDayGroupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today, ${DateFormat('d MMM').format(date)}';
    if (d == yesterday) return 'Yesterday, ${DateFormat('d MMM').format(date)}';
    return DateFormat('EEEE, d MMM yyyy').format(date);
  }

  static String formatTime(DateTime date) =>
      DateFormat('h:mm a').format(date);

  static String formatShortDate(DateTime date) =>
      DateFormat('d MMM').format(date);
}
