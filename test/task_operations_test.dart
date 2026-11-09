import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/notifications/reminders.dart';
import 'package:tudo_aki/features/progress/progress_rules.dart';
import 'package:tudo_aki/features/tasks/domain/task_operations.dart';

class TaskReminders extends Reminders {
  final calls = <String>[];
  bool cancelFails = false, scheduleFails = false, allowed = true;
  @override
  Future<void> cancel(int id) async {
    calls.add('cancel:$id');
    if (cancelFails) throw StateError('cancel failed');
  }

  @override
  Future<bool> schedule(int id, String title, DateTime date) async {
    calls.add('schedule:$id:$title:${date.toIso8601String()}');
    if (scheduleFails) throw StateError('schedule failed');
    return allowed;
  }
}

void main() {
  late TudoAkiDatabase db;
  late TudoAkiRepository repo;
  late TaskOperations operations;
  late TaskReminders reminders;
  late int refreshes;
  setUp(() {
    db = TudoAkiDatabase.memory();
    repo = TudoAkiRepository(db);
    reminders = TaskReminders();
    refreshes = 0;
    operations = TaskOperations(repo, reminders, refresh: () => refreshes++);
  });
  tearDown(() => db.close());

  test(
    'create title-only, edit same ID and preserve optional relations',
    () async {
      final goal = await repo.save('Goals', {
        'title': 'Ler',
        'target': 12,
        'created': '2026-11-09T10:00:00',
      });
      final subject = await repo.save('Subjects', {'title': 'História'});
      final saved = await operations.create({'title': 'Capítulo'});
      var task = (await repo.all('Tasks')).single;
      expect(task['due'], isNull);
      expect(task['reminder'], 0);
      expect(task['created'], isA<String>());
      final created = task['created'];
      await operations.edit(saved.id, {
        'goal_id': goal,
        'subject_id': subject,
        'priority': 2,
        'important': 1,
      });
      final edited = await operations.edit(saved.id, {
        'title': 'Rever capítulo',
      });
      task = (await repo.all('Tasks')).single;
      expect(edited.id, saved.id);
      expect(task['goal_id'], goal);
      expect(task['subject_id'], subject);
      expect(task['priority'], 2);
      expect(task['important'], 1);
      expect(task['created'], created);
      expect(task['title'], 'Rever capítulo');
      expect(reminders.calls, isEmpty);
      expect(refreshes, 3);
    },
  );

  test('reschedule never duplicates or converts date precision', () async {
    final result = await operations.create({'title': 'Preparar'});
    for (final due in <String?>[
      '2090-01-02',
      '2090-01-03T00:00:00.000',
      '2090-01-04T10:30:00Z',
      null,
    ]) {
      expect((await operations.reschedule(result.id, due)).id, result.id);
      expect((await repo.all('Tasks')).single['due'], due);
      expect(await repo.all('Tasks'), hasLength(1));
    }
    expect(await repo.all('ExperienceEvents'), isEmpty);
  });

  test(
    'completion and reopening delegate idempotent XP and keep goal metric',
    () async {
      final goal = await repo.save('Goals', {
        'title': 'Ler 12',
        'target': 12,
        'created': '2026-11-09T10:00:00',
      });
      final result = await operations.create({'title': 'Ler', 'goal_id': goal});
      for (final done in [true, false, true]) {
        final task = (await repo.all('Tasks')).single;
        await operations.setCompleted(task, done);
      }
      await repo.syncAchievements();
      expect((await repo.all('Tasks')).single['id'], result.id);
      expect((await repo.all('Tasks')).single['completed'], 1);
      expect((await repo.all('Goals')).single['current'], 0);
      expect((await repo.all('ExperienceEvents')).single['points'], 10);
      expect((await repo.all('Achievements')).single['code'], 'first_task');
      final xp = await repo.all('ExperienceEvents');
      final achievements = await repo.all('Achievements');
      await operations.delete((await repo.all('Tasks')).single);
      expect(await repo.all('ExperienceEvents'), xp);
      expect(await repo.all('Achievements'), achievements);
    },
  );

  test('disabled gamification still completes a task without XP', () async {
    await repo.save('UserPreferences', {'gamification': 0}, id: 1);
    await operations.create({'title': 'Descansar'});
    await operations.setCompleted((await repo.all('Tasks')).single, true);
    expect((await repo.all('Tasks')).single['completed'], 1);
    expect(await repo.all('ExperienceEvents'), isEmpty);
  });

  test(
    'reminder edit uses same ID and exact instant; day-only cancels it',
    () async {
      final result = await operations.create({
        'title': 'Telefonar',
        'due': '2090-01-02T09:00:00.000',
        'reminder': 1,
      });
      reminders.calls.clear();
      await operations.reschedule(result.id, '2090-01-03T11:30:00.000');
      expect(reminders.calls, [
        'cancel:${result.id}',
        'schedule:${result.id}:Telefonar:2090-01-03T11:30:00.000',
      ]);
      reminders.calls.clear();
      await operations.reschedule(result.id, '2090-01-04');
      expect(reminders.calls, ['cancel:${result.id}']);
      expect((await repo.all('Tasks')).single['reminder'], 0);
      expect((await repo.all('Tasks')).single['due'], '2090-01-04');
    },
  );

  test('reminder failures do not roll back saves or prevent refresh', () async {
    reminders.allowed = false;
    final saved = await operations.create({
      'title': 'Consulta',
      'due': '2090-01-02T09:00:00.000',
      'reminder': 1,
    });
    expect(saved.reminderFailure, TaskReminderFailure.unavailable);
    reminders.scheduleFails = true;
    final edited = await operations.edit(saved.id, {
      'title': 'Consulta revista',
    });
    expect(edited.reminderFailure, TaskReminderFailure.failed);
    expect((await repo.all('Tasks')).single['title'], 'Consulta revista');
    expect(refreshes, 2);
  });

  test(
    'completion keeps haptic hook ordering and reminder failure result',
    () async {
      await operations.create({
        'title': 'Consulta',
        'due': '2090-01-02T09:00:00.000',
        'reminder': 1,
      });
      reminders.calls.clear();
      var persisted = false;
      await operations.setCompleted(
        (await repo.all('Tasks')).single,
        true,
        onPersisted: () {
          persisted = true;
          expect(reminders.calls, isEmpty);
        },
      );
      expect(persisted, isTrue);
      expect(reminders.calls.single, startsWith('cancel:'));
      reminders.allowed = false;
      final result = await operations.setCompleted(
        (await repo.all('Tasks')).single,
        false,
      );
      expect(result, TaskReminderFailure.unavailable);
      expect((await repo.all('Tasks')).single['completed'], 0);
      expect((await repo.all('ExperienceEvents')).single['points'], 10);
    },
  );

  test(
    'delete cancels before removal and preserves existing failure ordering',
    () async {
      await operations.create({
        'title': 'Consulta',
        'due': '2090-01-02T09:00:00.000',
        'reminder': 1,
      });
      final task = (await repo.all('Tasks')).single;
      reminders.calls.clear();
      reminders.cancelFails = true;
      await expectLater(operations.delete(task), throwsStateError);
      expect(await repo.all('Tasks'), hasLength(1));
      expect(refreshes, 1);
      reminders.cancelFails = false;
      await operations.delete(task);
      expect(await repo.all('Tasks'), isEmpty);
      expect(refreshes, 2);
      expect(reminders.calls, ['cancel:${task['id']}', 'cancel:${task['id']}']);
    },
  );

  test(
    'SQLite failure does not notify reminders or report a successful refresh',
    () async {
      await expectLater(
        operations.create({'title': 'Inválida', 'goal_id': 999}),
        throwsA(isA<Exception>()),
      );
      expect(await repo.all('Tasks'), isEmpty);
      expect(reminders.calls, isEmpty);
      expect(refreshes, 0);
      await expectLater(
        operations.setCompleted({'id': 999}, true),
        throwsStateError,
      );
      expect(await repo.all('ExperienceEvents'), isEmpty);
    },
  );

  test(
    'provider invalidation exposes changes to existing data consumers',
    () async {
      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          remindersProvider.overrideWithValue(reminders),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(dataProvider, (_, _) {});
      addTearDown(subscription.close);
      expect((await container.read(dataProvider.future))['Tasks'], isEmpty);
      final service = container.read(taskOperationsProvider);
      final saved = await service.create({'title': 'Visível'});
      var data = await container.read(dataProvider.future);
      expect(data['Tasks']!.single['id'], saved.id);
      await service.edit(saved.id, {'title': 'Editada'});
      data = await container.read(dataProvider.future);
      expect(data['Tasks']!.single['title'], 'Editada');
      await service.setCompleted(data['Tasks']!.single, true);
      data = await container.read(dataProvider.future);
      expect(data['Tasks']!.single['completed'], 1);
      expect(data['Achievements']!.single['code'], 'first_task');
      await service.delete(data['Tasks']!.single);
      expect((await container.read(dataProvider.future))['Tasks'], isEmpty);
    },
  );
}
