import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/features/forms.dart';
import 'package:tudo_aki/features/tasks/presentation/quick_task_sheet.dart';
import 'support/planning_fixture.dart';

Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

Future<void> _attemptTab(WidgetTester tester, int selected) async {
  final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
  bar.onDestinationSelected!((selected + 1) % 4);
  await tester.pumpAndSettle();
  expect(
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
    selected,
  );
}

Future<void> _assertNavigationReleased(WidgetTester tester) async {
  await tapPlanning(
    tester,
    find.widgetWithText(NavigationDestination, 'Metas'),
  );
  expect(
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
    2,
  );
  await tapPlanning(tester, find.widgetWithText(NavigationDestination, 'Hoje'));
  expect(find.byType(FloatingActionButton), findsOneWidget);
}

void main() {
  late TudoAkiDatabase db;
  late PlanningRepository repo;
  setUp(() {
    db = TudoAkiDatabase.memory();
    repo = PlanningRepository(db, () => DateTime(2026, 11, 10, 10));
  });
  tearDown(() => db.close());

  testWidgets(
    'clean quick-sheet Android Back releases the shell repeatedly without writes',
    (tester) async {
      await bootPlanning(tester, repo, navigate: false);
      for (var cycle = 0; cycle < 2; cycle++) {
        await tapPlanning(tester, find.text('Adicionar tarefa'));
        expect(find.byType(QuickTaskSheet), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsNothing);
        await _attemptTab(tester, 0);
        await _back(tester);
        expect(find.byType(QuickTaskSheet), findsNothing);
        expect(find.text('Descartar alterações?'), findsNothing);
        await _assertNavigationReleased(tester);
      }
      expect(await repo.all('Tasks'), isEmpty);
      expect(await repo.all('ExperienceEvents'), isEmpty);
    },
  );

  testWidgets(
    'nested dirty-discard dialog keeps shell protected until the actual draft closes',
    (tester) async {
      await bootPlanning(tester, repo, navigate: false);
      await tapPlanning(tester, find.text('Adicionar tarefa'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Rascunho que deve continuar',
      );
      // Let the input event rebuild PopScope before a separate back event.
      await tester.pumpAndSettle();
      await _back(tester);
      expect(find.text('Descartar alterações?'), findsOneWidget);
      await _attemptTab(tester, 0);
      await _back(tester);
      expect(find.text('Descartar alterações?'), findsNothing);
      expect(find.text('Rascunho que deve continuar'), findsOneWidget);
      await _attemptTab(tester, 0);
      await tapPlanning(tester, find.text('Cancelar'));
      expect(find.text('Descartar alterações?'), findsOneWidget);
      await tapPlanning(tester, find.text('Continuar a editar'));
      expect(find.text('Rascunho que deve continuar'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      await _attemptTab(tester, 0);
      await tapPlanning(tester, find.text('Cancelar'));
      expect(find.text('Descartar alterações?'), findsOneWidget);
      await tapPlanning(tester, find.widgetWithText(FilledButton, 'Descartar'));
      expect(find.byType(QuickTaskSheet), findsNothing);
      await _assertNavigationReleased(tester);
      expect(await repo.all('Tasks'), isEmpty);
    },
  );

  testWidgets(
    'nested date picker and failed quick save preserve draft and unlock only after retry',
    (tester) async {
      await bootPlanning(tester, repo, navigate: false);
      await tapPlanning(tester, find.text('Adicionar tarefa'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Gravar depois de recuperar',
      );
      await tapPlanning(tester, find.textContaining('Dia: '));
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await _attemptTab(tester, 0);
      await tapPlanning(
        tester,
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.text('Cancelar'),
        ),
      );
      expect(find.byType(QuickTaskSheet), findsOneWidget);
      expect(find.text('Gravar depois de recuperar'), findsOneWidget);
      await _attemptTab(tester, 0);
      repo.failSave = true;
      await savePlan(tester);
      expect(
        find.text('Não foi possível guardar. Tenta novamente.'),
        findsOneWidget,
      );
      expect(await repo.all('Tasks'), isEmpty);
      expect(find.text('Gravar depois de recuperar'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      await _attemptTab(tester, 0);
      repo.failSave = false;
      await savePlan(tester);
      expect(find.byType(QuickTaskSheet), findsNothing);
      final task = (await repo.all('Tasks')).single;
      expect(task['title'], 'Gravar depois de recuperar');
      expect(task['due'], '2026-11-10');
      await _assertNavigationReleased(tester);
      expect(await repo.all('Tasks'), hasLength(1));
      expect(await repo.all('ExperienceEvents'), isEmpty);
    },
  );

  testWidgets(
    'root creator and full editor keep guard through nested picker failure and successful save',
    (tester) async {
      await bootPlanning(tester, repo, navigate: false);
      // Clean cancellation of the root popup must not leave a stale guard.
      await tapPlanning(tester, find.byType(FloatingActionButton));
      expect(find.widgetWithText(ListTile, 'Tarefa'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      await _attemptTab(tester, 0);
      await _back(tester);
      await _assertNavigationReleased(tester);

      await tapPlanning(tester, find.byType(FloatingActionButton));
      await tapPlanning(tester, find.widgetWithText(ListTile, 'Tarefa'));
      expect(find.byType(Editor), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Editor completo recuperado',
      );
      await tapPlanning(tester, find.textContaining('Quando: '));
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await _attemptTab(tester, 0);
      await tapPlanning(
        tester,
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.text('Cancelar'),
        ),
      );
      expect(find.byType(Editor), findsOneWidget);
      repo.failSave = true;
      await savePlan(tester);
      expect(find.byType(Editor), findsOneWidget);
      expect(find.text('Editor completo recuperado'), findsOneWidget);
      expect(await repo.all('Tasks'), isEmpty);
      await _attemptTab(tester, 0);
      repo.failSave = false;
      await savePlan(tester);
      expect(find.byType(Editor), findsNothing);
      expect(
        (await repo.all('Tasks')).single['title'],
        'Editor completo recuperado',
      );
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
      await _assertNavigationReleased(tester);
      expect(await repo.all('Tasks'), hasLength(1));
      expect(await repo.all('ExperienceEvents'), isEmpty);
    },
  );
}
