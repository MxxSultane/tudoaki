import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/features/finance/finance_panel.dart';
import 'package:tudo_aki/features/finance/finance_providers.dart';
import 'package:tudo_aki/features/finance/finance_repository.dart';
import 'package:tudo_aki/features/screens.dart';

Future<void> tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  late TudoAkiDatabase db;
  late TudoAkiRepository repo;
  setUp(() {
    db = TudoAkiDatabase.memory();
    repo = TudoAkiRepository(db);
  });
  tearDown(() => db.close());
  Future<void> render(WidgetTester tester, {bool profile = false}) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await initializeDateFormatting('pt');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          financeClockProvider.overrideWithValue(() => DateTime(2026, 10, 25)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: profile
                ? const TudoAkiScreen(section: 'Perfil')
                : const SingleChildScrollView(child: FinancePanel()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'profile changes only new defaults and finance keeps old edit denomination',
    (tester) async {
      await repo.save('FinancialTransactions', {
        'title': 'Despesa antiga',
        'amount_cents': 10000,
        'kind': 'expense',
        'category': 'Casa',
        'day': '2026-10-25',
      });
      await render(tester, profile: true);
      await tap(
        tester,
        find.widgetWithText(
          DropdownButtonFormField<String>,
          'Moeda para novos registos',
        ),
      );
      await tap(tester, find.text('Dólar americano (USD)').last);
      expect((await repo.all('UserPreferences')).single['currency'], 'USD');
      expect(
        (await repo.all('FinancialTransactions')).single['currency'],
        'MZN',
      );
      await render(tester);
      expect(find.text('Resumo mensal · USD'), findsOneWidget);
      expect(find.text('Despesas: 0,00 USD'), findsOneWidget);
      await tap(tester, find.text('Registar movimento'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Nova despesa',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Valor em USD (ex.: 1250,50)'),
        '25,40',
      );
      await tap(tester, find.widgetWithText(FilledButton, 'Guardar'));
      expect(find.text('Despesas: 25,40 USD'), findsOneWidget);
      await tap(
        tester,
        find.widgetWithText(
          DropdownButtonFormField<String>,
          'Moeda apresentada',
        ),
      );
      await tap(tester, find.text('Metical (MZN)').last);
      expect(find.text('Despesas: 100,00 MT'), findsOneWidget);
      await tap(tester, find.text('Despesa antiga'));
      expect(
        find.widgetWithText(TextFormField, 'Valor em MT (ex.: 1250,50)'),
        findsOneWidget,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Valor em MT (ex.: 1250,50)'),
        '110,50',
      );
      await tap(tester, find.widgetWithText(FilledButton, 'Guardar'));
      expect(find.text('Despesas: 110,50 MT'), findsOneWidget);
      expect(
        (await repo.all('FinancialTransactions')).first['currency'],
        'MZN',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'view currency scopes savings, contributions and recurring confirmation',
    (tester) async {
      await repo.save('SavingsGoals', {
        'title': 'Reserva USD',
        'target_cents': 10000,
        'currency': 'USD',
      });
      await repo.save('SavingsGoals', {
        'title': 'Reserva EUR',
        'target_cents': 10000,
        'currency': 'EUR',
      });
      await repo.saveRecurring(
        title: 'Renda USD',
        amountCents: 10001,
        kind: 'expense',
        category: 'Casa',
        frequency: 'monthly',
        start: DateTime(2026, 10, 1),
        currency: 'USD',
      );
      await render(tester);
      await tap(
        tester,
        find.widgetWithText(
          DropdownButtonFormField<String>,
          'Moeda apresentada',
        ),
      );
      await tap(tester, find.text('Dólar americano (USD)').last);
      expect(find.text('Reserva EUR'), findsNothing);
      await tap(tester, find.text('Registar contribuição'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Contribuição USD',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Valor em USD (ex.: 1250,50)'),
        '10,10',
      );
      await tap(tester, find.widgetWithText(FilledButton, 'Guardar'));
      expect(
        (await repo.all('FinancialTransactions')).single['currency'],
        'USD',
      );
      await tap(tester, find.text('Renda USD'));
      await tap(tester, find.text('Rever vencimentos'));
      expect(find.text('Total: 100,01 USD'), findsOneWidget);
      await tap(tester, find.text('Confirmar registo'));
      final rows = await repo.all('FinancialTransactions');
      expect(rows, hasLength(2));
      expect(rows.every((row) => row['currency'] == 'USD'), isTrue);
      expect((await repo.all('UserPreferences')).single['currency'], 'MZN');
      expect(tester.takeException(), isNull);
    },
  );
}
