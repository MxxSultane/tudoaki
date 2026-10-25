import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show MigrationStrategy;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/database/schema.dart';
import 'package:tudo_aki/features/finance/finance_repository.dart';
import 'package:tudo_aki/features/finance/finance_rules.dart';

void main() {
  test(
    'v4 migration preserves all denominations, IDs, ledger and focus on reopen',
    () async {
      final dir = await Directory.systemTemp.createTemp('tudo-aki-currency-');
      final file = File('${dir.path}/db.sqlite');
      TudoAkiDatabase db = LegacyV4Database(NativeDatabase(file));
      var repo = TudoAkiRepository(db);
      int budget = 0;
      try {
        await repo.save('UserPreferences', {'currency': 'USD'}, id: 1);
        final saving = await repo.save('SavingsGoals', {
          'title': 'Reserva',
          'target_cents': 100000,
        });
        final rule = await repo.save('RecurringTransactions', {
          'title': 'Renda',
          'amount_cents': 10001,
          'kind': 'expense',
          'category': 'Casa',
          'frequency': 'monthly',
          'start_day': '2026-10-01',
        });
        final movement = await repo.save('FinancialTransactions', {
          'title': 'Reserva',
          'amount_cents': 20001,
          'kind': 'saving',
          'savings_id': saving,
          'day': '2026-10-01',
        });
        await repo.save('RecurringOccurrences', {
          'rule_id': rule,
          'day': '2026-10-01',
          'transaction_id': movement,
        });
        budget = await repo.save('Budgets', {
          'month': '2026-10',
          'category': 'Casa',
          'category_key': 'casa',
          'limit_cents': 55555,
        });
        await repo.save('StudySessions', {
          'start': '2026-10-25T09:00:00',
          'minutes': 25,
          'remaining_seconds': 1500,
          'focus_end': '2026-10-25T09:25:00Z',
        });
        await repo.write(
          "INSERT INTO Achievements(code,unlocked_at) VALUES('first_task','2026-10-01T10:00:00')",
        );
      } finally {
        await db.close();
      }
      db = TudoAkiDatabase(NativeDatabase(file));
      repo = TudoAkiRepository(db);
      try {
        expect(
          (await repo.query('PRAGMA user_version')).single.values.single,
          5,
        );
        expect((await repo.all('UserPreferences')).single['currency'], 'USD');
        for (final table in [
          'SavingsGoals',
          'FinancialTransactions',
          'RecurringTransactions',
          'Budgets',
        ]) {
          expect((await repo.all(table)).single['currency'], 'MZN');
        }
        expect((await repo.all('Budgets')).single['id'], budget);
        expect((await repo.all('Budgets')).single['limit_cents'], 55555);
        expect(
          (await repo.all('FinancialTransactions')).single['amount_cents'],
          20001,
        );
        expect(
          (await repo.all('RecurringOccurrences')).single['transaction_id'],
          isNotNull,
        );
        expect(
          (await repo.all('StudySessions')).single['focus_end'],
          '2026-10-25T09:25:00Z',
        );
        expect(await repo.all('Achievements'), hasLength(1));
        expect(await repo.query('PRAGMA foreign_key_check'), isEmpty);
        final exported = jsonDecode(await repo.exportJson());
        expect(exported['schemaVersion'], 5);
        expect(exported['FinancialTransactions'][0]['currency'], 'MZN');
      } finally {
        await db.close();
      }
      db = TudoAkiDatabase(NativeDatabase(file));
      try {
        expect(
          (await TudoAkiRepository(db).all('Budgets')).single['currency'],
          'MZN',
        );
      } finally {
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );

  group('currency integrity', () {
    late TudoAkiDatabase db;
    late TudoAkiRepository repo;
    setUp(() {
      db = TudoAkiDatabase.memory();
      repo = TudoAkiRepository(db);
    });
    tearDown(() => db.close());
    Future<int> movement({String? currency, int? saving}) =>
        repo.save('FinancialTransactions', {
          'title': 'Compras',
          'amount_cents': 10001,
          'kind': saving == null ? 'expense' : 'saving',
          'category': 'Casa',
          'day': '2026-10-25',
          'currency': ?currency,
          'savings_id': ?saving,
        });

    test(
      'new defaults do not relabel old movements and currency is immutable',
      () async {
        final old = await movement();
        await repo.save('UserPreferences', {'currency': 'USD'}, id: 1);
        final fresh = await movement();
        expect(
          (await repo.all('FinancialTransactions')).map((r) => r['currency']),
          ['MZN', 'USD'],
        );
        await repo.save('FinancialTransactions', {'title': 'Editado'}, id: old);
        await expectLater(
          repo.save('FinancialTransactions', {'currency': 'USD'}, id: old),
          throwsA(isA<Exception>()),
        );
        expect(
          (await repo.all(
            'FinancialTransactions',
          )).singleWhere((r) => r['id'] == old)['currency'],
          'MZN',
        );
        expect(
          (await repo.all(
            'FinancialTransactions',
          )).singleWhere((r) => r['id'] == fresh)['amount_cents'],
          10001,
        );
        await expectLater(movement(currency: 'JPY'), throwsA(isA<Exception>()));
        await expectLater(
          repo.save('UserPreferences', {'currency': 'JPY'}, id: 1),
          throwsA(isA<Exception>()),
        );
        expect(money(10001, currency: 'USD'), '100,01 USD');
        expect(money(10001, currency: 'EUR'), '100,01 EUR');
        expect(money(10001, currency: 'ZAR'), '100,01 ZAR');
        await repo.erase();
        expect((await repo.all('UserPreferences')).single['currency'], 'MZN');
      },
    );

    test(
      'budgets have independent unique categories and spending per currency',
      () async {
        final mzn = await repo.saveBudget(
          month: '2026-10',
          category: 'Casa',
          limitCents: 50000,
        );
        await repo.saveBudget(
          month: '2026-10',
          category: 'CASA',
          limitCents: 20000,
          currency: 'USD',
        );
        await expectLater(
          repo.saveBudget(
            month: '2026-10',
            category: ' casa ',
            limitCents: 30000,
            currency: 'USD',
          ),
          throwsFormatException,
        );
        await movement(currency: 'MZN');
        await movement(currency: 'USD');
        final budgets = await repo.all('Budgets');
        for (final b in budgets) {
          expect(
            budgetSpent(b, await repo.all('FinancialTransactions')),
            BigInt.from(10001),
          );
        }
        await expectLater(
          repo.saveBudget(
            id: mzn,
            month: '2026-10',
            category: 'Outra',
            limitCents: 50000,
            currency: 'EUR',
          ),
          throwsA(isA<Exception>()),
        );
        expect((await repo.all('Budgets')).first['category'], 'Casa');
      },
    );

    test(
      'saving contributions reject mismatched currencies on insert and edit',
      () async {
        final goal = await repo.save('SavingsGoals', {
          'title': 'Viagem',
          'target_cents': 20000,
          'currency': 'EUR',
        });
        await expectLater(
          movement(currency: 'USD', saving: goal),
          throwsA(isA<Exception>()),
        );
        final contribution = await movement(currency: 'EUR', saving: goal);
        final other = await repo.save('SavingsGoals', {
          'title': 'Outra',
          'target_cents': 20000,
        });
        await expectLater(
          repo.save('FinancialTransactions', {
            'savings_id': other,
          }, id: contribution),
          throwsA(isA<Exception>()),
        );
        await expectLater(
          repo.save('SavingsGoals', {'currency': 'USD'}, id: goal),
          throwsA(isA<Exception>()),
        );
        await repo.delete('SavingsGoals', goal);
        expect(
          (await repo.all('FinancialTransactions')).single['currency'],
          'EUR',
        );
        expect(
          (await repo.all('FinancialTransactions')).single['savings_id'],
          isNull,
        );
      },
    );

    test(
      'recurrence keeps its currency after preference changes and repeated confirmation',
      () async {
        final rule = await repo.saveRecurring(
          title: 'Renda',
          amountCents: 10001,
          kind: 'expense',
          category: 'Casa',
          frequency: 'monthly',
          start: DateTime(2026, 10, 1),
          currency: 'ZAR',
        );
        await repo.save('UserPreferences', {'currency': 'USD'}, id: 1);
        final preview = await repo.previewRecurring(
          rule,
          now: DateTime(2026, 10, 25),
        );
        expect(preview.currency, 'ZAR');
        expect(
          await repo.recordRecurring(preview, now: DateTime(2026, 10, 25)),
          1,
        );
        expect(
          await repo.recordRecurring(preview, now: DateTime(2026, 10, 25)),
          0,
        );
        expect(
          (await repo.all('FinancialTransactions')).single['currency'],
          'ZAR',
        );
        await expectLater(
          repo.saveRecurring(
            id: rule,
            title: 'Renda',
            amountCents: 10001,
            kind: 'expense',
            category: 'Casa',
            frequency: 'monthly',
            start: DateTime(2026, 10, 1),
            currency: 'USD',
          ),
          throwsA(isA<Exception>()),
        );
        await repo.delete('RecurringTransactions', rule);
        expect(
          (await repo.all('FinancialTransactions')).single['currency'],
          'ZAR',
        );
      },
    );
  });
}

class LegacyV4Database extends TudoAkiDatabase {
  LegacyV4Database(super.executor);
  @override
  int get schemaVersion => 4;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {
      for (final sql in [...schemaV1, ...schemaV2, ...schemaV3, ...schemaV4]) {
        await customStatement(sql);
      }
    },
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
