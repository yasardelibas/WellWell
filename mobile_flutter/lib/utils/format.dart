import 'package:intl/intl.dart';

String formatDateTime(String iso) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null || iso.isEmpty) return iso;
  return DateFormat('d MMM y, HH:mm').format(parsed.toLocal());
}

String formatDate(String iso) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null || iso.isEmpty) return iso;
  return DateFormat('EEEE d MMM').format(parsed.toLocal());
}

bool isToday(String iso) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return false;
  final now = DateTime.now();
  final local = parsed.toLocal();
  return local.year == now.year && local.month == now.month && local.day == now.day;
}

String formatMonth(DateTime date) => DateFormat('MMMM y').format(date);

String formatConfidence(double value) => '${(value * 100).round()}%';

String checkLabel(String state) {
  switch (state) {
    case 'pass':
      return 'Clear';
    case 'fail':
      return 'Finding';
    case 'unknown':
      return 'Unknown';
    default:
      return state;
  }
}
