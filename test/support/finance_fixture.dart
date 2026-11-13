import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/features/finance/finance_repository.dart';

/// Synthetic denominations, month boundaries, plans and posted history.
Future<void> seedFinance(
  TudoAkiRepository repo, {
  bool longValues = false,
}) async {
  final saving = await repo.save('SavingsGoals', {
    'title': 'Reserva de emergência',
    'target_cents': 5000050,
    'currency': 'MZN',
  });
  for (final row in <DataRowMap>[
    {
      'title': 'Pagamento do trabalho',
      'kind': 'income',
      'amount_cents': 2500050,
      'category': 'Trabalho',
      'day': '2026-11-10',
      'currency': 'MZN',
    },
    {
      'title': 'Compras para a semana',
      'kind': 'expense',
      'amount_cents': 125050,
      'category': 'Alimentação',
      'day': '2026-11-11',
      'currency': 'MZN',
    },
    {
      'title': 'Contribuição de Novembro',
      'kind': 'saving',
      'amount_cents': 100025,
      'category': 'Reserva',
      'day': '2026-11-09',
      'currency': 'MZN',
      'savings_id': saving,
    },
    {
      'title': 'Contribuição anterior',
      'kind': 'saving',
      'amount_cents': 5000,
      'category': 'Reserva',
      'day': '2026-10-31',
      'currency': 'MZN',
      'savings_id': saving,
    },
    {
      'title': 'Despesa anterior',
      'kind': 'expense',
      'amount_cents': 99999,
      'category': 'Alimentação',
      'day': '2026-10-31',
      'currency': 'MZN',
    },
    {
      'title': 'Serviço em dólares',
      'kind': 'income',
      'amount_cents': 155050,
      'category': 'Trabalho',
      'day': '2026-11-10',
      'currency': 'USD',
    },
    {
      'title': 'Compra em dólares',
      'kind': 'expense',
      'amount_cents': 55555,
      'category': 'Alimentação',
      'day': '2026-11-11',
      'currency': 'USD',
    },
    {
      'title': 'Compra em euros',
      'kind': 'expense',
      'amount_cents': 11001,
      'category': 'Casa',
      'day': '2026-11-11',
      'currency': 'EUR',
    },
    {
      'title': 'Compra em rands',
      'kind': 'expense',
      'amount_cents': 12001,
      'category': 'Casa',
      'day': '2026-11-11',
      'currency': 'ZAR',
    },
  ]) {
    await repo.save('FinancialTransactions', row);
  }
  await repo.saveBudget(
    month: '2026-11',
    category: 'Alimentação',
    limitCents: 200000,
    currency: 'MZN',
  );
  final rule = await repo.saveRecurring(
    title: 'Renda mensal',
    amountCents: 50000,
    kind: 'expense',
    category: 'Casa',
    frequency: 'monthly',
    start: DateTime(2026, 10, 1),
    currency: 'MZN',
  );
  await repo.recordRecurring(
    await repo.previewRecurring(rule, now: DateTime(2026, 10, 1)),
    now: DateTime(2026, 10, 1),
  );
  if (longValues) {
    for (var i = 0; i < 3; i++) {
      await repo.save('FinancialTransactions', {
        'title': 'Entrada elevada ${i + 1}',
        'kind': 'income',
        'amount_cents': 9007199254740991,
        'category': 'Trabalho',
        'day': '2026-11-11',
        'currency': 'MZN',
      });
    }
  }
}

Future<Map<String, List<DataRowMap>>> financeSnapshot(
  TudoAkiRepository repo,
) async => {
  for (final table in [
    'FinancialTransactions',
    'SavingsGoals',
    'Budgets',
    'RecurringTransactions',
    'RecurringOccurrences',
    'UserPreferences',
    'ExperienceEvents',
  ])
    table: await repo.all(table),
};
