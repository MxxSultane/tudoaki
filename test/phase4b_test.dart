import 'dart:io';
import 'package:drift/native.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/features/tasks/presentation/quick_task_sheet.dart';
import 'quick_task_sheet_test.dart' as quick;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudo_aki/features/forms.dart';
import 'package:tudo_aki/features/habits/presentation/habits_screen.dart';
import 'legacy_modules_test.dart' as support;
import 'package:tudo_aki/core/database/database.dart';

void main() {
  test('habits survive closing SQLite and reopening with XP intact', () async {
    final directory = Directory.systemTemp.createTempSync('phase4b-');
    final file = File('${directory.path}/synthetic.sqlite');
    var db = TudoAkiDatabase(NativeDatabase(file));
    try {
      var repo = TudoAkiRepository(db);
      final ids = <int>[];
      for (final title in ['Ler', 'Correr', 'Meditar']) {
        ids.add(await repo.save('Habits', {'title': title}));
      }
      await repo.save('Habits', {'title': 'Ler mais'}, id: ids.first);
      await repo.toggleHabit(ids.first, DateTime(2026, 11, 12));
      final rows = await repo.all('Habits');
      final completions = await repo.all('HabitCompletions');
      final xp = await repo.all('ExperienceEvents');
      await db.close();
      db = TudoAkiDatabase(NativeDatabase(file));
      repo = TudoAkiRepository(db);
      expect(await repo.all('Habits'), rows);
      expect(await repo.all('HabitCompletions'), completions);
      expect(await repo.all('ExperienceEvents'), xp);
      await repo.toggleHabit(ids.first, DateTime(2026, 11, 12));
      await repo.toggleHabit(ids.first, DateTime(2026, 11, 12));
      expect(await repo.all('ExperienceEvents'), xp);
    } finally {
      await db.close();
      directory.deleteSync(recursive: true);
    }
  });
  testWidgets('goals FAB opens existing goal form directly', (tester) async {
    final db = TudoAkiDatabase.memory();
    addTearDown(db.close);
    final repo = TudoAkiRepository(db);
    await support.openArea(tester, repo, 'Hábitos');
    await support.tap(tester, find.byTooltip('Voltar'));
    await support.tap(
      tester,
      find.widgetWithText(NavigationDestination, 'Metas'),
    );
    await support.tap(tester, find.byType(FloatingActionButton));
    expect(tester.widget<Editor>(find.byType(Editor)).kind, 'Meta');
    expect(find.text('Evento'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Nova meta',
    );
    await support.tap(
      tester,
      find.widgetWithText(TextButton, 'Medir com números'),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Métrica de sucesso (ex.: livros)'),
      'livros',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Valor pretendido'),
      '12',
    );
    await support.tap(tester, find.widgetWithText(FilledButton, 'Criar'));
    expect((await repo.all('Goals')).single['title'], 'Nova meta');
    expect(find.byType(TudoAkiShell), findsOneWidget);
  });
  testWidgets('quick initial hierarchy retains repeated save after title', (
    tester,
  ) async {
    final db = TudoAkiDatabase.memory();
    addTearDown(db.close);
    await quick.open(tester, TudoAkiRepository(db), quick.QuickReminders());
    expect(find.byType(QuickTaskSheet), findsOneWidget);
    expect(find.text('Guardar e adicionar outra'), findsNothing);
    expect(find.text('Mais opções'), findsOneWidget);
    await quick.title(tester, 'Uma tarefa');
    await tester.pumpAndSettle();
    expect(find.text('Guardar e adicionar outra'), findsOneWidget);
    await quick.more(tester);
    expect(find.text('Prioridade'), findsOneWidget);
  });
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('multiple habits dark=$dark scale=$scale', (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final db = TudoAkiDatabase.memory();
        addTearDown(db.close);
        final repo = TudoAkiRepository(db);
        await repo.save('UserPreferences', {
          'theme': dark ? 'dark' : 'light',
        }, id: 1);
        await support.openArea(tester, repo, 'Hábitos');
        for (final title in ['Ler', 'Caminhar', 'Alongar']) {
          final create = find.text('Criar hábito');
          expect(create, findsOneWidget);
          await support.tap(tester, create);
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Título'),
            title,
          );
          await support.tap(
            tester,
            find.widgetWithText(FilledButton, 'Guardar'),
          );
          expect(find.byType(Editor), findsNothing);
        }
        final rows = await repo.all('Habits');
        expect(rows.map((r) => r['title']), ['Ler', 'Caminhar', 'Alongar']);
        expect(rows.map((r) => r['id']).toSet(), hasLength(3));
        expect(await repo.all('ExperienceEvents'), isEmpty);
        await support.tap(tester, find.byTooltip('Editar hábito').first);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Título'),
          'Ler mais',
        );
        await support.tap(tester, find.widgetWithText(FilledButton, 'Guardar'));
        expect((await repo.all('Habits')).first['id'], rows.first['id']);
        final check = find.descendant(
          of: find.widgetWithText(ListTile, 'Ler mais'),
          matching: find.byType(Checkbox),
        );
        await support.tap(tester, check);
        await support.tap(tester, check);
        await support.tap(tester, check);
        expect(await repo.all('ExperienceEvents'), hasLength(1));
        expect((await repo.all('ExperienceEvents')).single['points'], 5);
        await support.tap(tester, find.byTooltip('Voltar'));
        await support.tap(tester, find.widgetWithText(ListTile, 'Hábitos'));
        expect(find.byType(HabitsScreen), findsOneWidget);
        expect(tester.widget<Checkbox>(check).value, isTrue);
        expect(await repo.all('Habits'), hasLength(3));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
