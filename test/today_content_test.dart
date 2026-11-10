import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/theme/app_theme.dart';
import 'package:tudo_aki/core/theme/today_theme.dart';
import 'package:tudo_aki/features/agenda/domain/today_content.dart';
import 'support/today_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TudoAkiDatabase db;
  late TodayRepository repo;
  final now = DateTime(2026, 11, 10, 10, 30);
  setUp(() {
    db = TudoAkiDatabase.memory();
    repo = TodayRepository(db, () => now);
  });
  tearDown(() => db.close());

  test(
    'civil dates partition tasks once without changing persisted data',
    () async {
      final early = await todayTask(
        repo,
        'Hora já passada',
        '2026-11-10T08:00:00',
      );
      final day = await todayTask(repo, 'Dia flexível', '2026-11-10');
      final old = await todayTask(repo, 'Anterior', '2026-11-09T23:59:00');
      await todayTask(repo, 'Futura', '2026-11-11');
      await todayTask(repo, 'Sem data', null);
      final completed = await todayTask(repo, 'Feita hoje', '2026-11-08');
      await repo.taskDone(completed, true);
      final completedYesterday = await todayTask(
        repo,
        'Feita ontem',
        '2026-11-10',
      );
      await repo.taskDone(
        completedYesterday,
        true,
        at: DateTime(2026, 11, 9, 23),
      );
      final before = await todaySnapshot(repo);
      final content = TodayContent(before, now);
      expect(content.pending.map((t) => t['id']), [early, day]);
      expect(content.previous.map((t) => t['id']), [old]);
      expect(content.completedToday.map((t) => t['id']), [completed]);
      expect(content.undatedCount, 1);
      final ids = [
        ...content.pending,
        ...content.previous,
        ...content.completedToday,
      ].map((t) => t['id']).toList();
      expect(ids.toSet().length, ids.length);
      expect(await todaySnapshot(repo), before);
    },
  );

  test(
    'completed UTC instant uses local civil day without rewriting due',
    () async {
      final utc = DateTime(2026, 11, 10, 0, 15).toUtc().toIso8601String();
      final id = await todayTask(repo, 'Instante UTC', utc);
      final content = TodayContent(await todaySnapshot(repo), now);
      expect(content.pending.single['id'], id);
      await repo.taskDone(id, true, at: DateTime.parse(utc));
      expect(
        TodayContent(
          await todaySnapshot(repo),
          now,
        ).completedToday.single['id'],
        id,
      );
      expect((await repo.all('Tasks')).single['due'], utc);
    },
  );

  test(
    'importance and priority precede explicit time, then stable IDs',
    () async {
      final low = await todayTask(
        repo,
        'Baixa',
        '2026-11-10T07:00:00',
        priority: 0,
      );
      final second = await todayTask(repo, 'Hora 12', '2026-11-10T12:00:00');
      final first = await todayTask(repo, 'Hora 11', '2026-11-10T11:00:00');
      final flexible = await todayTask(repo, 'Flexível', '2026-11-10');
      final important = await todayTask(
        repo,
        'Importante',
        '2026-11-10',
        important: 1,
      );
      expect(
        TodayContent(
          await todaySnapshot(repo),
          now,
        ).pending.map((t) => t['id']),
        [important, first, second, flexible, low],
      );
    },
  );

  test(
    'two chronological upcoming blocks include ongoing and academic origins once',
    () async {
      await todayEvent(repo, 'Passado hoje', now, 8);
      await todayEvent(repo, 'Em curso', now, 10);
      await todayEvent(repo, 'Mais tarde', now, 15);
      final subject = await repo.save('Subjects', {'title': 'Matemática'});
      await repo.save('ClassSchedules', {
        'subject_id': subject,
        'weekday': now.weekday,
        'start_minute': 11 * 60,
        'end_minute': 12 * 60,
        'active_from': '2026-01-01',
      });
      await repo.save('Assessments', {
        'subject_id': subject,
        'title': 'Teste final',
        'at': '2026-11-10T13:00:00',
      });
      await repo.save('StudySessions', {
        'subject_id': subject,
        'title': 'Revisão',
        'start': '2026-11-10T14:00:00',
        'minutes': 30,
      });
      await todayTask(repo, 'Tarefa com hora', '2026-11-10T10:45:00');
      final content = TodayContent(await todaySnapshot(repo), now);
      expect(content.upcoming.map((i) => i.row['title']), [
        'Em curso',
        'Aula · Matemática',
      ]);
      expect(content.commitments, hasLength(6));
      expect(
        content.commitments.where((i) => i.row['academic_kind'] == 'Aula'),
        hasLength(1),
      );
      expect(
        content.commitments.where((i) => i.row['academic_kind'] == 'Avaliação'),
        hasLength(1),
      );
      expect(
        content.commitments.where((i) => i.row['academic_kind'] == 'Estudo'),
        hasLength(1),
      );
      expect(await repo.all('CalendarEvents'), hasLength(3));
    },
  );

  test(
    'habits are limited to three active routines for the civil weekday',
    () async {
      for (var i = 0; i < 4; i++) {
        await repo.save('Habits', {
          'title': 'Rotina $i',
          'weekdays': '${now.weekday}',
        });
      }
      await repo.save('Habits', {'title': 'Em pausa', 'paused': 1});
      await repo.save('Habits', {'title': 'Outro dia', 'weekdays': '7'});
      final habits = TodayContent(await todaySnapshot(repo), now).habits;
      expect(habits, hasLength(3));
      expect(
        habits.every((h) => (h['title'] as String).startsWith('Rotina')),
        isTrue,
      );
    },
  );

  test(
    'semantic palette meets text and essential control contrast in both themes',
    () {
      double ratio(Color a, Color b) {
        final x = a.computeLuminance(), y = b.computeLuminance();
        return (math.max(x, y) + .05) / (math.min(x, y) + .05);
      }

      for (final brightness in Brightness.values) {
        final theme = buildTodayTheme(buildTheme(brightness));
        for (final background in [
          theme.scaffoldBackgroundColor,
          theme.colorScheme.surface,
        ]) {
          expect(
            ratio(theme.colorScheme.onSurface, background),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            ratio(theme.colorScheme.onSurfaceVariant, background),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            ratio(theme.colorScheme.secondary, background),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            ratio(theme.colorScheme.outline, background),
            greaterThanOrEqualTo(3),
          );
        }
        expect(
          ratio(theme.colorScheme.onPrimary, theme.colorScheme.primary),
          greaterThanOrEqualTo(4.5),
        );
        expect(theme.colorScheme.primary, TodayColors.sage);
        expect(
          theme.textTheme.headlineLarge!.fontFamily,
          startsWith('Newsreader'),
        );
        expect(theme.floatingActionButtonTheme.elevation, 0);
      }
    },
  );
}
