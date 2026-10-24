import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/features/screens.dart';

void main() {
  testWidgets('create a subgoal, manage milestones and complete a linked task', (
    tester,
  ) async {
    // Scrolling a growing goal card requires a layout frame before hit testing.
    Future<void> tapVisible(Finder finder) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      expect(finder.hitTestable(), findsOneWidget);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await initializeDateFormatting('pt');
    final db = TudoAkiDatabase.memory();
    final repo = TudoAkiRepository(db);
    addTearDown(db.close);
    final parent = await tester.runAsync(() async {
      final id = await repo.save('Goals', {
        'title': 'Ler doze livros',
        'target': 12,
        'created': '2026-10-24',
        'horizon': 'Anual',
      });
      await repo.save('Tasks', {
        'title': 'Ler um capítulo',
        'goal_id': id,
        'created': '2026-10-24',
      });
      return id;
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: Scaffold(body: TudoAkiScreen(section: 'Metas')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final card = find.byKey(ValueKey('goal-$parent'));
    await tapVisible(
      find.descendant(of: card, matching: find.text('Criar submeta')),
    );
    expect(find.text('Mensal'), findsOneWidget);
    expect(find.text('Ler doze livros').hitTestable(), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Ler em Novembro',
    );
    await tapVisible(find.widgetWithText(FilledButton, 'Guardar'));
    final child = (await repo.all(
      'Goals',
    )).firstWhere((g) => g['parent_id'] == parent);
    expect(child['horizon'], 'Mensal');
    expect(find.text('Submeta de: Ler doze livros'), findsOneWidget);

    await tapVisible(
      find.descendant(of: card, matching: find.text('Plano desta meta')),
    );
    await tapVisible(
      find.descendant(of: card, matching: find.text('Adicionar etapa')),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Escolher os livros',
    );
    await tapVisible(find.widgetWithText(FilledButton, 'Guardar'));

    Finder stageTile(String title) =>
        find.ancestor(of: find.text(title), matching: find.byType(ListTile));
    final stage = stageTile('Escolher os livros');
    await tapVisible(
      find.descendant(of: stage, matching: find.byType(Checkbox)),
    );
    expect((await repo.all('GoalMilestones')).single['completed'], 1);
    expect((await repo.all('Goals')).first['current'], 0);
    expect(await repo.all('ExperienceEvents'), isEmpty);

    await tapVisible(
      find.descendant(of: stage, matching: find.byTooltip('Editar etapa')),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Escolher o primeiro livro',
    );
    await tapVisible(find.widgetWithText(FilledButton, 'Guardar'));
    expect(
      (await repo.all('GoalMilestones')).single['title'],
      'Escolher o primeiro livro',
    );
    expect((await repo.all('GoalMilestones')).single['completed'], 1);

    await tapVisible(
      find.descendant(
        of: stageTile('Ler um capítulo'),
        matching: find.byType(Checkbox),
      ),
    );
    expect((await repo.all('Tasks')).single['completed'], 1);
    expect((await repo.all('Goals')).first['current'], 0);
    expect((await repo.all('ExperienceEvents')).single['points'], 10);

    await tapVisible(
      find.descendant(
        of: stageTile('Escolher o primeiro livro'),
        matching: find.byTooltip('Editar etapa'),
      ),
    );
    await tapVisible(find.widgetWithText(TextButton, 'Eliminar'));
    await tapVisible(find.widgetWithText(FilledButton, 'Eliminar'));
    expect(await repo.all('GoalMilestones'), isEmpty);
    expect(find.text('Escolher o primeiro livro'), findsNothing);
    expect((await repo.all('Tasks')).single['completed'], 1);
    expect(tester.takeException(), isNull);
  });
}
