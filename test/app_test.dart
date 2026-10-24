import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/app/brand.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';

void main() {
  testWidgets('empty app starts without account and navigates to goals', (
    tester,
  ) async {
    await initializeDateFormatting('pt');
    final db = TudoAkiDatabase.memory();
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(TudoAkiRepository(db)),
        ],
        child: const TudoAkiApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Um passo de cada vez.'), findsOneWidget);
    expect(find.text('Tudo Aki'), findsOneWidget);
    expect(find.text('A tua vida, organizada num só lugar.'), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      'Tudo Aki',
    );
    expect(find.text('Bem-vindo ao Tudo Aki.'), findsOneWidget);
    await tester.tap(find.text('Metas').last);
    await tester.pumpAndSettle();
    expect(find.text('Qual é o seu próximo objectivo?'), findsOneWidget);
    await tester.tap(find.text('Criar meta'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Ler livros',
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Ler livros'), findsOneWidget);
    expect((await TudoAkiRepository(db).all('Goals')).single['target'], 1);
    await tester.tap(find.text('Adicionar acção'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Ler um capítulo',
    );
    await tester.tap(find.text('Quando: Escolher'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    final task = (await TudoAkiRepository(db).all('Tasks')).single;
    expect(
      task['goal_id'],
      (await TudoAkiRepository(db).all('Goals')).single['id'],
    );
    expect(task['due'], isNotNull);
    await tester.tap(find.text('Hoje').last);
    await tester.pumpAndSettle();
    final taskCard = find.ancestor(
      of: find.text('Ler um capítulo'),
      matching: find.byType(Card),
    );
    await tester.ensureVisible(taskCard);
    await tester.tap(
      find.descendant(of: taskCard, matching: find.byType(Checkbox)),
    );
    await tester.pumpAndSettle();
    expect((await TudoAkiRepository(db).all('Tasks')).single['completed'], 1);
    expect((await TudoAkiRepository(db).all('Goals')).single['current'], 0);
    await tester.tap(find.text('Progresso').last);
    await tester.pumpAndSettle();
    expect(find.text('1 tarefas concluídas'), findsOneWidget);
    expect(
      (await TudoAkiRepository(db).all('ExperienceEvents')).single['points'],
      10,
    );
  });
  testWidgets('brand header wraps on narrow screens with large text', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 220,
                child: MediaQuery(
                  data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                  child: const TudoAkiBrandHeader(showSlogan: true),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tudo Aki'), findsOneWidget);
      expect(find.text('A tua vida, organizada num só lugar.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
