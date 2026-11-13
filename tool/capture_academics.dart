// Diagnostic render utility, not golden tests or physical Android validation.
// Run: flutter test --no-pub tool/capture_academics.dart --reporter expanded
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/widgets/workspace_page.dart';
import 'package:tudo_aki/features/agenda/presentation/today_screen.dart';
import 'package:tudo_aki/features/forms.dart';
import 'package:tudo_aki/features/academics/focus_timer.dart';
import 'package:tudo_aki/features/academics/study_repository.dart';
import 'package:tudo_aki/features/finance/finance_providers.dart';
import 'package:tudo_aki/features/progress/progress_panel.dart';
import 'package:tudo_aki/features/planning/domain/planning_view.dart';
import 'package:tudo_aki/features/tasks/presentation/quick_task_sheet.dart';
import '../test/support/planning_fixture.dart';
import '../test/support/today_fixture.dart';

class _QualityRepository extends PlanningRepository {
  _QualityRepository(super.db, super.clock);
  Completer<void>? gate;
  @override
  Future<List<DataRowMap>> all(String table) async {
    if (table == 'Tasks' && gate != null) await gate!.future;
    return super.all(table);
  }
}

const _scenarios = [
  'academics-empty',
  'academics-empty-320',
  'academics-empty-360',
  'academics-empty-200',
  'academics-empty-320-200',
  'academics-empty-360-200',
  'academics-subjects',
  'academics-subjects-320',
  'academics-subjects-360',
  'academics-subjects-200',
  'academics-subjects-320-200',
  'academics-subjects-360-200',
  'academics-activities',
  'academics-activities-320',
  'academics-activities-360',
  'academics-activities-200',
  'academics-activities-320-200',
  'academics-activities-360-200',
  'academics-active',
  'academics-active-320',
  'academics-active-360',
  'academics-active-200',
  'academics-active-320-200',
  'academics-active-360-200',
  'academics-subject-detail',
  'academics-subject-detail-320',
  'academics-subject-detail-360',
  'academics-subject-detail-200',
  'academics-subject-detail-320-200',
  'academics-subject-detail-360-200',
  'academics-work',
  'academics-work-320',
  'academics-work-360',
  'academics-work-200',
  'academics-work-320-200',
  'academics-work-360-200',
  'academics-focus',
  'academics-focus-320',
  'academics-focus-360',
  'academics-focus-200',
  'academics-focus-320-200',
  'academics-focus-360-200',
  'hoje-filled',
  'plan-tomorrow',
  'goals',
  'tasks',
  'finance',
  'progress',
  'habits',
  'calendar',
];

Future<void> _seed(_QualityRepository repo, DateTime now) async {
  final goal = await repo.save('Goals', {
    'title': 'Ler por prazer',
    'target': 12,
    'current': 3,
    'unit': 'livros',
    'created': now.toIso8601String(),
  });
  final subject = await repo.save('Subjects', {'title': 'Matemática'});
  final task = await todayTask(repo, 'Preparar a apresentação', dayKey(now));
  await repo.save('Tasks', {'goal_id': goal, 'subject_id': subject}, id: task);
  await todayTask(repo, 'Passar na farmácia', dayKey(now));
  await todayTask(repo, 'Rever as notas', '2026-11-10');
  await todayTask(repo, 'Ler um capítulo', '2026-11-12');
  await todayTask(repo, 'Organizar fotografias', null);
  final done = await todayTask(repo, 'Guardar uma ideia', dayKey(now));
  await repo.taskDone(done, true);
  await todayEvent(repo, 'Consulta de rotina', now, 11);
  await todayEvent(repo, 'Reunião da equipa', DateTime(2026, 11, 9), 9);
  await repo.save('Habits', {
    'title': 'Dar uma caminhada',
    'cue': 'Depois do almoço',
  });
  await repo.save('Habits', {
    'title': 'Ler por prazer',
    'cue': 'Antes de dormir',
  });
  await repo.save('StudySessions', {
    'title': 'Revisão da matéria',
    'subject_id': subject,
    'start': now.toIso8601String(),
    'minutes': 25,
  });
  await repo.save('FinancialTransactions', {
    'title': 'Compras do dia',
    'kind': 'expense',
    'amount_cents': 125000,
    'category': 'Alimentação',
    'day': dayKey(now),
    'currency': 'MZN',
  });
  await repo.save('PeriodicReviews', {
    'period': 'Semanal',
    'day': dayKey(now),
    'achieved': 'Terminei uma leitura',
    'pending': 'Organizar notas',
    'obstacles': 'Pouco tempo',
    'next': 'Reservar um momento',
  });
}

void main() {
  for (final dark in [false, true]) {
    for (final scenario in _scenarios) {
      final name = '$scenario-${dark ? 'dark' : 'light'}';
      testWidgets('academics Flutter capture $name', (tester) async {
        final scaled = scenario.endsWith('-200');
        final baseScenario = scenario.replaceFirst(
          RegExp(r'-(320|360)(-200)?$|-200$'),
          '',
        );
        tester.view.physicalSize = Size(
          scenario.contains('-320')
              ? 320
              : scenario.contains('-360')
              ? 360
              : 390,
          scenario.contains('-320')
              ? 640
              : scenario.contains('-360')
              ? 800
              : 844,
        );
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        tester.platformDispatcher.textScaleFactorTestValue = scaled ? 2 : 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final db = TudoAkiDatabase.memory();
        addTearDown(db.close);
        final now = DateTime(2026, 11, 11, 10, 30);
        final repo = _QualityRepository(db, () => now);
        await repo.save('UserPreferences', {
          'theme': dark ? 'dark' : 'light',
        }, id: 1);
        if (baseScenario.startsWith('academics-')) {
          if (baseScenario != 'academics-empty') {
            final subject = await repo.save('Subjects', {
              'title': 'Matemática',
            });
            await repo.save('Subjects', {'title': 'História da arte'});
            if (baseScenario != 'academics-subjects') {
              await repo.save('Tasks', {
                'title': 'Preparar a apresentação de geometria',
                'subject_id': subject,
                'due': '2026-11-12',
                'created': '2026-11-01',
              });
              await repo.save('Tasks', {
                'title': 'Organizar apontamentos',
                'subject_id': subject,
                'created': '2026-11-01',
              });
              await repo.save('Assessments', {
                'title': 'Teste de álgebra',
                'kind': 'Teste',
                'subject_id': subject,
                'at': '2026-11-11T14:00:00',
                'minutes': 60,
              });
              await repo.save('ClassSchedules', {
                'subject_id': subject,
                'weekday': now.weekday,
                'start_minute': 540,
                'end_minute': 600,
                'active_from': '2026-11-01',
                'location': 'Sala 12',
              });
              final session = await repo.saveStudy(
                title: 'Revisão de álgebra',
                subjectId: subject,
                start: DateTime(2026, 11, 11, 16),
                minutes: 25,
              );
              if ([
                'academics-active',
                'academics-focus',
              ].contains(baseScenario)) {
                await repo.startStudy(
                  session,
                  now: now.subtract(const Duration(minutes: 5)),
                );
              }
            }
          }
        } else if (![
          'hoje-empty',
          'loading',
          'read-error',
        ].contains(scenario)) {
          await _seed(repo, now);
        }
        repo.failRead = scenario == 'read-error';
        if (scenario == 'loading') repo.gate = Completer<void>();
        await initializeDateFormatting('pt');
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await tester.runAsync(icons.load);
        const capture = ValueKey('quality-capture');
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              repositoryProvider.overrideWithValue(repo),
              remindersProvider.overrideWithValue(PlanningReminders()),
              workspaceClockProvider.overrideWithValue(() => now),
              financeClockProvider.overrideWithValue(() => now),
              studyClockProvider.overrideWithValue(() => now),
              progressClockProvider.overrideWithValue(() => now),
            ],
            child: const RepaintBoundary(key: capture, child: TudoAkiApp()),
          ),
        );
        await tester.runAsync(() => GoogleFonts.pendingFonts());
        if (scenario == 'loading') {
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        } else {
          await tester.pumpAndSettle();
        }
        final router = GoRouter.of(tester.element(find.byType(TudoAkiShell)));
        if (baseScenario.startsWith('plan-')) {
          final mode = {
            'plan-today': PlanningView.today,
            'plan-tomorrow': PlanningView.tomorrow,
            'plan-week': PlanningView.week,
            'plan-undated': PlanningView.undated,
          }[baseScenario]!;
          router.go('/plan', extra: PlanningRequest(mode));
          await tester.pumpAndSettle();
        } else if (baseScenario.startsWith('academics-')) {
          router.go('/academics');
          await tester.pumpAndSettle();
          if ([
            'academics-subject-detail',
            'academics-work',
          ].contains(baseScenario)) {
            final subject = find.text('Matemática');
            await tester.ensureVisible(subject);
            await tester.pumpAndSettle();
            await tester.tap(subject);
            await tester.pumpAndSettle();
            if (baseScenario == 'academics-work') {
              final create = find.text('Adicionar trabalho');
              await tester.ensureVisible(create);
              await tester.pumpAndSettle();
              await tester.tap(create);
              await tester.pumpAndSettle();
              if (scaled) {
                tester.view.viewInsets = const FakeViewPadding(bottom: 280);
                await tester.pumpAndSettle();
              }
            } else {
              await tester.ensureVisible(subject);
              await tester.pumpAndSettle();
            }
          }
          if (baseScenario == 'academics-focus') {
            if (find.byType(FocusTimerCard).evaluate().isEmpty) {
              final resume = find.text('Retomar foco');
              await tester.ensureVisible(resume);
              await tester.tap(resume);
              await tester.pumpAndSettle();
            }
            final pause = find.widgetWithText(FilledButton, 'Pausar');
            await tester.ensureVisible(pause);
            await tester.pumpAndSettle();
            Focus.of(
              tester.element(
                find.descendant(of: pause, matching: find.byType(Text)).first,
              ),
            ).requestFocus();
            await tester.pumpAndSettle();
          }
        } else if (scenario.startsWith('quick')) {
          showQuickTaskSheet(
            tester.element(find.byType(TodayScreen)),
            initialDate: now,
          );
          await tester.pumpAndSettle();
          if (scenario != 'quick-empty') {
            await tester.enterText(
              find.widgetWithText(TextFormField, 'Título'),
              scaled
                  ? 'Preparar uma apresentação com um título extenso'
                  : 'Uma pequena acção',
            );
          }
          if (scaled) {
            tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          }
          await tester.pumpAndSettle();
          expect(find.byType(QuickTaskSheet), findsOneWidget);
        } else if (baseScenario == 'editor') {
          final row = (await repo.all(
            'Tasks',
          )).firstWhere((r) => r['title'] == 'Preparar a apresentação');
          showEditor(
            tester.element(find.byType(TodayScreen)),
            'Tarefa',
            existing: row,
          );
          await tester.pumpAndSettle();
          expect(find.byType(Editor), findsOneWidget);
        } else {
          final route = {
            'goals': '/goals',
            'goals-create': '/goals',
            'more': '/areas',
            'more-200': '/areas',
            'tasks': '/tasks',
            'habits': '/habits',
            'academics': '/academics',
            'finance': '/finance',
            'reviews': '/reviews',
            'settings': '/profile',
            'progress': '/progress',
            'calendar': '/calendar',
          }[scenario];
          if (route != null) {
            router.go(route);
            await tester.pumpAndSettle();
            if (scenario == 'goals-create') {
              if (const bool.fromEnvironment('QUALITY_GOAL_SELECTOR')) {
                showWorkspaceCreateSheet(
                  tester.element(find.byType(TudoAkiShell)),
                );
              } else {
                await tester.tap(find.byType(FloatingActionButton));
              }
              await tester.pumpAndSettle();
            }
          }
        }
        if (const bool.fromEnvironment('QUALITY_SCROLL_HABITS') &&
            baseScenario == 'hoje-filled') {
          final habits = find.widgetWithText(TextButton, 'Ver hábitos');
          await tester.scrollUntilVisible(
            habits,
            250,
            scrollable: find
                .descendant(
                  of: find.byType(TodayScreen),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.ensureVisible(habits);
          await tester.pumpAndSettle();
          expect(habits.hitTestable(), findsOneWidget);
        }
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(capture),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          final folder = Directory(
            const String.fromEnvironment(
              'QUALITY_OUTPUT',
              defaultValue: 'docs/ux/previews/phase4c3c/before',
            ),
          )..createSync(recursive: true);
          await File(
            '${folder.path}/$name.png',
          ).writeAsBytes(bytes.buffer.asUint8List());
          image.dispose();
        });
        expect(tester.takeException(), isNull);
        // Check that the actions below the captured first viewport remain
        // reachable by scrolling, without changing the screenshot itself.
        if (scaled && baseScenario == 'editor') {
          final save = find.widgetWithText(FilledButton, 'Guardar');
          await tester.ensureVisible(save);
          await tester.pumpAndSettle();
          expect(save.hitTestable(), findsOneWidget);
        }
        if (scaled && baseScenario == 'hoje-filled') {
          final habits = find.widgetWithText(TextButton, 'Ver hábitos');
          await tester.scrollUntilVisible(
            habits,
            400,
            scrollable: find
                .descendant(
                  of: find.byType(TodayScreen),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.pumpAndSettle();
          expect(habits.hitTestable(), findsOneWidget);
        }
        if (scaled && scenario.startsWith('quick')) {
          final another = find.widgetWithText(
            TextButton,
            'Guardar e adicionar outra',
          );
          await tester.ensureVisible(another);
          await tester.pumpAndSettle();
          expect(another.hitTestable(), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        if (repo.gate != null) {
          repo.gate!.complete();
          await tester.pumpAndSettle();
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    }
  }
}
