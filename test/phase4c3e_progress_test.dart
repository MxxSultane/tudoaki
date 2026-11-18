import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/database/schema.dart';
import 'package:tudo_aki/core/theme/app_theme.dart';
import 'package:tudo_aki/core/theme/premium_tokens.dart';
import 'package:tudo_aki/core/widgets/premium_components.dart';
import 'package:tudo_aki/core/widgets/workspace_page.dart';
import 'package:tudo_aki/features/progress/progress_activity.dart';
import 'package:tudo_aki/features/progress/progress_journey.dart';
import 'package:tudo_aki/features/progress/progress_panel.dart';
import 'package:tudo_aki/features/progress/progress_read_provider.dart';
import 'package:tudo_aki/features/progress/progress_rules.dart';
import 'package:tudo_aki/features/progress/progress_screen.dart';
import 'package:tudo_aki/features/goals/presentation/goal_detail.dart';
import 'support/progress_fixture.dart';
import 'support/planning_fixture.dart' show PlanningReminders;

final progressNow = DateTime(2026, 11, 18, 10, 30);
Map<String, List<DataRowMap>> emptyProgress() => {
  for (final t in exportTables) t: <DataRowMap>[],
  'UserPreferences': [
    {'gamification': 1, 'theme': 'light'},
  ],
};

class ProgressSpy extends TudoAkiRepository {
  ProgressSpy(super.db);
  bool forbidWrites = false, fail = false;
  int writes = 0;
  final reads = <String>[];
  Completer<void>? gate;
  @override
  Future<void> write(String sql, [List<Object?> args = const []]) async {
    writes++;
    if (forbidWrites) throw StateError('Unexpected progress write');
    await super.write(sql, args);
  }

  @override
  Future<List<DataRowMap>> all(String table) async {
    reads.add(table);
    if (table == 'Tasks') {
      if (fail) throw StateError('synthetic failure');
      if (gate != null) await gate!.future;
    }
    return super.all(table);
  }
}

Future<Map<String, List<DataRowMap>>> progressSnapshot(
  TudoAkiRepository repo,
) async => {for (final table in exportTables) table: await repo.all(table)};
Future<GoRouter?> bootProgress(
  WidgetTester t,
  ProgressSpy repo, {
  bool app = false,
  bool dark = false,
  bool settle = true,
}) async {
  await initializeDateFormatting('pt');
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        progressClockProvider.overrideWithValue(() => progressNow),
        workspaceClockProvider.overrideWithValue(() => progressNow),
        remindersProvider.overrideWithValue(PlanningReminders()),
      ],
      child: app
          ? const TudoAkiApp()
          : MaterialApp(
              theme: buildTheme(dark ? Brightness.dark : Brightness.light),
              home: const Scaffold(appBar: null, body: ProgressScreen()),
            ),
    ),
  );
  await t.runAsync(() => GoogleFonts.pendingFonts());
  if (settle) {
    await t.pumpAndSettle();
  } else {
    await t.pump(const Duration(milliseconds: 100));
  }
  if (!app) return null;
  final router = GoRouter.of(t.element(find.byType(TudoAkiShell)));
  repo.forbidWrites = true;
  repo.writes = 0;
  repo.reads.clear();
  router.go('/progress');
  await t.pumpAndSettle();
  return router;
}

Future<void> revealProgress(WidgetTester t, Finder finder) async {
  final journey = find.byKey(const PageStorageKey('progress-journey-scroll'));
  final root = journey.evaluate().isNotEmpty
      ? journey
      : find.byKey(const PageStorageKey('progress-overview'));
  final scroll = find
      .descendant(of: root, matching: find.byType(Scrollable))
      .first;
  if (finder.evaluate().isEmpty) {
    t.state<ScrollableState>(scroll).position.jumpTo(0);
    await t.pumpAndSettle();
    for (var i = 0; i < 80 && finder.evaluate().isEmpty; i++) {
      await t.drag(scroll, const Offset(0, -300));
      await t.pumpAndSettle();
    }
  }
  expect(finder, findsOneWidget);
  await t.ensureVisible(finder);
  await t.pumpAndSettle();
}

Future<void> pressProgress(WidgetTester t, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await t.pumpAndSettle();
  await revealProgress(t, finder);
  expect(finder.hitTestable(), findsOneWidget);
  await t.tap(finder);
  await t.pumpAndSettle();
}

Future<void> chooseJourney(WidgetTester t, String field, String label) async {
  await pressProgress(t, find.byKey(ValueKey(field)));
  await pressProgress(t, find.text(label).last);
}

void progressSize(WidgetTester t, double width, double scale) {
  t.view.physicalSize = Size(width, width == 320 ? 640 : 800);
  t.view.devicePixelRatio = 1;
  t.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  test(
    'projection uses one persisted source row, ignores XP duplicates and reopened tasks',
    () async {
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = TudoAkiRepository(db);
      await seedProgress(repo, progressNow);
      final data = await progressSnapshot(repo);
      final before = await progressSnapshot(repo);
      final v = ProgressView(data, progressNow);
      expect(v.history.length, 5);
      expect(v.history.map((e) => e.key).toSet().length, 5);
      expect(v.history.where((e) => e.kind == ProgressKind.task).length, 1);
      expect(v.history.where((e) => e.title == 'Tarefa reaberta'), isEmpty);
      expect(
        v.history.any((e) => e.key.startsWith('ExperienceEvents')),
        isFalse,
      );
      expect(await progressSnapshot(repo), before);
    },
  );
  test('Maputo civil dates, day-only precision and deterministic ordering', () {
    final data = emptyProgress();
    data['Tasks'] = [
      {
        'id': 1,
        'title': 'UTC',
        'completed': 1,
        'completed_at': '2026-11-17T22:30:00Z',
      },
      {
        'id': 2,
        'title': 'Civil',
        'completed': 1,
        'completed_at': '2026-11-18T01:30:00',
      },
    ];
    data['Habits'] = [
      {'id': 1, 'title': 'Leitura'},
    ];
    data['HabitCompletions'] = [
      {'id': 1, 'habit_id': 1, 'day': '2026-11-18'},
    ];
    final v = ProgressView(data, progressNow);
    expect(v.history.map((e) => e.title), ['Civil', 'UTC', 'Leitura']);
    expect(v.history[1].at!.hour, 0);
    expect(v.history.last.dateOnly, isTrue);
    expect(progressStamp(v.history.last), contains('Hora não registada'));
    expect(progressStamp(v.history.last), isNot(contains('00:00')));
  });
  test(
    'missing and invalid dates never borrow creation, due or planned study start',
    () {
      final data = emptyProgress();
      data['Tasks'] = [
        {
          'id': 1,
          'completed': 1,
          'title': 'Sem data',
          'created': '2026-11-18',
          'due': '2026-11-18',
        },
      ];
      data['StudySessions'] = [
        {
          'id': 1,
          'completed': 1,
          'title': 'Sem data',
          'start': '2026-11-18',
          'minutes': 25,
        },
      ];
      data['GoalProgress'] = [
        {'id': 1, 'recorded_at': '2026-02-31', 'value': 3},
      ];
      final v = ProgressView(data, progressNow);
      expect(v.history, isEmpty);
      expect(v.undated.length, 3);
    },
  );
  test(
    'current completed goal is not a fabricated dated achievement event or historical unit',
    () {
      final data = emptyProgress();
      data['Goals'] = [
        {
          'id': 1,
          'title': 'Nome actual',
          'current': 10,
          'target': 10,
          'unit': 'nova unidade',
          'status': 'completed',
          'created': '2026-11-18',
        },
      ];
      expect(ProgressView(data, progressNow).history, isEmpty);
      data['GoalProgress'] = [
        {
          'id': 1,
          'goal_id': 1,
          'value': 3.5,
          'recorded_at': '2026-11-17T10:00:00',
        },
      ];
      final e = ProgressView(data, progressNow).history.single;
      expect(e.detail, 'Valor registado: 3,5');
      expect(e.detail, isNot(contains('nova unidade')));
      expect(e.route, '/goal/1');
    },
  );
  test(
    'unavailable origins keep generic context without invented titles or links',
    () {
      final data = emptyProgress();
      data['GoalProgress'] = [
        {'id': 1, 'goal_id': 99, 'value': 3, 'recorded_at': '2026-11-18'},
      ];
      data['HabitCompletions'] = [
        {'id': 1, 'habit_id': 99, 'day': '2026-11-18'},
      ];
      final v = ProgressView(data, progressNow);
      expect(v.history.every((e) => e.route == null), isTrue);
      expect(
        v.history.map((e) => e.title),
        containsAll(['Meta indisponível', 'Hábito indisponível']),
      );
    },
  );
  test(
    'seven day boundaries preserve existing week rule and future civil day exclusion',
    () {
      final data = emptyProgress();
      data['Tasks'] = [
        for (final day in [11, 12, 18, 19])
          {
            'id': day,
            'title': 'Dia $day',
            'completed': 1,
            'completed_at': '2026-11-${day}T10:00:00',
          },
      ];
      final v = ProgressView(data, progressNow);
      expect(v.history.length, 3);
      expect(v.recent.length, 2);
      expect(v.future.length, 1);
      expect(
        activityWeek(data, progressNow).fold(0, (sum, d) => sum + d.tasks),
        2,
      );
    },
  );
  test('gamification does not change activity, values, status or XP data', () {
    final data = emptyProgress();
    data['Goals'] = [
      {'id': 1, 'current': 12, 'target': 10, 'status': 'active'},
    ];
    data['Tasks'] = [
      {
        'id': 1,
        'title': 'Tarefa',
        'completed': 1,
        'completed_at': '2026-11-18',
      },
    ];
    data['ExperienceEvents'] = [
      {'source': 'task:1', 'points': 10, 'created': '2026-11-18'},
    ];
    final first = ProgressView(data, progressNow);
    data['UserPreferences']!.single['gamification'] = 0;
    final second = ProgressView(data, progressNow);
    expect(second.history.map((e) => e.key), first.history.map((e) => e.key));
    expect(data['Goals']!.single['status'], 'active');
    expect(data['ExperienceEvents']!.length, 1);
    expect(second.gamification, isFalse);
  });
  test(
    'date parsing rejects impossible civil/time values without normalising and preserves offsets',
    () {
      for (final raw in [
        null,
        '',
        'bad',
        '2026-02-31',
        '2026-13-01',
        '2026-11-18T25:00:00',
        '2026-11-18T00:61:00',
      ]) {
        expect(progressDate(raw), isNull);
      }
      expect(progressDate('2026-11-18T00:30:00+02:00')!.hour, 0);
      expect(progressDate('2026-11-17T22:30:00Z')!.day, 18);
      expect(progressNumber(double.infinity), 'Valor não disponível');
    },
  );
  for (final dark in [false, true]) {
    for (final width in [320.0, 360.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'progress $dark ${width}dp ${scale}x hierarchy, contrast roles, focus, targets and reduced motion',
          (t) async {
            progressSize(t, width, scale);
            t.platformDispatcher.accessibilityFeaturesTestValue =
                const FakeAccessibilityFeatures(disableAnimations: true);
            addTearDown(
              t.platformDispatcher.clearAccessibilityFeaturesTestValue,
            );
            final db = TudoAkiDatabase.memory();
            addTearDown(db.close);
            final repo = ProgressSpy(db);
            await seedProgress(repo, progressNow);
            await repo.save('UserPreferences', {
              'theme': dark ? 'dark' : 'light',
            }, id: 1);
            final before = await progressSnapshot(repo);
            await bootProgress(t, repo, app: true, dark: dark);
            expect(find.text('Progresso'), findsOneWidget);
            expect(find.text('Actividade recente'), findsOneWidget);
            expect(find.text('Enviar o projecto'), findsOneWidget);
            expect(find.text('Tarefa reaberta'), findsNothing);
            expect(find.textContaining('XP · Nível'), findsNothing);
            double contentY(Finder f) =>
                t.getTopLeft(f).dy +
                t
                    .state<ScrollableState>(
                      find
                          .descendant(
                            of: find.byKey(
                              const PageStorageKey('progress-overview'),
                            ),
                            matching: find.byType(Scrollable),
                          )
                          .first,
                    )
                    .position
                    .pixels;
            final activityY = contentY(find.text('Actividade recente'));
            await revealProgress(t, find.text('Evolução das metas'));
            final goalsY = contentY(find.text('Evolução das metas'));
            await revealProgress(t, find.text('Hábitos e estudo'));
            final habitsY = contentY(find.text('Hábitos e estudo'));
            expect(activityY, lessThan(goalsY));
            expect(goalsY, lessThan(habitsY));
            final action = find.widgetWithText(TextButton, 'Explorar Percurso');
            final theme = Theme.of(t.element(action));
            expect(
              theme.expansionTileTheme.iconColor,
              PremiumTokens(dark).action,
            );
            expect(
              theme.expansionTileTheme.expansionAnimationStyle!.duration,
              Duration.zero,
            );
            for (final f in [
              action,
              find.widgetWithText(TextButton, 'Em curso'),
              find.widgetWithText(TextButton, 'Alcançadas'),
              find.widgetWithText(TextButton, 'Consultar hábitos'),
            ]) {
              final size = t.getSize(f);
              expect(size.width, greaterThanOrEqualTo(48));
              expect(size.height, greaterThanOrEqualTo(48));
            }
            await revealProgress(t, action);
            await t.pumpAndSettle();
            Focus.of(
              t.element(
                find.descendant(of: action, matching: find.byType(Text)).first,
              ),
            ).requestFocus();
            await t.pumpAndSettle();
            expect(FocusManager.instance.primaryFocus!.hasFocus, isTrue);
            expect(
              theme.textButtonTheme.style!.side!.resolve({
                WidgetState.focused,
              })!.width,
              2,
            );
            await t.sendKeyEvent(LogicalKeyboardKey.tab);
            await t.pumpAndSettle();
            final semantics = t.ensureSemantics();
            await revealProgress(t, action);
            await t.pumpAndSettle();
            expect(t.getSemantics(action).label, contains('Explorar Percurso'));
            semantics.dispose();
            final reads = repo.reads.length;
            await pressProgress(
              t,
              find.widgetWithText(TextButton, 'Alcançadas'),
            );
            expect(find.text('Preparar uma apresentação'), findsOneWidget);
            await pressProgress(t, find.widgetWithText(TextButton, 'Em curso'));
            expect(repo.reads.length, reads);
            expect(repo.writes, 0);
            expect(
              find.descendant(
                of: find.byType(PremiumSurface),
                matching: find.byType(PremiumSurface),
              ),
              findsNothing,
            );
            expect(await progressSnapshot(repo), before);
            expect(t.takeException(), isNull);
            await t.pumpWidget(const SizedBox.shrink());
            await t.pumpAndSettle();
          },
        );
      }
    }
  }
  testWidgets(
    'cold progress is read-only even with pending achievement recognition',
    (t) async {
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = ProgressSpy(db);
      await repo.award('task:missing', 10, '2026-11-18T09:00:00');
      final before = await progressSnapshot(repo);
      repo.forbidWrites = true;
      repo.writes = 0;
      repo.reads.clear();
      await bootProgress(t, repo);
      expect(repo.reads, progressTables);
      expect(repo.writes, 0);
      expect(find.textContaining('Sem registos datados'), findsOneWidget);
      await pressProgress(t, find.text('Histórico e indicadores'));
      expect(find.text('10 XP · Nível 1'), findsOneWidget);
      expect(find.textContaining('Alcançada em'), findsNothing);
      expect(await progressSnapshot(repo), before);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'journey and list expose the same source IDs, filters and data without extra queries or XP',
    (t) async {
      progressSize(t, 320, 2);
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = ProgressSpy(db);
      await seedProgress(repo, progressNow);
      await bootProgress(t, repo, app: true);
      repo.forbidWrites = true;
      repo.writes = 0;
      final reads = repo.reads.length;
      final before = await progressSnapshot(repo);
      final expectedReads = repo.reads.length;
      await pressProgress(t, find.text('Explorar Percurso'));
      final journey = find.byType(ProgressJourney);
      for (final key in ['journey-view', 'journey-period']) {
        final size = t.getSize(find.byKey(ValueKey(key)));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      expect(
        t
            .state<ScrollableState>(
              find
                  .descendant(of: journey, matching: find.byType(Scrollable))
                  .first,
            )
            .position
            .pixels,
        0,
        reason:
            'The viewer opens at its own beginning, not at the underlying page offset.',
      );
      expect(
        find
            .descendant(of: journey, matching: find.text('Enviar o projecto'))
            .hitTestable(),
        findsOneWidget,
        reason:
            'At least the first real activity title must be visible when the viewer opens at 320dp/200%.',
      );
      List<String> ids() => t
          .widgetList<ProgressEntryTile>(
            find.descendant(
              of: journey,
              matching: find.byType(ProgressEntryTile),
            ),
          )
          .map((w) => w.entry.key)
          .toList();
      final expectedIds = t
          .widget<ProgressJourney>(journey)
          .view
          .recent
          .map((e) => e.key)
          .toList();
      await revealProgress(
        t,
        find.descendant(
          of: journey,
          matching: find.byKey(ValueKey('entry-${expectedIds.first}')),
        ),
      );
      final timeline = ids();
      expect(timeline, isNotEmpty);
      await chooseJourney(t, 'journey-view', 'Lista');
      await revealProgress(
        t,
        find.descendant(
          of: journey,
          matching: find.byKey(ValueKey('entry-${expectedIds.first}')),
        ),
      );
      expect(
        t.widget<ProgressJourney>(journey).view.recent.map((e) => e.key),
        expectedIds,
      );
      expect(ids().every(expectedIds.contains), isTrue);
      await chooseJourney(t, 'journey-period', 'Todo o histórico');
      expect(repo.reads.length, expectedReads);
      await chooseJourney(t, 'journey-view', 'Linha do tempo');
      await pressProgress(t, find.byTooltip('Fechar Percurso'));
      expect(repo.writes, 0);
      expect(expectedReads, greaterThan(reads));
      expect(await progressSnapshot(repo), before);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'legacy and disabled gamification keep undated records out of timeline and hide XP only',
    (t) async {
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = ProgressSpy(db);
      await seedProgress(repo, progressNow, legacy: true, disabled: true);
      await bootProgress(t, repo);
      final before = await progressSnapshot(repo);
      repo.forbidWrites = true;
      repo.writes = 0;
      expect(find.text('Enviar o projecto'), findsOneWidget);
      await pressProgress(t, find.text('Registos sem data confirmada (3)'));
      expect(find.text('Data não registada'), findsNWidgets(3));
      expect(find.textContaining('2020'), findsNothing);
      await pressProgress(t, find.text('Histórico e indicadores'));
      expect(find.text('Conquistas'), findsNothing);
      expect(find.textContaining('XP · Nível'), findsNothing);
      expect(find.text('Histórico de XP'), findsNothing);
      expect(await progressSnapshot(repo), before);
      expect(repo.writes, 0);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'real origin routes and reviews return without progress writes or changes to entities',
    (t) async {
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = ProgressSpy(db);
      await seedProgress(repo, progressNow);
      final router = (await bootProgress(t, repo, app: true))!;
      final before = await progressSnapshot(repo);
      repo.writes = 0;
      final goal = (await repo.all('Goals')).first;
      await pressProgress(
        t,
        find.descendant(
          of: find.byType(PremiumSurface).first,
          matching: find.text('Ver meta'),
        ),
      );
      expect(t.widget<GoalDetail>(find.byType(GoalDetail)).id, goal['id']);
      router.pop();
      await t.pumpAndSettle();
      await pressProgress(t, find.text('Fazer uma revisão'));
      expect(find.text('Revisões'), findsOneWidget);
      router.pop();
      await t.pumpAndSettle();
      expect(await progressSnapshot(repo), before);
      expect(repo.writes, 0);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'large journey builds a bounded lazy page rather than all 10000 records',
    (t) async {
      progressSize(t, 390, 1);
      await initializeDateFormatting('pt');
      final data = emptyProgress();
      data['Goals'] = [
        {
          'id': 1,
          'title': 'Leitura',
          'initial': 0,
          'current': 3,
          'target': 12,
          'unit': 'livros',
          'status': 'active',
        },
      ];
      data['GoalProgress'] = [
        for (var i = 0; i < 10000; i++)
          {
            'id': i,
            'goal_id': 1,
            'value': i / 10,
            'recorded_at': DateTime(
              2026,
              11,
              17,
              0,
              i % 1440,
            ).toIso8601String(),
          },
      ];
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            progressReadProvider.overrideWith((_) async => data),
            progressClockProvider.overrideWithValue(() => progressNow),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: const Scaffold(body: ProgressScreen()),
          ),
        ),
      );
      await t.runAsync(() => GoogleFonts.pendingFonts());
      await t.pumpAndSettle();
      await pressProgress(t, find.text('Explorar Percurso'));
      expect(
        t.widgetList<ProgressEntryTile>(find.byType(ProgressEntryTile)).length,
        lessThan(30),
      );
      final sliver = t.widget<SliverList>(
        find.descendant(
          of: find.byType(ProgressJourney),
          matching: find.byType(SliverList),
        ),
      );
      expect(sliver.delegate.estimatedChildCount, 20);
      await pressProgress(t, find.text('Carregar mais registos'));
      final next = t.widget<SliverList>(
        find.descendant(
          of: find.byType(ProgressJourney),
          matching: find.byType(SliverList),
        ),
      );
      expect(next.delegate.estimatedChildCount, 40);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'progress read error is not an empty or zero activity result and supports retry',
    (t) async {
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = ProgressSpy(db)..fail = true;
      await bootProgress(t, repo);
      expect(find.text('Não foi possível abrir o progresso.'), findsOneWidget);
      expect(find.textContaining('Sem registos datados'), findsNothing);
      repo.fail = false;
      await pressProgress(t, find.text('Tentar novamente'));
      expect(find.textContaining('Sem registos datados'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'loading is separate from no activity and completion performs no writes',
    (t) async {
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = ProgressSpy(db)
        ..gate = Completer<void>()
        ..forbidWrites = true;
      await bootProgress(t, repo, settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('Sem registos datados'), findsNothing);
      repo.gate!.complete();
      await t.pumpAndSettle();
      expect(find.textContaining('Sem registos datados'), findsOneWidget);
      expect(repo.writes, 0);
      expect(t.takeException(), isNull);
    },
  );
}
