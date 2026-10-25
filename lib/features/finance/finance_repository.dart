import 'package:drift/drift.dart';
import '../../core/database/database.dart';
import 'finance_rules.dart';

class RecurringPreview {
  RecurringPreview({
    required this.ruleId,
    required this.revision,
    required this.title,
    required this.amountCents,
    required this.kind,
    required this.category,
    required this.through,
    this.currency = 'MZN',
    required List<String> days,
  }) : days = List.unmodifiable(days);
  final int ruleId, revision, amountCents;
  final String title, kind, category, through, currency;
  final List<String> days;
}

extension FinanceRepository on TudoAkiRepository {
  Future<int> saveBudget({
    int? id,
    required String month,
    required String category,
    required int limitCents,
    String? currency,
  }) => db.transaction(() async {
    if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(month) ||
        categoryKey(category).isEmpty ||
        limitCents <= 0) {
      throw const FormatException(
        'Defina mês, categoria e um limite positivo.',
      );
    }
    currency ??= id == null
        ? (await all('UserPreferences')).single['currency'] as String
        : rowCurrency(
            (await all('Budgets')).singleWhere((row) => row['id'] == id),
          );
    if (!currencyLabels.containsKey(currency)) {
      throw const FormatException('Moeda inválida.');
    }
    final duplicate = await query(
      'SELECT id FROM Budgets WHERE month=? AND category_key=? AND currency=?',
      [
        Variable.withString(month),
        Variable.withString(categoryKey(category)),
        Variable.withString(currency!),
      ],
    );
    if (duplicate.any((row) => row['id'] != id)) {
      throw const FormatException(
        'Já existe um orçamento para esta categoria neste mês.',
      );
    }
    return save('Budgets', {
      'month': month,
      'category': cleanCategory(category),
      'category_key': categoryKey(category),
      'limit_cents': limitCents,
      'currency': currency,
    }, id: id);
  });

  Future<int> saveRecurring({
    int? id,
    required String title,
    required int amountCents,
    required String kind,
    required String category,
    required String frequency,
    required DateTime start,
    DateTime? end,
    bool active = true,
    String? currency,
  }) => db.transaction(() async {
    if (title.trim().isEmpty ||
        amountCents <= 0 ||
        !['income', 'expense'].contains(kind) ||
        !frequencyLabels.containsKey(frequency) ||
        categoryKey(category).isEmpty) {
      throw const FormatException('Preencha os dados da recorrência.');
    }
    if (start.year < 2000 ||
        start.year > 2100 ||
        end != null &&
            (end.year > 2100 || dayKey(end).compareTo(dayKey(start)) < 0)) {
      throw const FormatException('Use datas válidas entre 2000 e 2100.');
    }
    currency ??= id == null
        ? (await all('UserPreferences')).single['currency'] as String
        : rowCurrency(
            (await all(
              'RecurringTransactions',
            )).singleWhere((row) => row['id'] == id),
          );
    if (!currencyLabels.containsKey(currency)) {
      throw const FormatException('Moeda inválida.');
    }
    var revision = 1;
    if (id != null) {
      final old = (await query(
        'SELECT * FROM RecurringTransactions WHERE id=?',
        [Variable.withInt(id)],
      )).single;
      final posted = await query(
        'SELECT id FROM RecurringOccurrences WHERE rule_id=? LIMIT 1',
        [Variable.withInt(id)],
      );
      if (posted.isNotEmpty &&
          (old['start_day'] != dayKey(start) ||
              old['frequency'] != frequency)) {
        throw const FormatException(
          'Este calendário já tem registos. Encerre a regra e crie outra para mudar os vencimentos.',
        );
      }
      revision = (old['revision'] as int) + 1;
    }
    return save('RecurringTransactions', {
      'title': title.trim(),
      'amount_cents': amountCents,
      'kind': kind,
      'category': cleanCategory(category),
      'frequency': frequency,
      'start_day': dayKey(start),
      'end_day': end == null ? null : dayKey(end),
      'active': active ? 1 : 0,
      'revision': revision,
      'currency': currency,
    }, id: id);
  });

  Future<RecurringPreview> previewRecurring(int id, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final rows = await query('SELECT * FROM RecurringTransactions WHERE id=?', [
      Variable.withInt(id),
    ]);
    if (rows.isEmpty) throw const FormatException('Esta regra já não existe.');
    final rule = rows.single;
    final posted = (await query(
      'SELECT day FROM RecurringOccurrences WHERE rule_id=?',
      [Variable.withInt(id)],
    )).map((row) => row['day']).toSet();
    final dates = recurringDays(
      rule,
      at,
    ).where((day) => !posted.contains(day)).take(recurringBatchLimit).toList();
    return RecurringPreview(
      ruleId: id,
      revision: rule['revision'] as int,
      title: rule['title'] as String,
      amountCents: rule['amount_cents'] as int,
      kind: rule['kind'] as String,
      category: rule['category'] as String,
      through: dayKey(at),
      currency: rowCurrency(rule),
      days: dates,
    );
  }

  Future<int> recordRecurring(RecurringPreview preview, {DateTime? now}) =>
      db.transaction(() async {
        final at = now ?? DateTime.now();
        if (preview.days.length > recurringBatchLimit ||
            preview.through.compareTo(dayKey(at)) > 0) {
          throw const FormatException(
            'Reveja os movimentos vencidos até hoje.',
          );
        }
        final rows = await query(
          'SELECT * FROM RecurringTransactions WHERE id=?',
          [Variable.withInt(preview.ruleId)],
        );
        if (rows.isEmpty || rows.single['revision'] != preview.revision) {
          throw const FormatException(
            'A regra foi alterada. Reveja os vencimentos antes de registar.',
          );
        }
        final rule = rows.single;
        if (rule['active'] != 1) {
          throw const FormatException('Esta regra está em pausa.');
        }
        final allowed = recurringDays(
          rule,
          DateTime.parse(preview.through),
        ).toSet();
        if (preview.days.any((day) => !allowed.contains(day))) {
          throw const FormatException(
            'O movimento não corresponde a um vencimento desta regra.',
          );
        }
        var added = 0;
        for (final day in preview.days) {
          final existing = await query(
            'SELECT id FROM RecurringOccurrences WHERE rule_id=? AND day=?',
            [Variable.withInt(preview.ruleId), Variable.withString(day)],
          );
          if (existing.isNotEmpty) continue;
          final transaction = await save('FinancialTransactions', {
            'title': rule['title'],
            'amount_cents': rule['amount_cents'],
            'currency': rule['currency'],
            'kind': rule['kind'],
            'category': rule['category'],
            'day': day,
            'recurring_id': preview.ruleId,
            'recurring_day': day,
          });
          await save('RecurringOccurrences', {
            'rule_id': preview.ruleId,
            'day': day,
            'transaction_id': transaction,
          });
          added++;
        }
        return added;
      });
}
