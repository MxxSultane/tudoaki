import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/database/schema.dart';
import 'package:tudo_aki/core/theme/premium_tokens.dart';
import 'package:tudo_aki/core/widgets/premium_components.dart';
import 'package:tudo_aki/core/widgets/workspace_page.dart';
import 'package:tudo_aki/features/areas/presentation/areas_screen.dart';
import 'package:tudo_aki/features/forms.dart';
import 'support/planning_fixture.dart';
import 'package:tudo_aki/features/planning/domain/planning_view.dart';
import 'package:tudo_aki/features/tasks/presentation/task_row.dart';
import 'package:tudo_aki/features/progress/progress_screen.dart';

void size(WidgetTester t, double width, double scale, {double height = 640}) {
  t.view.physicalSize = Size(width, height);
  t.view.devicePixelRatio = 1;
  t.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  addTearDown(t.view.resetViewInsets);
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<Map<String, List<DataRowMap>>> snapshot(TudoAkiRepository repo) async =>
    {for (final table in exportTables) table: await repo.all(table)};
void main() {
  for (final dark in [false, true]) {
    for (final width in [320.0, 360.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'global identity $dark $width $scale: full navigation labels, focus and read-only areas',
          (t) async {
            size(t, width, scale);
            t.platformDispatcher.accessibilityFeaturesTestValue =
                const FakeAccessibilityFeatures(disableAnimations: true);
            addTearDown(
              t.platformDispatcher.clearAccessibilityFeaturesTestValue,
            );
            final db = TudoAkiDatabase.memory();
            addTearDown(db.close);
            final repo = PlanningRepository(
              db,
              () => DateTime(2026, 11, 18, 10),
            );
            await repo.save('UserPreferences', {
              'theme': dark ? 'dark' : 'light',
            }, id: 1);
            await bootPlanning(t, repo, navigate: false);
            final before = await snapshot(repo);
            final nav = find.byType(NavigationBar);
            final label = find.descendant(
              of: nav,
              matching: find.text('Planear'),
            );
            final text = t.widget<Text>(label);
            final effective = MediaQuery.textScalerOf(
              t.element(label),
            ).scale(text.style!.fontSize!);
            expect(
              effective,
              closeTo(13 * scale, .01),
              reason:
                  'Navigation must honour 200%, not Material default 130% clamp',
            );
            expect(
              t.widget<NavigationBar>(nav).animationDuration,
              Duration.zero,
            );
            for (final d in t.widgetList<NavigationDestination>(
              find.byType(NavigationDestination),
            )) {
              final f = find.widgetWithText(NavigationDestination, d.label);
              expect(t.getSize(f).width, greaterThanOrEqualTo(48));
              expect(t.getSize(f).height, greaterThanOrEqualTo(48));
            }
            final destination = find.widgetWithText(
              NavigationDestination,
              'Mais',
            );
            final nativeFocus = find
                .descendant(of: destination, matching: find.byType(Text))
                .first;
            Focus.of(t.element(nativeFocus)).requestFocus();
            await t.pumpAndSettle();
            final focusedRing = find.descendant(
              of: find
                  .ancestor(
                    of: destination,
                    matching: find.byType(PremiumFocusOutline),
                  )
                  .first,
              matching: find.byKey(const ValueKey('premium-focus-ring')),
            );
            final border =
                (t.widget<DecoratedBox>(focusedRing).decoration
                        as BoxDecoration)
                    .border!;
            expect(border.top.color, PremiumTokens(dark).action);
            expect(border.top.width, 2);
            await t.sendKeyEvent(LogicalKeyboardKey.tab);
            await t.pumpAndSettle();
            await tapPlanning(t, destination);
            expect(
              PremiumTokens.active(t.element(find.byType(AreasScreen))),
              isTrue,
            );
            final rows = find.descendant(
              of: find.byType(AreasScreen),
              matching: find.byType(ListTile),
            );
            expect(rows, findsNWidgets(9));
            expect(
              find.descendant(
                of: find.byType(AreasScreen),
                matching: find.byType(PremiumFocusOutline),
              ),
              findsNWidgets(9),
            );
            final router = GoRouter.of(t.element(find.byType(TudoAkiShell)));
            for (final route in [
              '/tasks',
              '/calendar',
              '/habits',
              '/academics',
              '/finance',
              '/progress',
              '/reviews',
              '/profile',
            ]) {
              router.push(route);
              await t.pumpAndSettle();
              final area = find.byType(AreaScaffold);
              final ctx = area.evaluate().isNotEmpty
                  ? t.element(find.byType(Scaffold).last)
                  : t.element(find.byType(WorkspacePage));
              expect(PremiumTokens.active(ctx), isTrue, reason: route);
              expect(t.takeException(), isNull, reason: route);
              router.pop();
              await t.pumpAndSettle();
            }
            expect(await snapshot(repo), before);
            expect(t.takeException(), isNull);
            await t.pumpWidget(const SizedBox.shrink());
          },
        );
      }
    }
    for (final kind in ['Tarefa', 'Evento', 'Hábito']) {
      testWidgets(
        'global editor $kind $dark focus, error, keyboard, cancel without writing',
        (t) async {
          size(t, 320, 2);
          final db = TudoAkiDatabase.memory();
          addTearDown(db.close);
          final repo = PlanningRepository(db, () => DateTime(2026, 11, 18, 10));
          await repo.save('UserPreferences', {
            'theme': dark ? 'dark' : 'light',
          }, id: 1);
          await bootPlanning(t, repo, navigate: false);
          final before = await snapshot(repo);
          showEditor(t.element(find.byType(TudoAkiShell)), kind);
          await t.pumpAndSettle();
          final field = find.widgetWithText(TextFormField, 'Título');
          expect(PremiumTokens.active(t.element(field)), isTrue);
          expect(
            find.ancestor(
              of: field,
              matching: find.byType(PremiumFocusOutline),
            ),
            findsWidgets,
          );
          await tapPlanning(t, find.widgetWithText(FilledButton, 'Guardar'));
          expect(find.text('Preencha este campo'), findsWidgets);
          await t.enterText(field, 'Rascunho $kind');
          t.view.viewInsets = const FakeViewPadding(bottom: 280);
          await t.pumpAndSettle();
          await t.ensureVisible(field);
          await t.pumpAndSettle();
          expect(field.hitTestable(), findsOneWidget);
          expect(t.takeException(), isNull);
          await tapPlanning(t, find.widgetWithText(TextButton, 'Cancelar'));
          expect(find.byType(Editor), findsNothing);
          expect(await snapshot(repo), before);
          await t.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
  testWidgets(
    'shared error remains readable and retry reachable in short landscape at 200%',
    (t) async {
      size(t, 640, 2, height: 170);
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = PlanningRepository(db, () => DateTime(2026, 11, 18))
        ..failRead = true;
      await bootPlanning(t, repo, navigate: false);
      expect(t.takeException(), isNull);
      await t.ensureVisible(find.text('Tentar novamente'));
      await t.pumpAndSettle();
      expect(find.text('Tentar novamente').hitTestable(), findsOneWidget);
      repo.failRead = false;
      await tapPlanning(t, find.text('Tentar novamente'));
      expect(find.text('Não foi possível abrir os dados.'), findsNothing);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'journey E: create and complete task, inspect Progress, switch Line/List, return to origin without XP duplication',
    (t) async {
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = PlanningRepository(db, () => DateTime(2026, 11, 18, 10));
      await bootPlanning(t, repo, navigate: false);
      await tapPlanning(t, find.text('Adicionar tarefa'));
      await t.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Percurso integrado',
      );
      await savePlan(t);
      final task = (await repo.all('Tasks')).single;
      await tapPlanning(
        t,
        find.descendant(
          of: find.byType(TaskRow).first,
          matching: find.byType(Checkbox),
        ),
      );
      expect((await repo.all('Tasks')).single['completed'], 1);
      final completed = await repo.all('Tasks');
      final xp = await repo.all('ExperienceEvents');
      expect(
        xp.where((r) => r['source'] == 'task:${task['id']}'),
        hasLength(1),
      );
      final router = GoRouter.of(t.element(find.byType(TudoAkiShell)));
      router.push('/progress');
      await t.pumpAndSettle();
      expect(find.text('Percurso integrado'), findsOneWidget);
      final explore = find.text('Explorar Percurso');
      await t.scrollUntilVisible(
        explore,
        300,
        scrollable: find
            .descendant(
              of: find.byType(ProgressScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tapPlanning(t, explore);
      expect(find.text('Percurso integrado'), findsWidgets);
      await tapPlanning(t, find.byKey(const ValueKey('journey-view')));
      await tapPlanning(t, find.text('Lista').last);
      expect(find.text('Percurso integrado'), findsWidgets);
      await tapPlanning(t, find.text('Ver tarefas').last);
      expect(find.text('Tarefas'), findsWidgets);
      router.push('/progress');
      await t.pumpAndSettle();
      final allGoals = find.text('Ver todas as metas');
      await t.scrollUntilVisible(
        allGoals,
        300,
        scrollable: find
            .descendant(
              of: find.byType(ProgressScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tapPlanning(t, allGoals);
      expect(
        t.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );
      expect(t.takeException(), isNull);
      expect(await repo.all('ExperienceEvents'), xp);
      expect(await repo.all('Tasks'), completed);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'week at 320/200 retains seven days and reachable create without overflowing below integrated navigation',
    (t) async {
      size(t, 320, 2);
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = PlanningRepository(db, () => DateTime(2026, 11, 18, 10));
      await bootPlanning(t, repo, navigate: false);
      await tapPlanning(
        t,
        find.widgetWithText(NavigationDestination, 'Planear'),
      );
      await planView(t, PlanningView.week);
      expect(t.takeException(), isNull);
      for (var i = 0; i < 7; i++) {
        final day = find.byKey(ValueKey('plan-day-$i'));
        await t.scrollUntilVisible(
          day,
          200,
          scrollable: find
              .descendant(
                of: find.byKey(const ValueKey('weekly-days')),
                matching: find.byType(Scrollable),
              )
              .first,
          maxScrolls: 60,
        );
        expect(day, findsOneWidget);
      }
      await tapPlanning(
        t,
        find.widgetWithText(FilledButton, 'Adicionar tarefa'),
      );
      expect(find.byType(TextFormField), findsWidgets);
      await tapPlanning(t, find.widgetWithText(TextButton, 'Cancelar'));
      expect(await repo.all('Tasks'), isEmpty);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'Planear all tasks uses existing shell destination without duplicated page keys',
    (t) async {
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = PlanningRepository(db, () => DateTime(2026, 11, 18));
      await bootPlanning(t, repo, navigate: false);
      await tapPlanning(
        t,
        find.widgetWithText(NavigationDestination, 'Planear'),
      );
      await tapPlanning(t, find.text('Todas as tarefas'));
      expect(find.text('Tarefas'), findsWidgets);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
}
