import 'dart:math' as math;
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/theme/app_colors.dart';
import 'package:tudo_aki/core/theme/app_theme.dart';

Future<void> start(WidgetTester tester, TudoAkiRepository repo) async {
  await initializeDateFormatting('pt');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [repositoryProvider.overrideWithValue(repo)],
      child: const TudoAkiApp(),
    ),
  );
  await tester.runAsync(() => GoogleFonts.pendingFonts());
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> create(WidgetTester tester, String kind) async {
  await tap(tester, find.byType(FloatingActionButton));
  await tap(tester, find.widgetWithText(ListTile, kind));
}

Future<void> save(WidgetTester tester) =>
    tap(tester, find.widgetWithText(FilledButton, 'Guardar'));

void main() {
  testWidgets(
    'real goal, linked task, completion, event editing and native reopen',
    (tester) async {
      final directory = Directory.systemTemp.createTempSync('tudoaki-app-');
      final file = File('${directory.path}/db.sqlite');
      var db = TudoAkiDatabase(NativeDatabase(file));
      var repo = TudoAkiRepository(db);
      addTearDown(() async {
        await db.close();
        directory.deleteSync(recursive: true);
      });
      await start(tester, repo);
      expect(find.byType(NavigationDestination), findsNWidgets(3));
      expect(find.text('Hoje'), findsOneWidget);
      expect(find.text('Reunião de equipa'), findsNothing);
      await create(tester, 'Meta');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Ler doze livros',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Métrica de sucesso (ex.: livros)'),
        'livros',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Valor pretendido'),
        '12',
      );
      await save(tester);
      await tap(tester, find.widgetWithText(NavigationDestination, 'Metas'));
      await tap(tester, find.text('Ler doze livros'));
      await tap(tester, find.text('Adicionar acção'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Ler um capítulo',
      );
      await tap(tester, find.text('Quando: Escolher'));
      await tap(tester, find.text('OK'));
      await tap(tester, find.text('OK'));
      await save(tester);
      expect(
        (await repo.all('Tasks')).single['goal_id'],
        (await repo.all('Goals')).single['id'],
      );
      expect((await repo.all('Tasks')).single['due'], isNotNull);
      await tap(tester, find.byTooltip('Voltar'));
      await tap(tester, find.widgetWithText(NavigationDestination, 'Tarefas'));
      final row = find.ancestor(
        of: find.text('Ler um capítulo'),
        matching: find.byType(ListTile),
      );
      await tap(
        tester,
        find.descendant(of: row, matching: find.byType(Checkbox)),
      );
      await tap(tester, find.text('Concluídas'));
      await tap(tester, find.text('Ler um capítulo'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Capítulo lido',
      );
      await save(tester);
      expect((await repo.all('Tasks')).single['completed'], 1);
      expect((await repo.all('Goals')).single['current'], 0);
      expect((await repo.all('ExperienceEvents')).single['points'], 10);
      await tap(tester, find.widgetWithText(NavigationDestination, 'Metas'));
      await tap(tester, find.text('Ler doze livros'));
      await tap(tester, find.text('Registar progresso'));
      await tester.enterText(
        find.widgetWithText(TextField, 'Resultado em livros'),
        '3',
      );
      await save(tester);
      expect((await repo.all('Goals')).single['current'], 3);
      await tap(tester, find.byTooltip('Voltar'));

      await tap(tester, find.widgetWithText(NavigationDestination, 'Agenda'));
      await create(tester, 'Evento');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Encontro',
      );
      await save(tester);
      await tap(tester, find.text('Encontro'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Encontro semanal',
      );
      await tap(tester, find.text('Mais opções'));
      await tap(
        tester,
        find.widgetWithText(DropdownButtonFormField<String>, 'Repetir'),
      );
      await tap(tester, find.text('Todas as semanas').last);
      await save(tester);
      expect((await repo.all('CalendarEvents')).single['recurrence'], 'weekly');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await db.close();
      db = TudoAkiDatabase(NativeDatabase(file));
      repo = TudoAkiRepository(db);
      await start(tester, repo);
      expect(find.text('Encontro semanal'), findsOneWidget);
      await tap(tester, find.widgetWithText(NavigationDestination, 'Metas'));
      expect(find.text('Ler doze livros'), findsOneWidget);
      await tap(tester, find.widgetWithText(NavigationDestination, 'Tarefas'));
      await tap(tester, find.text('Concluídas'));
      expect(find.text('Capítulo lido'), findsOneWidget);
      expect((await repo.all('Goals')).single['current'], 3);
      await create(tester, 'Tarefa');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Próximo capítulo',
      );
      await save(tester);
      expect(find.text('Próximo capítulo'), findsOneWidget);
      expect((await repo.all('Tasks')).length, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'all personal areas are reachable through More and return to three tabs',
    (tester) async {
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      await start(tester, TudoAkiRepository(db));
      await tap(tester, find.text('Mais'));
      for (final title in [
        'Hábitos',
        'Estudos',
        'Finanças',
        'Progresso',
        'Revisões',
        'Definições',
      ]) {
        await tap(tester, find.widgetWithText(ListTile, title));
        expect(find.byType(NavigationDestination), findsNothing);
        expect(find.byType(FloatingActionButton), findsNothing);
        expect(
          find.byType(FilledButton).evaluate().length,
          lessThanOrEqualTo(1),
        );
        expect(tester.takeException(), isNull);
        await tap(tester, find.byTooltip('Voltar'));
      }
      await tap(tester, find.byTooltip('Voltar'));
      expect(find.byType(NavigationDestination), findsNWidgets(3));
      expect(find.text('Hoje'), findsOneWidget);
    },
  );

  testWidgets(
    'light and dark layouts fit 360px at normal and 200 percent text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = TudoAkiRepository(db);
      for (final brightness in Brightness.values) {
        for (final scale in [1.0, 2.0]) {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          await start(tester, repo);
          final context = tester.element(find.byType(TudoAkiShell));
          expect(Theme.of(context).brightness, brightness);
          expect(find.byType(FloatingActionButton), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tap(tester, find.byType(FloatingActionButton));
          for (final label in ['Evento', 'Tarefa', 'Meta']) {
            expect(
              find.widgetWithText(ListTile, label).hitTestable(),
              findsOneWidget,
            );
          }
          await tap(tester, find.widgetWithText(ListTile, 'Tarefa'));
          expect(find.byType(FilledButton), findsOneWidget);
          expect(tester.takeException(), isNull);
          Navigator.of(tester.element(find.byType(TextFormField).first)).pop();
          await tester.pumpAndSettle();
          for (final tab in ['Metas', 'Tarefas']) {
            await tap(tester, find.widgetWithText(NavigationDestination, tab));
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
      }
    },
  );

  test('palette, typography and text contrast follow the guide', () async {
    double contrast(Color a, Color b) {
      final first = a.computeLuminance(), second = b.computeLuminance();
      return (math.max(first, second) + .05) / (math.min(first, second) + .05);
    }

    for (final brightness in Brightness.values) {
      final theme = buildTheme(brightness);
      final dark = brightness == Brightness.dark;
      expect(
        theme.scaffoldBackgroundColor,
        dark ? AppColors.bgDark : AppColors.bgLight,
      );
      expect(
        theme.colorScheme.primary,
        dark ? AppColors.accentDark : AppColors.accentLight,
      );
      expect(
        theme.textTheme.headlineLarge!.fontFamily,
        startsWith('Newsreader'),
      );
      expect(theme.textTheme.bodyLarge!.fontFamily, startsWith('Inter'));
      expect(theme.textTheme.headlineLarge!.fontSize, 34);
      expect(theme.textTheme.titleLarge!.fontSize, 22);
      expect(theme.textTheme.bodyLarge!.fontSize, 16);
      expect(theme.textTheme.bodySmall!.fontSize, 13);
      expect(theme.cardTheme.elevation, 0);
      expect(theme.floatingActionButtonTheme.elevation, 0);
      for (final background in [
        theme.scaffoldBackgroundColor,
        theme.colorScheme.surface,
      ]) {
        expect(
          contrast(theme.textTheme.bodyLarge!.color!, background),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(theme.textTheme.bodySmall!.color!, background),
          greaterThanOrEqualTo(4.5),
        );
      }
      expect(
        contrast(theme.colorScheme.onPrimary, theme.colorScheme.primary),
        greaterThanOrEqualTo(4.5),
      );
    }
    expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
    await GoogleFonts.pendingFonts();
  });
}
