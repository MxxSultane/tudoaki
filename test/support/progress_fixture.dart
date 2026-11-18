import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/features/academics/study_repository.dart';
import 'package:tudo_aki/features/progress/progress_rules.dart';

Future<void> seedProgress(
  TudoAkiRepository repo,
  DateTime now, {
  bool legacy = false,
  bool many = false,
  bool disabled = false,
}) async {
  final goal = await repo.save('Goals', {
    'title': 'Ler por prazer',
    'initial': 0,
    'target': 12,
    'current': 3,
    'unit': 'livros',
    'status': 'active',
    'created': '2026-01-01T09:00:00',
  });
  await repo.save('GoalProgress', {
    'goal_id': goal,
    'value': 3,
    'recorded_at': DateTime(
      now.year,
      now.month,
      now.day - 1,
      14,
    ).toIso8601String(),
  });
  final achieved = await repo.save('Goals', {
    'title': 'Preparar uma apresentação',
    'initial': 0,
    'target': 10,
    'current': 10,
    'unit': 'capítulos',
    'status': 'completed',
    'created': '2026-01-02T09:00:00',
  });
  await repo.save('GoalProgress', {
    'goal_id': achieved,
    'value': 10,
    'recorded_at': DateTime(
      now.year,
      now.month,
      now.day - 3,
      9,
    ).toIso8601String(),
  });
  final task = await repo.save('Tasks', {
    'title': 'Enviar o projecto',
    'due': dayKey(DateTime(now.year, now.month, now.day + 2)),
    'created': '2026-01-01T09:00:00',
  });
  await repo.taskDone(
    task,
    true,
    at: DateTime(now.year, now.month, now.day, 9, 30),
  );
  final reopened = await repo.save('Tasks', {
    'title': 'Tarefa reaberta',
    'created': '2026-01-01T09:00:00',
  });
  await repo.taskDone(
    reopened,
    true,
    at: DateTime(now.year, now.month, now.day - 2, 10),
  );
  await repo.taskDone(reopened, false, at: now);
  final habit = await repo.save('Habits', {'title': 'Ler dez minutos'});
  await repo.toggleHabit(habit, DateTime(now.year, now.month, now.day));
  final study = await repo.saveStudy(
    title: 'Rever a matéria',
    start: DateTime(now.year, now.month, now.day + 3, 15),
    minutes: 1,
  );
  final started = DateTime(now.year, now.month, now.day - 2, 16);
  await repo.startStudy(study, now: started);
  await repo.completeStudy(study, now: started.add(const Duration(minutes: 1)));
  if (legacy) {
    await repo.save('Tasks', {
      'title': 'Tarefa antiga sem data de conclusão',
      'completed': 1,
      'created': '2020-01-01',
      'due': '2020-01-02',
    });
    await repo.save('StudySessions', {
      'title': 'Estudo antigo sem conclusão datada',
      'completed': 1,
      'start': '2020-01-03T10:00:00',
      'minutes': 25,
    });
    await repo.save('GoalProgress', {
      'goal_id': goal,
      'value': 2,
      'recorded_at': 'data desconhecida',
    });
  }
  if (many) {
    await repo.db.transaction(() async {
      for (var i = 0; i < 500; i++) {
        await repo.save('GoalProgress', {
          'goal_id': goal,
          'value': i / 10,
          'recorded_at': DateTime(
            now.year,
            now.month,
            now.day - 1,
            0,
            i,
          ).toIso8601String(),
        });
      }
    });
  }
  await repo.syncAchievements();
  if (disabled) await repo.save('UserPreferences', {'gamification': 0}, id: 1);
}
