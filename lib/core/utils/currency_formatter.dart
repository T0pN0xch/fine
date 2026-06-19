import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, {String symbol = 'RM'}) {
    final f = NumberFormat('#,##0.00');
    return '$symbol ${f.format(amount.abs())}';
  }

  static String formatSigned(double amount, {String symbol = 'RM'}) {
    final f = NumberFormat('#,##0.00');
    return '${amount >= 0 ? '+' : '-'}$symbol ${f.format(amount.abs())}';
  }

  static String formatCompact(double amount, {String symbol = 'RM'}) {
    return format(amount, symbol: symbol);
  }
}
