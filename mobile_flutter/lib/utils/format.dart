import 'package:intl/intl.dart';

import '../l10n/language_controller.dart';

// DateFormat falls back to intl's globally-set default locale (not the app's chosen
// display language) unless a locale is passed explicitly, so every call here is pinned
// to AppLanguage.currentCode - otherwise weekday/month names could mismatch the rest of
// a Turkish UI whenever the device's own locale differs from the in-app selection.
String formatDateTime(String iso) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null || iso.isEmpty) return iso;
  return DateFormat('d MMM y, HH:mm', AppLanguage.currentCode).format(parsed.toLocal());
}

String formatDate(String iso) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null || iso.isEmpty) return iso;
  return DateFormat('EEEE d MMM', AppLanguage.currentCode).format(parsed.toLocal());
}

bool isToday(String iso) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return false;
  final now = DateTime.now();
  final local = parsed.toLocal();
  return local.year == now.year && local.month == now.month && local.day == now.day;
}

String formatMonth(DateTime date) => DateFormat('MMMM y', AppLanguage.currentCode).format(date);

String formatConfidence(double value) => '${(value * 100).round()}%';

String checkLabel(String state) {
  final tr = AppLanguage.currentCode == 'tr';
  switch (state) {
    case 'pass':
      return tr ? 'Sorun yok' : 'Clear';
    case 'fail':
      return tr ? 'Bulgu' : 'Finding';
    case 'unknown':
      return tr ? 'Bilinmiyor' : 'Unknown';
    default:
      return state;
  }
}
