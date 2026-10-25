import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/widgets/workspace_page.dart';

Future<void> tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  if (finder.evaluate().isEmpty) {
    final scrollable = find
        .descendant(
          of: find.byKey(const ValueKey('weekly-days')),
          matching: find.byType(Scrollable),
        )
        .first;
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(finder, 200, scrollable: scrollable);
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> open(WidgetTester tester, TudoAkiRepository repo) async {
  await initializeDateFormatting('pt');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        workspaceClockProvider.overrideWithValue(
          () => DateTime(2026, 10, 25, 16),
        ),
      ],
      child: const TudoAkiApp(),
    ),
  );
  await tester.runAsync(() => GoogleFonts.pendingFonts());
  await tester.pumpAndSettle();
  await tap(tester, find.text('Mais'));
  await tap(tester, find.widgetWithText(ListTile, 'Planear semana'));
}

Future<void> save(WidgetTester tester) =>
    tap(tester, find.widgetWithText(FilledButton, 'Guardar'));

void main() {
  testWidgets(
    'plan date-only tasks, bring a pending task and add an event into the real agenda',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = TudoAkiRepository(db);
      final pending = await repo.save('Tasks', {
        'title': 'Ler um capítulo',
        'created': '2026-10-25T16:00:00',
      });
      await open(tester, repo);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNothing);
      expect(await repo.all('CalendarEvents'), isEmpty);
      await tap(tester, find.text('Adicionar tarefa'));
      expect(find.text('Quando: 26/10/2026'), findsOneWidget);
      expect(find.byTooltip('Remover data'), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Preparar semana',
      );
      await save(tester);
      var planned = (await repo.all(
        'Tasks',
      )).singleWhere((t) => t['id'] != pending);
      final plannedId = planned['id'];
      expect(planned['due'], '2026-10-26');
      await tap(tester, find.text('Preparar semana'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Preparar relatório',
      );
      await save(tester);
      planned = (await repo.all(
        'Tasks',
      )).singleWhere((t) => t['id'] == plannedId);
      expect(planned['due'], '2026-10-26');
      await tap(tester, find.text('Escolher pendente'));
      await tap(tester, find.widgetWithText(ListTile, 'Ler um capítulo'));
      await save(tester);
      expect(await repo.all('Tasks'), hasLength(2));
      expect(
        (await repo.all('Tasks')).singleWhere((t) => t['id'] == pending)['due'],
        '2026-10-26',
      );
      await tap(tester, find.byKey(const ValueKey('plan-kind-event')));
      await tap(tester, find.byKey(const ValueKey('plan-day-1')));
      await tap(tester, find.text('Adicionar evento'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Reunião semanal',
      );
      await save(tester);
      final event = (await repo.all('CalendarEvents')).single;
      expect(event['start'], '2026-10-27T09:00:00.000');
      expect(event['end'], '2026-10-27T10:00:00.000');
      await tap(tester, find.text('Adicionar evento'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Não guardar',
      );
      Navigator.of(tester.element(find.byType(TextFormField).first)).pop();
      await tester.pumpAndSettle();
      expect(await repo.all('CalendarEvents'), hasLength(1));
      await tap(tester, find.byTooltip('Semana seguinte'));
      expect(find.text('Reunião semanal'), findsNothing);
      await tap(tester, find.byTooltip('Semana anterior'));
      expect(find.text('Reunião semanal'), findsOneWidget);
      expect(await repo.all('CalendarEvents'), hasLength(1));
      expect(await repo.all('ExperienceEvents'), isEmpty);
      await tap(tester, find.byTooltip('Voltar'));
      await tap(tester, find.byTooltip('Voltar'));
      await tap(tester, find.widgetWithText(TextButton, 'Semana'));
      await tap(tester, find.byTooltip('Período seguinte'));
      expect(find.text('Preparar relatório'), findsOneWidget);
      expect(find.text('Reunião semanal'), findsOneWidget);
      expect(find.text('Sem hora'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('planner tasks can opt into a time and keep it when reopened', (
    tester,
  ) async {
    final db = TudoAkiDatabase.memory();
    addTearDown(db.close);
    final repo = TudoAkiRepository(db);
    await open(tester, repo);
    await tap(tester, find.text('Adicionar tarefa'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Telefonar',
    );
    await tap(tester, find.text('Definir hora'));
    await tap(tester, find.text('OK'));
    await save(tester);
    expect((await repo.all('Tasks')).single['due'], '2026-10-26T09:00:00.000');
    await tap(tester, find.text('Telefonar'));
    expect(find.text('Quando: 26/10/2026 09:00'), findsOneWidget);
    await save(tester);
    expect((await repo.all('Tasks')).single['due'], '2026-10-26T09:00:00.000');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'week cards and entry forms fit 360px with 200 percent text in both themes',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      for (final brightness in Brightness.values) {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        await open(tester, TudoAkiRepository(db));
        expect(find.byType(FilledButton), findsOneWidget);
        await tap(tester, find.byKey(const ValueKey('plan-day-6')));
        await tap(tester, find.text('Adicionar tarefa'));
        expect(find.text('Quando: 01/11/2026'), findsOneWidget);
        expect(tester.takeException(), isNull);
        Navigator.of(tester.element(find.byType(TextFormField).first)).pop();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    },
  );
}
