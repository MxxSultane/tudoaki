import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudo_aki/core/database/database.dart';

void main() {
  group('repository', () {
    late TudoAkiDatabase db;
    late TudoAkiRepository repo;
    setUp(() {
      db = TudoAkiDatabase.memory();
      repo = TudoAkiRepository(db);
    });
    tearDown(() => db.close());
    Future<int> task({int? goal}) => repo.save('Tasks', {
      'title': 'Ler',
      'created': DateTime(2026, 10, 24).toIso8601String(),
      'goal_id': goal,
    });
    Future<int> goal() => repo.save('Goals', {
      'title': 'Ler 12 livros',
      'initial': 0,
      'target': 12,
      'current': 0,
      'unit': 'livros',
      'created': DateTime(2026).toIso8601String(),
    });

    test('schema v2 creates every entity and defaults', () async {
      expect((await repo.all('UserPreferences')).single['currency'], 'MZN');
      expect((await repo.query('PRAGMA user_version')).single.values.single, 2);
      expect((await repo.query('PRAGMA foreign_keys')).single.values.single, 1);
      expect((await repo.all('Tasks')), isEmpty);
    });
    test('task completion and reopening award XP only once', () async {
      final id = await task();
      await repo.taskDone(id, true);
      await repo.taskDone(id, false);
      await repo.taskDone(id, true);
      expect((await repo.all('ExperienceEvents')).single['points'], 10);
      expect((await repo.all('Tasks')).single['completed'], 1);
    });
    test('unknown tasks cannot create ghost experience', () async {
      await expectLater(repo.taskDone(999, true), throwsStateError);
      expect(await repo.all('ExperienceEvents'), isEmpty);
    });
    test('disabled gamification does not award experience', () async {
      await repo.save('UserPreferences', {'gamification': 0}, id: 1);
      await repo.taskDone(await task(), true);
      expect(await repo.all('ExperienceEvents'), isEmpty);
    });
    test('goal metrics remain independent of completed actions', () async {
      final id = await goal();
      await repo.taskDone(await task(goal: id), true);
      expect((await repo.all('Goals')).single['current'], 0);
      await repo.updateMetric(id, 3);
      expect((await repo.all('Goals')).single['current'], 3);
      expect(goalProgress(0, 12, 3), .25);
      expect((await repo.all('GoalProgress')).single['value'], 3);
      await repo.updateMetric(id, 12);
      expect((await repo.all('Goals')).single['status'], 'completed');
      await repo.updateMetric(id, 8);
      expect((await repo.all('Goals')).single['status'], 'active');
    });
    test('deleting a goal preserves its tasks with a null relation', () async {
      final id = await goal();
      await task(goal: id);
      await repo.delete('Goals', id);
      expect((await repo.all('Tasks')).single['goal_id'], isNull);
    });
    test('habit completions and XP are idempotent per civil day', () async {
      final id = await repo.save('Habits', {'title': 'Caminhar'});
      final date = DateTime(2026, 10, 24);
      await repo.toggleHabit(id, date);
      await repo.toggleHabit(id, date);
      await repo.toggleHabit(id, date);
      expect((await repo.all('HabitCompletions')).length, 1);
      expect((await repo.all('ExperienceEvents')).single['points'], 5);
      await repo.toggleHabit(id, DateTime(2026, 10, 25));
      expect((await repo.all('HabitCompletions')).length, 2);
    });
    test('financial contributions store exact integer cents', () async {
      final id = await repo.save('SavingsGoals', {
        'title': 'Reserva',
        'target_cents': 3000000,
      });
      await repo.save('FinancialTransactions', {
        'title': 'Contribuição',
        'amount_cents': moneyCents('12000,10'),
        'kind': 'saving',
        'day': '2026-10-24',
        'savings_id': id,
      });
      expect(
        (await repo.all('FinancialTransactions')).single['amount_cents'],
        1200010,
      );
      expect(moneyCents('0,1'), 10);
      expect(() => moneyCents('1,001'), throwsFormatException);
      expect(() => moneyCents('-1'), throwsFormatException);
      expect(() => moneyCents('0'), throwsFormatException);
    });
    test('weekly recurrence uses civil date and ignores earlier dates', () {
      final event = {
        'start': '2026-10-24T09:00:00',
        'end': '2026-10-24T10:00:00',
        'recurrence': 'weekly',
      };
      expect(
        occurrenceOn(event, DateTime(2026, 10, 31)),
        DateTime(2026, 10, 31, 9),
      );
      expect(occurrenceOn(event, DateTime(2026, 10, 25)), isNull);
      expect(occurrenceOn(event, DateTime(2026, 10, 17)), isNull);
    });
    test('reset deletes personal data and restores preferences', () async {
      await task();
      await goal();
      await repo.erase();
      expect(await repo.all('Tasks'), isEmpty);
      expect(await repo.all('Goals'), isEmpty);
      expect((await repo.all('UserPreferences')).single['onboarded'], 0);
    });
  });
  test(
    'unknown future database versions are refused without data loss',
    () async {
      final dir = await Directory.systemTemp.createTemp('tudo-aki-migration-');
      final file = File('${dir.path}/db.sqlite');
      final first = TudoAkiDatabase(NativeDatabase(file));
      await TudoAkiRepository(first).save('Habits', {'title': 'Preservar'});
      await first.customStatement('PRAGMA user_version = 3');
      await first.close();
      final future = TudoAkiDatabase(NativeDatabase(file));
      try {
        await expectLater(
          TudoAkiRepository(future).all('Habits'),
          throwsStateError,
        );
      } finally {
        await future.close();
      }
      final compatible = FutureVersionDatabase(NativeDatabase(file));
      try {
        expect(
          (await TudoAkiRepository(compatible).all('Habits')).single['title'],
          'Preservar',
        );
      } finally {
        await compatible.close();
        await dir.delete(recursive: true);
      }
    },
  );
  test('native SQLite data survives closing and reopening', () async {
    final dir = await Directory.systemTemp.createTemp('tudo-aki-test-');
    final file = File('${dir.path}/db.sqlite');
    final first = TudoAkiDatabase(NativeDatabase(file));
    await TudoAkiRepository(first).save('Habits', {'title': 'Ler diariamente'});
    await first.close();
    final second = TudoAkiDatabase(NativeDatabase(file));
    try {
      expect(
        (await TudoAkiRepository(second).all('Habits')).single['title'],
        'Ler diariamente',
      );
    } finally {
      await second.close();
      await dir.delete(recursive: true);
    }
  });
}

// Simulates the version that wrote the file, proving failed downgrade preserves it.
class FutureVersionDatabase extends TudoAkiDatabase {
  FutureVersionDatabase(super.executor);
  @override
  int get schemaVersion => 3;
}
