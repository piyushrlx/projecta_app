import 'package:intl/intl.dart';

/// Centralized Date and Time formatting matching web localhost/projecta (functions.php)
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _dateFormat = DateFormat('d MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('d MMM yyyy, HH:mm');
  static final DateFormat _dateTime12Format = DateFormat('d MMM yyyy, hh:mm a');

  /// Safely parses MySQL UTC timestamp into a UTC DateTime
  static DateTime? parseUtc(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    try {
      // If date-only format YYYY-MM-DD
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) {
        return DateTime.parse(trimmed);
      }
      // If already has timezone indicator 'Z', '+', or '-' with time offset
      if (trimmed.endsWith('Z') ||
          trimmed.contains('+') ||
          RegExp(r'[T ]\d{2}:\d{2}:\d{2}-\d{2}').hasMatch(trimmed)) {
        return DateTime.parse(trimmed).toUtc();
      }
      // MySQL standard datetime format: YYYY-MM-DD HH:MM:SS (which is UTC in ProjectA)
      final isoStr = '${trimmed.replaceFirst(' ', 'T')}Z';
      return DateTime.parse(isoStr);
    } catch (_) {
      try {
        return DateTime.parse(trimmed);
      } catch (_) {
        return null;
      }
    }
  }

  /// Formats date strings (e.g. '2026-11-10' or '2026-11-10 00:00:00') into '10 Nov 2026'.
  /// Returns [fallback] ('—') if null, empty, or unparseable.
  static String fmtDate(String? value, {String fallback = '—'}) {
    if (value == null || value.trim().isEmpty) return fallback;
    try {
      final parsed = DateTime.parse(value.trim());
      return _dateFormat.format(parsed);
    } catch (_) {
      return value;
    }
  }

  /// Formats datetime strings (e.g. '2026-11-10 14:30:00') into '10 Nov 2026, 14:30'.
  /// Returns [fallback] ('—') if null, empty, or unparseable.
  static String fmtDateTime(String? value, {String fallback = '—', bool use24Hour = true}) {
    if (value == null || value.trim().isEmpty) return fallback;
    try {
      final parsed = DateTime.parse(value.trim());
      return use24Hour ? _dateTimeFormat.format(parsed) : _dateTime12Format.format(parsed);
    } catch (_) {
      return value;
    }
  }

  /// Formats relative time matching web time_ago() in functions.php:
  /// < 60s: 'just now'
  /// < 1h:  'X min ago'
  /// < 24h: 'X hr ago'
  /// < 7d:  'X days ago'
  /// >= 7d: '10 Nov 2026'
  static String timeAgo(String? value, {String fallback = '—'}) {
    if (value == null || value.trim().isEmpty) return fallback;
    try {
      final parsed = parseUtc(value);
      if (parsed == null) return fallback;
      final nowUtc = DateTime.now().toUtc();
      final diff = nowUtc.difference(parsed.toUtc());
      final seconds = diff.inSeconds;

      // Handle small clock-skew (-10s to 59s as just now)
      if (seconds >= -10 && seconds < 60) return 'just now';
      if (seconds < -10) return fmtDate(value, fallback: fallback);
      if (seconds < 3600) return '${seconds ~/ 60} min ago';
      if (seconds < 86400) return '${seconds ~/ 3600} hr ago';
      if (seconds < 86400 * 7) return '${seconds ~/ 86400} days ago';
      return fmtDate(value, fallback: fallback);
    } catch (_) {
      return value;
    }
  }

  /// Calculates day difference between two dates.
  /// Positive if d2 is after d1, negative if d2 is before d1.
  static int daysBetween(DateTime d1, DateTime d2) {
    final a = DateTime(d1.year, d1.month, d1.day);
    final b = DateTime(d2.year, d2.month, d2.day);
    return b.difference(a).inDays;
  }
}
