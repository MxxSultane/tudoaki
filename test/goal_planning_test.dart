import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show MigrationStrategy;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/database/database.dart';
import 'package:lifeos/core/database/schema.dart';
import 'package:lifeos/features/goals/goal_tree.dart';

Future<int> addGoal(LifeRepository repo, String title, {int? parent}) =>
    repo.save('Goals', {
      'title': title,
      'initial': 0,
      'target': 12,
      'current': 0,
      'unit': 'livros',
      'created': '2026-10-24T10:00:00',
      'parent_id': parent,
    });

void main() {
  group('goal planning', () {
    late LifeDatabase db;
    late LifeRepository repo;
    setUp(() {
      db = LifeDatabase.memory();
      repo = LifeRepository(db);
    });
    tearDown(() => db.close());

    test(
      'hierarchy excludes self and descendants and rejects cycles in SQLite',
      () async {
        final year = await addGoal(repo, 'Ano');
        final month = await addGoal(repo, 'Mês', parent: year);
        final week = await addGoal(repo, 'Semana', parent: month);
        final independent = await addGoal(repo, 'Outra meta');
        final goals = await repo.all('Goals');
        expect(availableGoalParents(goals, year).map((g) => g['id']), [
          independent,
        ]);
        expect(availableGoalParents(goals, month).map((g) => g['id']), [
          year,
          independent,
        ]);
        await expectLater(
          repo.save('Goals', {'parent_id': week}, id: year),
          throwsA(isA<Exception>()),
        );
        await expectLater(
          repo.save('Goals', {'parent_id': month}, id: month),
          throwsA(isA<Exception>()),
        );
        expect((await repo.all('Goals')).first['parent_id'], isNull);
        // A valid move between branches is still supported.
        await repo.save('Goals', {'parent_id': independent}, id: month);
        expect(
          (await repo.all(
            'Goals',
          )).firstWhere((g) => g['id'] == month)['parent_id'],
          independent,
        );
      },
    );

    test(
      'deleting a parent preserves child goals, tasks and measured results',
      () async {
        final year = await addGoal(repo, 'Ano');
        final month = await addGoal(repo, 'Mês', parent: year);
        await repo.updateMetric(month, 3);
        await repo.save('Tasks', {
          'title': 'Ler',
          'created': '2026-10-24',
          'goal_id': month,
        });
        await repo.save('GoalMilestones', {
          'title': 'Escolher livros',
          'goal_id': year,
        });
        await repo.delete('Goals', year);
        final child = (await repo.all('Goals')).single;
        expect(child['parent_id'], isNull);
        expect(child['current'], 3);
        expect((await repo.all('Tasks')).single['goal_id'], month);
        expect(await repo.all('GoalMilestones'), isEmpty);
        expect((await repo.query('PRAGMA foreign_key_check')), isEmpty);
      },
    );

    test(
      'milestones can be edited, completed and removed without changing metrics or XP',
      () async {
        final goal = await addGoal(repo, 'Ler');
        final step = await repo.save('GoalMilestones', {
          'goal_id': goal,
          'title': 'Escolher livro',
          'due': '2026-11-01T12:00:00',
        });
        await repo.save('GoalMilestones', {
          'title': 'Escolher primeiro livro',
          'completed': 1,
        }, id: step);
        final milestone = (await repo.all('GoalMilestones')).single;
        expect(milestone['title'], 'Escolher primeiro livro');
        expect(milestone['completed'], 1);
        expect(milestone['due'], '2026-11-01T12:00:00');
        expect((await repo.all('Goals')).single['current'], 0);
        expect(await repo.all('ExperienceEvents'), isEmpty);
        final export =
            jsonDecode(await repo.exportJson()) as Map<String, dynamic>;
        expect(export['schemaVersion'], 2);
        expect((export['GoalMilestones'] as List).single['completed'], 1);
        await repo.delete('GoalMilestones', step);
        expect(await repo.all('GoalMilestones'), isEmpty);
      },
    );
  });

  test(
    'v1 upgrades in place to v2 and reopens with goals and history intact',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'lifeos-v1-migration-',
      );
      final file = File('${directory.path}/lifeos.sqlite');
      final legacy = LegacyDatabase(NativeDatabase(file));
      final old = LifeRepository(legacy);
      final goal = await old.save('Goals', {
        'title': 'Doze livros',
        'target': 12,
        'created': '2026-10-24',
      });
      final step = await old.save('GoalMilestones', {
        'title': 'Uma biblioteca',
        'goal_id': goal,
        'completed': 1,
      });
      final task = await old.save('Tasks', {
        'title': 'Ler',
        'created': '2026-10-24',
        'goal_id': goal,
      });
      await old.taskDone(task, true);
      await old.updateMetric(goal, 2);
      await old.save('UserPreferences', {'theme': 'dark'}, id: 1);
      await legacy.close();
      final current = LifeDatabase(NativeDatabase(file));
      final repo = LifeRepository(current);
      try {
        expect(
          (await repo.query('PRAGMA user_version')).single.values.single,
          2,
        );
        expect((await repo.all('Goals')).single['current'], 2);
        expect((await repo.all('Goals')).single['parent_id'], isNull);
        expect((await repo.all('GoalMilestones')).single['id'], step);
        expect((await repo.all('GoalMilestones')).single['completed'], 1);
        expect((await repo.all('GoalMilestones')).single['due'], isNull);
        expect((await repo.all('Tasks')).single['completed'], 1);
        expect((await repo.all('ExperienceEvents')).single['points'], 10);
        expect((await repo.all('GoalProgress')).single['value'], 2);
        expect((await repo.all('UserPreferences')).single['theme'], 'dark');
        final child = await addGoal(repo, 'Novembro', parent: goal);
        expect(child, greaterThan(goal));
        await repo.save('GoalMilestones', {'due': '2026-11-01'}, id: step);
        expect(await repo.query('PRAGMA foreign_key_check'), isEmpty);
      } finally {
        await current.close();
      }
      final reopened = LifeDatabase(NativeDatabase(file));
      try {
        final data = LifeRepository(reopened);
        expect((await data.all('Goals')).length, 2);
        expect((await data.all('GoalMilestones')).single['due'], '2026-11-01');
      } finally {
        await reopened.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('child horizon defaults follow the annual, monthly, weekly flow', () {
    expect(nextGoalHorizon('Anual'), 'Mensal');
    expect(nextGoalHorizon('Mensal'), 'Semanal');
    expect(nextGoalHorizon(null), 'Anual');
  });
}

class LegacyDatabase extends LifeDatabase {
  LegacyDatabase(super.executor);
  @override
  int get schemaVersion => 1;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {
      for (final statement in schemaV1) {
        await customStatement(statement);
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
