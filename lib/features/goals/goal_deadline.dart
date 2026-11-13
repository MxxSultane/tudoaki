import '../../../core/database/database.dart' show dayKey;

/// An input adapter only. Goals.due remains nullable TEXT in SQLite v5.
/// Uses civil calendar arithmetic, not N*24 hours; no rolling countdown stored.
String? goalDeadlineFromDays(String input, DateTime anchor) {
  final value = input.trim();
  if (value.isEmpty) return null;
  final days = RegExp(r'^\d+$').hasMatch(value) ? int.tryParse(value) : null;
  final max = DateTime.utc(
    2100,
    1,
    1,
  ).difference(DateTime.utc(anchor.year, anchor.month, anchor.day)).inDays;
  if (days == null || days < 1) {
    throw const FormatException(
      'Introduz um número inteiro de dias, a partir de 1.',
    );
  }
  if (days > max) {
    throw const FormatException('Escolhe um prazo até 01/01/2100.');
  }
  return dayKey(DateTime.utc(anchor.year, anchor.month, anchor.day + days));
}

/// Match the existing detail's DateTime.parse/DateFormat display semantics.
/// The original string (including zone/time/precision) is never rewritten here.
String goalDeadlineLabel(String? raw) {
  if (raw == null) return 'Sem prazo';
  final date = DateTime.tryParse(raw);
  if (date == null) return raw;
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().padLeft(4, '0')}';
}
