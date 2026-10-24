import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show MigrationStrategy;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/database/schema.dart';
import 'package:tudo_aki/features/finance/finance_rules.dart';
import 'package:tudo_aki/features/finance/finance_repository.dart';
import 'package:tudo_aki/features/academics/study_repository.dart';

void main() {
  test(
    'centavo formatting and sums are exact beyond native integer aggregate range',
    () {
      expect(money(0), '0,00 MT');
      expect(money(-1), '-0,01 MT');
      expect(money(9007199254740991), '90.071.992.547.409,91 MT');
      final rows = List.generate(
        2000,
        (_) => <String, dynamic>{'amount_cents': 9007199254740991},
      );
      final total = transactionTotal(rows, (_) => true);
      expect(total, BigInt.from(9007199254740991) * BigInt.from(2000));
      expect(formatMoney(total), '180.143.985.094.819.820,00 MT');
      expect(moneyInput(1200010), '12000,10');
    },
  );
  test(
    'amount parsing rejects values that would overflow native centavo multiplication',
    () {
      expect(moneyCents('90071992547409,91'), 9007199254740991);
      expect(() => moneyCents('90071992547409,92'), throwsFormatException);
      expect(() => moneyCents('184467440737095516,17'), throwsFormatException);
      expect(
        () => moneyCents('99999999999999999999999999999,99'),
        throwsFormatException,
      );
    },
  );
  test(
    'recurrence anchors restore month ends and leap days with bounded civil dates',
    () {
      final rule = <String, dynamic>{
        'active': 1,
        'frequency': 'monthly',
        'start_day': '2026-01-31',
        'end_day': null,
      };
      expect(recurringDays(rule, DateTime(2026, 3, 31)), [
        '2026-01-31',
        '2026-02-28',
        '2026-03-31',
      ]);
      expect(
        recurringDays({
          ...rule,
          'frequency': 'yearly',
          'start_day': '2024-02-29',
        }, DateTime(2028, 2, 29)),
        ['2024-02-29', '2025-02-28', '2026-02-28', '2027-02-28', '2028-02-29'],
      );
      expect(
        recurringDays({
          ...rule,
          'frequency': 'weekly',
          'start_day': '2026-10-24',
          'end_day': '2026-11-01',
        }, DateTime(2026, 12)),
        ['2026-10-24', '2026-10-31'],
      );
      expect(
        recurringDays({...rule, 'active': 0}, DateTime(2026, 3, 31)),
        isEmpty,
      );
      expect(recurringDays(rule, DateTime(2025, 12, 31)), isEmpty);
    },
  );
  group('financial planning', () {
    late TudoAkiDatabase db;
    late TudoAkiRepository repo;
    final start = DateTime(2026, 1, 31);
    final now = DateTime(2026, 3, 31);
    setUp(() {
      db = TudoAkiDatabase.memory();
      repo = TudoAkiRepository(db);
    });
    tearDown(() => db.close());
    Future<int> rule({bool active = true}) => repo.saveRecurring(
      title: 'Renda',
      amountCents: 200000,
      kind: 'expense',
      category: 'Casa',
      frequency: 'monthly',
      start: start,
      active: active,
    );
    test(
      'budgets match normalised categories and exclude income, savings and other months',
      () async {
        final id = await repo.saveBudget(
          month: '2026-02',
          category: '  Alimentação ',
          limitCents: 100000,
        );
        for (final row in [
          {
            'kind': 'expense',
            'amount_cents': 50000,
            'category': 'alimentação',
            'day': '2026-02-01',
          },
          {
            'kind': 'expense',
            'amount_cents': 20000,
            'category': 'ALIMENTAÇÃO  ',
            'day': '2026-02-02',
          },
          {
            'kind': 'income',
            'amount_cents': 200000,
            'category': 'Alimentação',
            'day': '2026-02-02',
          },
          {
            'kind': 'saving',
            'amount_cents': 10000,
            'category': 'Alimentação',
            'day': '2026-02-02',
          },
          {
            'kind': 'expense',
            'amount_cents': 999,
            'category': 'Alimentação',
            'day': '2026-03-01',
          },
        ]) {
          await repo.save('FinancialTransactions', {
            'title': 'Movimento',
            ...row,
          });
        }
        final budget = (await repo.all('Budgets')).single;
        expect(
          budgetSpent(budget, await repo.all('FinancialTransactions')),
          BigInt.from(70000),
        );
        await expectLater(
          repo.saveBudget(
            month: '2026-02',
            category: 'ALIMENTAÇÃO',
            limitCents: 1,
          ),
          throwsFormatException,
        );
        await repo.saveBudget(
          id: id,
          month: '2026-02',
          category: 'Alimentação',
          limitCents: 150000,
        );
        expect((await repo.all('Budgets')).single['limit_cents'], 150000);
        await repo.saveBudget(
          month: '2026-03',
          category: 'Alimentação',
          limitCents: 100000,
        );
        expect((await repo.all('Budgets')).length, 2);
      },
    );
    test(
      'preview has no side effects and confirmation is idempotent',
      () async {
        final id = await rule();
        final preview = await repo.previewRecurring(id, now: now);
        expect(preview.days, ['2026-01-31', '2026-02-28', '2026-03-31']);
        expect(await repo.all('FinancialTransactions'), isEmpty);
        expect(await repo.all('RecurringOccurrences'), isEmpty);
        expect(await repo.recordRecurring(preview, now: now), 3);
        expect(await repo.recordRecurring(preview, now: now), 0);
        expect((await repo.all('FinancialTransactions')).length, 3);
        expect((await repo.all('RecurringOccurrences')).length, 3);
        expect(
          (await repo.all(
            'FinancialTransactions',
          )).every((t) => t['recurring_id'] == id),
          isTrue,
        );
        expect(await repo.all('ExperienceEvents'), isEmpty);
      },
    );
    test(
      'deleted movements are not silently recreated and deleting a rule preserves history',
      () async {
        final id = await rule();
        await repo.recordRecurring(
          await repo.previewRecurring(id, now: now),
          now: now,
        );
        final first = (await repo.all('FinancialTransactions')).first;
        await repo.delete('FinancialTransactions', first['id'] as int);
        expect((await repo.previewRecurring(id, now: now)).days, isEmpty);
        expect(
          (await repo.all(
            'RecurringOccurrences',
          )).where((o) => o['transaction_id'] == null).length,
          1,
        );
        await repo.delete('RecurringTransactions', id);
        expect(await repo.all('RecurringOccurrences'), isEmpty);
        final remaining = await repo.all('FinancialTransactions');
        expect(remaining.length, 2);
        expect(
          remaining.every(
            (row) =>
                row['recurring_id'] == null && row['recurring_day'] != null,
          ),
          isTrue,
        );
        expect(await repo.query('PRAGMA foreign_key_check'), isEmpty);
      },
    );
    test(
      'edits invalidate stale previews and affect only new movements',
      () async {
        final id = await rule();
        await repo.recordRecurring(
          await repo.previewRecurring(id, now: now),
          now: now,
        );
        final april = DateTime(2026, 4, 30);
        final stale = await repo.previewRecurring(id, now: april);
        await repo.saveRecurring(
          id: id,
          title: 'Renda actualizada',
          amountCents: 250000,
          kind: 'expense',
          category: 'Casa',
          frequency: 'monthly',
          start: start,
        );
        await expectLater(
          repo.recordRecurring(stale, now: april),
          throwsFormatException,
        );
        final fresh = await repo.previewRecurring(id, now: april);
        expect(fresh.days, ['2026-04-30']);
        expect(await repo.recordRecurring(fresh, now: april), 1);
        final rows = await repo.all('FinancialTransactions');
        expect(rows.where((row) => row['amount_cents'] == 200000).length, 3);
        expect(rows.where((row) => row['amount_cents'] == 250000).length, 1);
        await expectLater(
          repo.saveRecurring(
            id: id,
            title: 'Mudar calendário',
            amountCents: 250000,
            kind: 'expense',
            category: 'Casa',
            frequency: 'weekly',
            start: start,
          ),
          throwsFormatException,
        );
      },
    );
    test('paused rules and future or forged due dates cannot post', () async {
      final id = await rule(active: false);
      expect((await repo.previewRecurring(id, now: now)).days, isEmpty);
      await repo.saveRecurring(
        id: id,
        title: 'Renda',
        amountCents: 200000,
        kind: 'expense',
        category: 'Casa',
        frequency: 'monthly',
        start: start,
      );
      final valid = await repo.previewRecurring(id, now: now);
      RecurringPreview forged(String through, List<String> days) =>
          RecurringPreview(
            ruleId: id,
            revision: valid.revision,
            title: valid.title,
            amountCents: valid.amountCents,
            kind: valid.kind,
            category: valid.category,
            through: through,
            days: days,
          );
      await expectLater(
        repo.recordRecurring(forged('2026-04-30', ['2026-04-30']), now: now),
        throwsFormatException,
      );
      await expectLater(
        repo.recordRecurring(
          forged('2026-03-31', ['2026-01-31', '2026-02-01']),
          now: now,
        ),
        throwsFormatException,
      );
      expect(await repo.all('FinancialTransactions'), isEmpty);
      expect(await repo.all('RecurringOccurrences'), isEmpty);
    });
    test(
      'overdue batches are bounded and repeated reviews advance without duplicates',
      () async {
        final id = await repo.saveRecurring(
          title: 'Transportes',
          amountCents: 1000,
          kind: 'expense',
          category: 'Transporte',
          frequency: 'weekly',
          start: DateTime(2025, 1, 1),
        );
        final one = await repo.previewRecurring(id, now: DateTime(2026, 1, 1));
        expect(one.days.length, 24);
        await repo.recordRecurring(one, now: DateTime(2026, 1, 1));
        final two = await repo.previewRecurring(id, now: DateTime(2026, 1, 1));
        expect(two.days.length, 24);
        expect(one.days.toSet().intersection(two.days.toSet()), isEmpty);
        await repo.recordRecurring(two, now: DateTime(2026, 1, 1));
        expect((await repo.all('FinancialTransactions')).length, 48);
      },
    );
    test(
      'export and erase include financial plans and recurrence ledger',
      () async {
        await repo.saveBudget(
          month: '2026-03',
          category: 'Casa',
          limitCents: 500000,
        );
        final id = await rule();
        await repo.recordRecurring(
          await repo.previewRecurring(id, now: now),
          now: now,
        );
        final exported =
            jsonDecode(await repo.exportJson()) as Map<String, dynamic>;
        expect(exported['schemaVersion'], 4);
        expect((exported['Budgets'] as List).length, 1);
        expect((exported['RecurringOccurrences'] as List).length, 3);
        await repo.erase();
        for (final table in [
          'Budgets',
          'RecurringTransactions',
          'RecurringOccurrences',
          'FinancialTransactions',
        ]) {
          expect(await repo.all(table), isEmpty);
        }
        expect(await repo.query('PRAGMA foreign_key_check'), isEmpty);
      },
    );
  });
  test(
    'v3 migrates to v4 while preserving money, academic planning and running focus',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'tudo-aki-finance-migration-',
      );
      final file = File('${directory.path}/db.sqlite');
      final oldDb = LegacyV3Database(NativeDatabase(file));
      final old = TudoAkiRepository(oldDb);
      final at = DateTime.utc(2026, 10, 24, 10);
      final study = await old.saveStudy(
        title: 'Estudo',
        start: at,
        minutes: 25,
      );
      await old.startStudy(study, now: at);
      await old.save('FinancialTransactions', {
        'title': 'Transporte',
        'amount_cents': 10001,
        'kind': 'expense',
        'category': 'Transporte',
        'day': '2026-10-24',
      });
      await oldDb.close();
      final current = TudoAkiDatabase(NativeDatabase(file));
      final repo = TudoAkiRepository(current);
      try {
        expect(
          (await repo.query('PRAGMA user_version')).single.values.single,
          4,
        );
        final row = (await repo.all('FinancialTransactions')).single;
        expect(row['amount_cents'], 10001);
        expect(row['recurring_id'], isNull);
        expect(row['recurring_day'], isNull);
        expect(
          (await repo.studyById(study))['focus_end'],
          at.add(const Duration(minutes: 25)).toIso8601String(),
        );
        await repo.saveBudget(
          month: '2026-10',
          category: 'Transporte',
          limitCents: 20000,
        );
        expect(
          budgetSpent(
            (await repo.all('Budgets')).single,
            await repo.all('FinancialTransactions'),
          ),
          BigInt.from(10001),
        );
        expect(await repo.query('PRAGMA foreign_key_check'), isEmpty);
      } finally {
        await current.close();
      }
      final reopened = TudoAkiDatabase(NativeDatabase(file));
      try {
        expect(
          (await TudoAkiRepository(
            reopened,
          ).all('Budgets')).single['limit_cents'],
          20000,
        );
      } finally {
        await reopened.close();
        await directory.delete(recursive: true);
      }
    },
  );
}

class LegacyV3Database extends TudoAkiDatabase {
  LegacyV3Database(super.executor);
  @override
  int get schemaVersion => 3;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {
      for (final sql in [...schemaV1, ...schemaV2, ...schemaV3]) {
        await customStatement(sql);
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
