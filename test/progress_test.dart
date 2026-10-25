import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/database/schema.dart';
import 'package:tudo_aki/features/progress/progress_panel.dart';
import 'package:tudo_aki/features/progress/progress_rules.dart';

void main() {
  test(
    'achievements survive reopening, preserve award dates and reset with data',
    () async {
      final dir = await Directory.systemTemp.createTemp('tudo-aki-progress-');
      final file = File('${dir.path}/db.sqlite');
      var db = TudoAkiDatabase(NativeDatabase(file));
      var repo = TudoAkiRepository(db);
      try {
        for (var i = 0; i < 10; i++) {
          await repo.award(
            'task:$i',
            10,
            DateTime(2026, 10, i + 1).toIso8601String(),
          );
        }
        for (var i = 0; i < 7; i++) {
          await repo.award(
            'habit:1:$i',
            5,
            DateTime(2026, 10, i + 1).toIso8601String(),
          );
        }
        for (var i = 0; i < 3; i++) {
          await repo.award(
            'study:2026-10-01:$i',
            15,
            DateTime(2026, 10, 1, i).toUtc().toIso8601String(),
          );
        }
        await repo.syncAchievements();
        final first = await repo.all('Achievements');
        expect(first, hasLength(4));
        expect(
          first.singleWhere((a) => a['code'] == 'ten_tasks')['unlocked_at'],
          '2026-10-10T00:00:00.000',
        );
        await db.close();
        db = TudoAkiDatabase(NativeDatabase(file));
        repo = TudoAkiRepository(db);
        await repo.syncAchievements();
        expect(await repo.all('Achievements'), first);
        expect(await repo.all('ExperienceEvents'), hasLength(20));
        expect(
          jsonDecode(await repo.exportJson())['Achievements'],
          hasLength(4),
        );
        await repo.erase();
        await repo.syncAchievements();
        expect(await repo.all('Achievements'), isEmpty);
      } finally {
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );

  test(
    'disabled gamification delays recognition without deleting history',
    () async {
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = TudoAkiRepository(db);
      await repo.award('task:1', 10, '2026-10-01T12:00:00');
      await repo.save('UserPreferences', {'gamification': 0}, id: 1);
      await repo.syncAchievements();
      expect(await repo.all('Achievements'), isEmpty);
      await repo.save('UserPreferences', {'gamification': 1}, id: 1);
      await repo.syncAchievements();
      expect(await repo.all('Achievements'), hasLength(1));
      await repo.save('UserPreferences', {'gamification': 0}, id: 1);
      await repo.syncAchievements();
      expect(await repo.all('Achievements'), hasLength(1));
    },
  );

  test(
    'week uses civil Maputo boundaries, excludes future and reopened tasks',
    () {
      final data = {for (final table in exportTables) table: <DataRowMap>[]};
      data['Tasks'] = [
        {'completed': 1, 'completed_at': '2026-10-24T22:30:00Z'},
        {'completed': 0, 'completed_at': '2026-10-25T10:00:00'},
        {'completed': 1, 'completed_at': '2026-10-26T10:00:00'},
        {'completed': 1, 'completed_at': '2026-10-18T10:00:00'},
      ];
      data['HabitCompletions'] = [
        {'day': '2026-10-19'},
      ];
      data['StudySessions'] = [
        {'completed': 1, 'completed_at': '2026-10-24T23:00:00Z'},
      ];
      final week = activityWeek(data, DateTime.utc(2026, 10, 24, 23));
      expect(week.first.habits, 1);
      expect(dayKey(week.last.day), '2026-10-25');
      expect(week.last.tasks, 1);
      expect(week.last.studies, 1);
      expect(week.fold(0, (sum, d) => sum + d.tasks), 1);
    },
  );

  testWidgets('chart and achievement labels fit narrow screens at large text', (
    tester,
  ) async {
    await initializeDateFormatting('pt');
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = {for (final table in exportTables) table: <DataRowMap>[]};
    Future<void> render(bool enabled) => tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressClockProvider.overrideWithValue(() => DateTime(2026, 10, 25)),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: ProgressPanel(data: data, gamification: enabled),
              ),
            ),
          ),
        ),
      ),
    );
    await render(true);
    expect(find.text('Primeiro passo'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(7));
    expect(tester.takeException(), isNull);
    await render(false);
    expect(find.text('Conquistas'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(7));
    expect(tester.takeException(), isNull);
  });
}
