import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/features/finance/finance_providers.dart';
import 'package:tudo_aki/features/finance/finance_repository.dart';
import 'package:tudo_aki/features/screens.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<TudoAkiRepository> launch(
  WidgetTester tester,
  DateTime now, {
  Future<void> Function(TudoAkiRepository)? seed,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await initializeDateFormatting('pt');
  final db = TudoAkiDatabase.memory();
  final repo = TudoAkiRepository(db);
  addTearDown(db.close);
  if (seed != null) await tester.runAsync(() => seed(repo));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        financeClockProvider.overrideWithValue(() => now),
      ],
      child: const MaterialApp(
        home: Scaffold(body: TudoAkiScreen(section: 'Finanças')),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets(
    'monthly budget tracks manual expenses, edits and month navigation',
    (tester) async {
      final repo = await launch(tester, DateTime(2026, 2, 15));
      await tapVisible(tester, find.text('Adicionar orçamento'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Categoria'),
        'Alimentação',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Limite em MT'),
        '1000,50',
      );
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
      expect((await repo.all('Budgets')).single['month'], '2026-02');
      await tapVisible(tester, find.text('Registar movimento'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Compras de casa',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Valor em MT (ex.: 1250,50)'),
        '250,10',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Categoria'),
        'ALIMENTAÇÃO',
      );
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
      expect(
        (await repo.all('FinancialTransactions')).single['day'],
        '2026-02-15',
      );
      expect(find.text('250,10 MT de 1.000,50 MT'), findsOneWidget);
      expect(find.text('Restante: 750,40 MT'), findsOneWidget);
      await tapVisible(tester, find.byTooltip('Mês seguinte'));
      expect(find.text('Despesas: 0,00 MT'), findsOneWidget);
      expect(find.text('Restante: 750,40 MT'), findsNothing);
      await tapVisible(tester, find.byTooltip('Mês anterior'));
      await tapVisible(tester, find.byTooltip('Editar orçamento'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Limite em MT'),
        '2000,50',
      );
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
      expect(find.text('Restante: 1.750,40 MT'), findsOneWidget);
      expect(
        (await repo.all('FinancialTransactions')).single['amount_cents'],
        25010,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'recurring review requires confirmation, avoids duplicates and preserves deleted dates',
    (tester) async {
      final repo = await launch(
        tester,
        DateTime(2026, 3, 31),
        seed: (repo) async {
          await repo.saveRecurring(
            title: 'Renda',
            amountCents: 50000,
            kind: 'expense',
            category: 'Casa',
            frequency: 'monthly',
            start: DateTime(2026, 1, 31),
          );
        },
      );
      expect(await repo.all('FinancialTransactions'), isEmpty);
      await tapVisible(tester, find.text('Renda'));
      await tapVisible(tester, find.text('Rever vencimentos'));
      expect(find.text('31/01/2026'), findsOneWidget);
      expect(find.text('28/02/2026'), findsOneWidget);
      expect(find.text('31/03/2026'), findsOneWidget);
      await tapVisible(tester, find.widgetWithText(TextButton, 'Cancelar'));
      expect(await repo.all('FinancialTransactions'), isEmpty);
      await tapVisible(tester, find.text('Rever vencimentos'));
      await tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'Confirmar registo'),
      );
      expect((await repo.all('FinancialTransactions')).length, 3);
      expect(find.text('Despesas: 500,00 MT'), findsOneWidget);
      await tapVisible(tester, find.text('Rever vencimentos'));
      expect((await repo.all('FinancialTransactions')).length, 3);
      await tapVisible(tester, find.widgetWithText(ListTile, 'Renda').last);
      await tapVisible(tester, find.widgetWithText(TextButton, 'Eliminar'));
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Eliminar'));
      expect((await repo.all('FinancialTransactions')).length, 2);
      await tapVisible(tester, find.text('Rever vencimentos'));
      expect((await repo.all('FinancialTransactions')).length, 2);
      expect(
        (await repo.all(
          'RecurringOccurrences',
        )).where((row) => row['transaction_id'] == null).length,
        1,
      );
      await tapVisible(tester, find.text('Editar regra'));
      await tapVisible(tester, find.widgetWithText(TextButton, 'Eliminar'));
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Eliminar'));
      expect(await repo.all('RecurringTransactions'), isEmpty);
      expect((await repo.all('FinancialTransactions')).length, 2);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'savings contributions and goal edits preserve exact amounts and orphan history',
    (tester) async {
      final repo = await launch(tester, DateTime(2026, 2, 15));
      await tapVisible(tester, find.text('Criar poupança'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Reserva',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Valor pretendido em MT'),
        '30000,50',
      );
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
      await tapVisible(tester, find.text('Registar contribuição'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Primeira contribuição',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Valor em MT (ex.: 1250,50)'),
        '12000,10',
      );
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
      expect(
        (await repo.all('FinancialTransactions')).single['kind'],
        'saving',
      );
      expect(find.text('12.000,10 MT / 30.000,50 MT'), findsOneWidget);
      await tapVisible(tester, find.byTooltip('Editar poupança'));
      expect(find.text('30000,50'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Valor pretendido em MT'),
        '40000,50',
      );
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
      expect((await repo.all('SavingsGoals')).single['target_cents'], 4000050);
      await tapVisible(tester, find.byTooltip('Editar poupança'));
      await tapVisible(tester, find.widgetWithText(TextButton, 'Eliminar'));
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Eliminar'));
      expect(await repo.all('SavingsGoals'), isEmpty);
      expect(
        (await repo.all('FinancialTransactions')).single['savings_id'],
        isNull,
      );
      await tapVisible(tester, find.text('Primeira contribuição'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Contribuição preservada',
      );
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
      expect(
        (await repo.all('FinancialTransactions')).single['title'],
        'Contribuição preservada',
      );
      expect(
        (await repo.all('FinancialTransactions')).single['amount_cents'],
        1200010,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
