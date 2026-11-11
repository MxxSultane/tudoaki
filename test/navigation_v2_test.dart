import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/features/areas/presentation/areas_screen.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/features/planning/domain/planning_view.dart';
import 'package:tudo_aki/features/planning/presentation/planning_screen.dart';
import 'package:tudo_aki/features/tasks/presentation/quick_task_sheet.dart';
import 'support/planning_fixture.dart';
import 'support/navigation_access.dart';

void main() {
  testWidgets(
    'four tabs retain the same planning state and repeated taps do not reset it',
    (tester) async {
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = PlanningRepository(db, () => DateTime(2026, 11, 10, 10));
      await bootPlanning(tester, repo, navigate: false);
      expect(
        tester
            .widgetList<NavigationDestination>(
              find.byType(NavigationDestination),
            )
            .map((d) => d.label),
        ['Hoje', 'Planear', 'Metas', 'Mais'],
      );
      await tapPlanning(
        tester,
        find.widgetWithText(NavigationDestination, 'Planear'),
      );
      final state = tester.state(find.byType(PlanningScreen));
      await planView(tester, PlanningView.undated);
      for (final tab in ['Metas', 'Mais', 'Hoje', 'Planear', 'Planear']) {
        await tapPlanning(
          tester,
          find.widgetWithText(NavigationDestination, tab),
        );
      }
      expect(
        identical(tester.state(find.byType(PlanningScreen)), state),
        isTrue,
      );
      await tapPlanning(tester, find.text('Adicionar tarefa'));
      expect(find.byType(QuickTaskSheet), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Rascunho conservado',
      );
      expect(find.text('Dia: Sem data'), findsOneWidget);
      await tester.tapAt(
        tester.getCenter(find.widgetWithText(NavigationDestination, 'Hoje')),
      );
      tester
          .widget<NavigationBar>(find.byType(NavigationBar))
          .onDestinationSelected!(0);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Rascunho conservado'), findsOneWidget);
      await tapPlanning(tester, find.widgetWithText(FilledButton, 'Guardar'));
      expect((await repo.all('Tasks')).single['due'], isNull);
      expect(find.text('Rascunho conservado'), findsOneWidget);
      // Android back at a primary non-home destination returns to Hoje.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
    },
  );
  testWidgets(
    'explicit contexts reuse Planear and legacy paths remain functional',
    (tester) async {
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = PlanningRepository(db, () => DateTime(2026, 11, 10, 10));
      await bootPlanning(tester, repo, navigate: false);
      await tapPlanning(
        tester,
        find.widgetWithText(NavigationDestination, 'Planear'),
      );
      final state = tester.state(find.byType(PlanningScreen));
      expect(find.text('Ainda não há tarefas para este dia.'), findsOneWidget);
      await tapPlanning(
        tester,
        find.widgetWithText(NavigationDestination, 'Hoje'),
      );
      await tapPlanning(tester, find.text('Planear amanhã'));
      expect(find.text('Ainda não há tarefas para amanhã.'), findsOneWidget);
      expect(
        identical(tester.state(find.byType(PlanningScreen)), state),
        isTrue,
      );
      await tapPlanning(
        tester,
        find.widgetWithText(NavigationDestination, 'Hoje'),
      );
      await tapPlanning(tester, find.text('Planear semana'));
      expect(find.byKey(const ValueKey('weekly-days')), findsOneWidget);
      await tapPlanning(
        tester,
        find.widgetWithText(NavigationDestination, 'Mais'),
      );
      await tapPlanning(
        tester,
        find.widgetWithText(ListTile, 'Agenda completa'),
      );
      expect(find.byTooltip('Período seguinte'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      await tapPlanning(tester, find.byTooltip('Voltar'));
      expect(find.byType(AreasScreen), findsOneWidget);
      final router = GoRouter.of(tester.element(find.byType(TudoAkiShell)));
      await tapPlanning(tester, find.widgetWithText(ListTile, 'Hábitos'));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AreasScreen), findsOneWidget);
      await openGlobalTasks(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AreasScreen), findsOneWidget);
      router.go('/tasks');
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
      await tapPlanning(
        tester,
        find.widgetWithText(NavigationDestination, 'Hoje'),
      );
      await tapPlanning(
        tester,
        find.widgetWithText(NavigationDestination, 'Mais'),
      );
      expect(find.byType(AreasScreen), findsOneWidget);
      expect(
        router.configuration.findMatch(Uri.parse('/agenda')).isError,
        isTrue,
      );
      expect(await repo.all('Tasks'), isEmpty);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'four labelled destinations fit safe area and 200 percent text in $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(bottom: 24);
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final db = TudoAkiDatabase.memory();
        addTearDown(db.close);
        await bootPlanning(
          tester,
          PlanningRepository(db, () => DateTime(2026, 11, 10)),
          navigate: false,
        );
        for (final name in ['Planear', 'Metas', 'Mais', 'Hoje']) {
          await tapPlanning(
            tester,
            find.widgetWithText(NavigationDestination, name),
          );
          expect(find.byType(NavigationDestination), findsNWidgets(4));
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
