import '../../core/database/database.dart';

String cleanCategory(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ');
String categoryKey(String value) => cleanCategory(value).toLowerCase();
String monthKey(DateTime value) => dayKey(value).substring(0, 7);
String moneyInput(int cents) =>
    '${cents ~/ 100},${(cents % 100).toString().padLeft(2, '0')}';

/// Formatting never converts centavos to floating point, including large totals.
String formatMoney(BigInt cents) {
  final digits = cents.abs().toString().padLeft(3, '0');
  final whole = digits.substring(0, digits.length - 2);
  final fraction = digits.substring(digits.length - 2);
  final groups = <String>[];
  for (var end = whole.length; end > 0; end -= 3) {
    groups.insert(0, whole.substring(end < 3 ? 0 : end - 3, end));
  }
  return '${cents.isNegative ? '-' : ''}${groups.join('.')},$fraction MT';
}

String money(int cents) => formatMoney(BigInt.from(cents));

BigInt transactionTotal(
  Iterable<DataRowMap> rows,
  bool Function(DataRowMap) include,
) => rows
    .where(include)
    .fold(
      BigInt.zero,
      (sum, row) => sum + BigInt.from(row['amount_cents'] as int),
    );
BigInt budgetSpent(DataRowMap budget, Iterable<DataRowMap> rows) =>
    transactionTotal(
      rows,
      (row) =>
          row['kind'] == 'expense' &&
          (row['day'] as String).startsWith(budget['month'] as String) &&
          categoryKey(row['category'] as String) == budget['category_key'],
    );

double moneyProgress(BigInt current, int target) =>
    (current.toDouble() / target).clamp(0, 1).toDouble();
const recurringBatchLimit = 24;
const frequencyLabels = {
  'weekly': 'Semanal',
  'monthly': 'Mensal',
  'yearly': 'Anual',
};

/// Always derive an occurrence from its anchor: Jan 31 → Feb 28 → Mar 31.
/// Weekly dates use civil arithmetic, not fixed UTC durations across DST.
List<String> recurringDays(DataRowMap rule, DateTime through) {
  if (rule['active'] != 1) return [];
  final start = DateTime.parse(rule['start_day'] as String);
  var limit = DateTime(through.year, through.month, through.day);
  final end = rule['end_day'] as String?;
  if (end != null && DateTime.parse(end).isBefore(limit)) {
    limit = DateTime.parse(end);
  }
  if (start.isAfter(limit)) return [];
  final days = <String>[];
  for (var index = 0; ; index++) {
    late DateTime next;
    switch (rule['frequency']) {
      case 'weekly':
        next = DateTime(start.year, start.month, start.day + 7 * index);
      case 'monthly':
        final month = DateTime(start.year, start.month + index, 1);
        final last = DateTime(month.year, month.month + 1, 0).day;
        next = DateTime(
          month.year,
          month.month,
          start.day > last ? last : start.day,
        );
      case 'yearly':
        final last = DateTime(start.year + index, start.month + 1, 0).day;
        next = DateTime(
          start.year + index,
          start.month,
          start.day > last ? last : start.day,
        );
      default:
        throw const FormatException('Frequência inválida.');
    }
    if (next.isAfter(limit)) break;
    days.add(dayKey(next));
  }
  return days;
}
