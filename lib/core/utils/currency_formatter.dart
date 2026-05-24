import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static const Map<String, String> _banglaDigits = {
    '0': '০',
    '1': '১',
    '2': '২',
    '3': '৩',
    '4': '৪',
    '5': '৫',
    '6': '৬',
    '7': '৭',
    '8': '৮',
    '9': '৯',
  };

  static String format(
    num value, {
    bool includeSymbol = true,
    bool compact = false,
  }) {
    final formatter = compact
        ? NumberFormat.compact(locale: 'en_US')
        : NumberFormat('#,##0.##', 'en_US');
    final formatted = formatter.format(value.abs());
    final localized = toBanglaDigits(formatted);
    final prefix = includeSymbol ? '৳ ' : '';
    final sign = value < 0 ? '-' : '';
    return '$sign$prefix$localized';
  }

  static String toBanglaDigits(String input) {
    return input.split('').map((char) => _banglaDigits[char] ?? char).join();
  }
}
