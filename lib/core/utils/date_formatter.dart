import 'package:intl/intl.dart';

import 'currency_formatter.dart';

class AppDateFormatter {
  AppDateFormatter._();

  static String banglaShort(DateTime date) {
    final formatted = DateFormat('d MMM yyyy', 'en_US').format(date);
    return CurrencyFormatter.toBanglaDigits(formatted);
  }

  static String banglaMonth(DateTime date) {
    const months = <int, String>{
      1: 'জানুয়ারি',
      2: 'ফেব্রুয়ারি',
      3: 'মার্চ',
      4: 'এপ্রিল',
      5: 'মে',
      6: 'জুন',
      7: 'জুলাই',
      8: 'আগস্ট',
      9: 'সেপ্টেম্বর',
      10: 'অক্টোবর',
      11: 'নভেম্বর',
      12: 'ডিসেম্বর',
    };

    return '${months[date.month]} ${CurrencyFormatter.toBanglaDigits(date.year.toString())}';
  }

  static String relativeDayLabel(DateTime date, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    final current = DateTime(reference.year, reference.month, reference.day);
    final diff = current.difference(day).inDays;
    if (diff == 0) return 'আজকে';
    if (diff == 1) return 'গতকাল';
    return banglaShort(date);
  }
}
