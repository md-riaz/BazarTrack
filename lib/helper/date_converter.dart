import 'package:intl/intl.dart';

class DateConverter {
  static String formatApiDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  /// Parse many common server date formats into a local [DateTime].
  /// Returns null when input is null or cannot be parsed.
  static DateTime? parseApiDate(dynamic dateTime) {
    if (dateTime == null) return null;

    final String s = dateTime.toString();

    // 1) If it looks like ISO (has 'T', ends with 'Z', or has timezone offset), use DateTime.parse
    final bool looksIso = s.contains('T') || s.endsWith('Z') || RegExp(r'[+-]\d{2}(:?\d{2})?$').hasMatch(s);
    if (looksIso) {
      try {
        // DateTime.parse will handle timezone offsets and 'Z'. Convert to local.
        return DateTime.parse(s).toLocal();
      } catch (_) {
        // fallthrough to more permissive parsers
      }
    }

    // 2) Try common API format 'yyyy-MM-dd HH:mm:ss' (assume it's local, do NOT force UTC)
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parseLoose(s);
    } catch (_) {
      // parseLoose will try some leniency but fallback further
    }

    // 3) Try alternative ISO-ish format with T and milliseconds without timezone
    try {
      return DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").parseLoose(s);
    } catch (_) {}

    // 4) Last resort try DateTime.parse (may throw) and convert to local
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return null;
    }
  }

  @deprecated
  static String formatDate(DateTime dateTime) {
    return formatApiDate(dateTime);
  }

  static String estimatedDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  static DateTime convertStringToDatetime(String dateTime) {
    return DateFormat("yyyy-MM-ddTHH:mm:ss.SSS").parse(dateTime);
  }

  static DateTime isoStringToLocalDate(String dateTime) {
    return DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').parse(dateTime, true).toLocal();
  }

  static String isoStringToLocalTimeOnly(String dateTime) {
    return DateFormat('hh:mm aa').format(isoStringToLocalDate(dateTime));
  }

  static String isoStringToLocalAMPM(String dateTime) {
    return DateFormat('a').format(isoStringToLocalDate(dateTime));
  }

  static String isoStringToLocalDateOnly(String dateTime) {
    return DateFormat('dd MMM yyyy').format(isoStringToLocalDate(dateTime));
  }

  static String localDateToIsoString(DateTime dateTime) {
    return DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').format(dateTime.toUtc());
  }

  static String convertTimeToTime(String time) {
    return DateFormat('hh:mm a').format(DateFormat('hh:mm:ss').parse(time));
  }
}
