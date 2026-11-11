// Diagnostic render utility, not golden tests or physical Android validation.
// Run: flutter test --no-pub tool/capture_quality.dart --reporter expanded
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
  'hoje-empty',
  'hoje-filled',
  'plan-today',
  'plan-tomorrow',
  'plan-week',
  'plan-undated',
  'goals',
  'more',
  'tasks',
  'quick',
  'editor',
  'habits',
  'academics',
  'finance',
  'reviews',
  'settings',
  'progress',
  'calendar',
  'loading',
  'read-error',
  'quick-keyboard-200',
  'more-200',
  'hoje-filled-200',
  'plan-week-200',
  'editor-200',
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
      testWidgets('quality capture $name', (tester) async {
        final scaled = scenario.endsWith('-200');
        final baseScenario = scenario.replaceFirst(RegExp(r'-200$'), '');
        tester.view.physicalSize = Size(scaled ? 360 : 390, scaled ? 800 : 844);
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
        if (!['hoje-empty', 'loading', 'read-error'].contains(scenario)) {
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
        } else if (scenario.startsWith('quick')) {
          showQuickTaskSheet(
            tester.element(find.byType(TodayScreen)),
            initialDate: now,
          );
          await tester.pumpAndSettle();
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Título'),
            scaled
                ? 'Preparar uma apresentação com um título extenso'
                : 'Uma pequena acção',
          );
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
          }
        }
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(capture),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          final folder = Directory('docs/ux/previews/phase3f')
            ..createSync(recursive: true);
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
