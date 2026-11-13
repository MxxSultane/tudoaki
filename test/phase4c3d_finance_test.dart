import 'dart:async';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/theme/premium_tokens.dart';
import 'package:tudo_aki/core/widgets/premium_components.dart';
import 'package:tudo_aki/core/widgets/workspace_page.dart';
import 'package:tudo_aki/features/finance/finance_amount.dart';
import 'package:tudo_aki/features/finance/finance_panel.dart';
import 'package:tudo_aki/features/finance/finance_providers.dart';
import 'package:tudo_aki/features/finance/finance_rules.dart';
import 'package:tudo_aki/features/forms.dart';
import 'support/finance_fixture.dart';
import 'support/planning_fixture.dart' show PlanningReminders;

final financeNow = DateTime(2026, 11, 11, 10, 30);

class FinanceTestRepo extends TudoAkiRepository {
  FinanceTestRepo(super.db);
  bool failRead = false;
  Completer<void>? gate;
  @override
  Future<List<DataRowMap>> all(String table) async {
    if (table == 'FinancialTransactions') {
      if (failRead) throw StateError('synthetic read failure');
      if (gate != null) await gate!.future;
    }
    return super.all(table);
  }
}

Future<void> bootFinance(
  WidgetTester t,
  TudoAkiRepository repo, {
  bool settle = true,
}) async {
  await initializeDateFormatting('pt');
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        financeClockProvider.overrideWithValue(() => financeNow),
        workspaceClockProvider.overrideWithValue(() => financeNow),
        remindersProvider.overrideWithValue(PlanningReminders()),
      ],
      child: const TudoAkiApp(),
    ),
  );
  await t.runAsync(() => GoogleFonts.pendingFonts());
  if (settle) {
    await t.pumpAndSettle();
  } else {
    await t.pump(const Duration(milliseconds: 100));
  }
  GoRouter.of(t.element(find.byType(TudoAkiShell))).go('/finance');
  if (settle) {
    await t.pumpAndSettle();
  } else {
    await t.pump(const Duration(milliseconds: 350));
  }
}

Future<void> pressFinance(WidgetTester t, Finder f) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await t.pumpAndSettle();
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  expect(f.hitTestable(), findsOneWidget);
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> expandFinance(WidgetTester t, String id) => pressFinance(
  t,
  find
      .descendant(of: find.byKey(ValueKey(id)), matching: find.byType(ListTile))
      .first,
);
Finder financeValue(String id, String text) =>
    find.descendant(of: find.byKey(ValueKey(id)), matching: find.text(text));
void smallFinance(WidgetTester t, {double width = 320, double scale = 2}) {
  t.view.physicalSize = Size(width, width == 320 ? 640 : 800);
  t.view.devicePixelRatio = 1;
  t.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  addTearDown(t.view.resetViewInsets);
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  for (final dark in [false, true]) {
    for (final width in [320.0, 360.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'finance $dark ${width}dp ${scale}x hierarchy, targets, semantics, focus and read-only disclosure',
          (t) async {
            smallFinance(t, width: width, scale: scale);
            t.platformDispatcher.accessibilityFeaturesTestValue =
                const FakeAccessibilityFeatures(disableAnimations: true);
            addTearDown(
              t.platformDispatcher.clearAccessibilityFeaturesTestValue,
            );
            final db = TudoAkiDatabase.memory();
            addTearDown(db.close);
            final repo = TudoAkiRepository(db);
            await seedFinance(repo);
            await repo.save('UserPreferences', {
              'theme': dark ? 'dark' : 'light',
            }, id: 1);
            final before = await financeSnapshot(repo);
            await bootFinance(t, repo);
            expect(find.text('Finanças'), findsOneWidget);
            expect(find.text('MZN'), findsOneWidget);
            expect(
              find.textContaining('Sem conversão cambial.'),
              findsOneWidget,
            );
            expect(
              financeValue('finance-result', '22.749,75 MT'),
              findsOneWidget,
            );
            final action = find.widgetWithText(
              FilledButton,
              'Registar movimento',
            );
            expect(
              t.getTopLeft(find.byKey(const ValueKey('view-currency-MZN'))).dy,
              lessThan(
                t.getTopLeft(find.byKey(const ValueKey('finance-result'))).dy,
              ),
            );
            expect(
              t.getTopLeft(action).dy,
              lessThan(t.getTopLeft(find.text('Movimentos do mês')).dy),
            );
            if (scale == 1 && width == 390) {
              expect(action.hitTestable(), findsOneWidget);
            }
            expect(find.text('Adicionar orçamento'), findsNothing);
            for (final f in [
              action,
              find.byTooltip('Mês anterior'),
              find.byTooltip('Mês seguinte'),
              find.byKey(const ValueKey('view-currency-MZN')),
            ]) {
              final size = t.getSize(f);
              expect(size.width, greaterThanOrEqualTo(48));
              expect(size.height, greaterThanOrEqualTo(48));
            }
            final theme = Theme.of(t.element(action));
            final tokens = PremiumTokens.of(t.element(action));
            expect(theme.expansionTileTheme.iconColor, tokens.action);
            expect(theme.expansionTileTheme.collapsedIconColor, tokens.action);
            expect(
              theme.expansionTileTheme.expansionAnimationStyle!.duration,
              Duration.zero,
            );
            expect(
              find.descendant(
                of: find.byType(PremiumSurface),
                matching: find.byType(PremiumSurface),
              ),
              findsNothing,
            );
            await t.ensureVisible(action);
            await t.pumpAndSettle();
            Focus.of(
              t.element(
                find.descendant(of: action, matching: find.byType(Text)).first,
              ),
            ).requestFocus();
            await t.pumpAndSettle();
            expect(FocusManager.instance.primaryFocus!.hasFocus, isTrue);
            expect(
              theme.filledButtonTheme.style!.side!.resolve({
                WidgetState.focused,
              })!.width,
              2,
            );
            await t.sendKeyEvent(LogicalKeyboardKey.tab);
            await t.pumpAndSettle();
            await t.ensureVisible(find.byKey(const ValueKey('finance-result')));
            await t.pumpAndSettle();
            final semantics = t.ensureSemantics();
            expect(
              t
                  .getSemantics(find.byKey(const ValueKey('finance-result')))
                  .label,
              contains('22.749,75 MT'),
            );
            expect(
              t
                  .getSemantics(find.byKey(const ValueKey('finance-result')))
                  .label,
              contains('Metical (MZN)'),
            );
            semantics.dispose();
            await expandFinance(t, 'finance-composition');
            expect(
              financeValue('finance-income', '25.000,50 MT'),
              findsOneWidget,
            );
            expect(
              financeValue('finance-expense', '1.250,50 MT'),
              findsOneWidget,
            );
            expect(
              financeValue('finance-saving-total', '1.000,25 MT'),
              findsOneWidget,
            );
            for (final id in [
              'finance-budgets',
              'finance-savings',
              'finance-recurring',
            ]) {
              await expandFinance(t, id);
            }
            expect(find.text('749,50 MT'), findsOneWidget);
            expect(find.text('1.050,25 MT'), findsOneWidget);
            for (final label in [
              'Adicionar orçamento',
              'Criar poupança',
              'Nova recorrência',
              'Registar contribuição',
              'Editar orçamento',
              'Editar poupança',
            ]) {
              final f = find.widgetWithText(TextButton, label);
              final size = t.getSize(f);
              expect(size.width, greaterThanOrEqualTo(48));
              expect(size.height, greaterThanOrEqualTo(48));
            }
            await pressFinance(t, find.text('Renda mensal'));
            expect(find.text('Movimento registado.'), findsOneWidget);
            for (final id in [
              'finance-composition',
              'finance-budgets',
              'finance-savings',
              'finance-recurring',
            ]) {
              await expandFinance(t, id);
            }
            expect(await financeSnapshot(repo), before);
            expect(t.takeException(), isNull);
            await t.pumpWidget(const SizedBox.shrink());
            await t.pumpAndSettle();
          },
        );
      }
    }
  }
  for (final currency in currencyLabels.keys) {
    testWidgets(
      '$currency creation, exact large edit, month/currency context and cancellation preserve IDs and denomination',
      (t) async {
        smallFinance(t);
        final db = TudoAkiDatabase.memory();
        addTearDown(db.close);
        final repo = TudoAkiRepository(db);
        await repo.save('UserPreferences', {'currency': currency}, id: 1);
        await bootFinance(t, repo);
        final before = await financeSnapshot(repo);
        await pressFinance(t, find.text('Registar movimento'));
        await pressFinance(t, find.text('Cancelar'));
        expect(await financeSnapshot(repo), before);
        await pressFinance(t, find.text('Registar movimento'));
        await t.enterText(
          find.widgetWithText(TextFormField, 'Título'),
          'Despesa exacta',
        );
        await t.enterText(
          find.widgetWithText(
            TextFormField,
            'Valor em ${currencyUnit(currency)} (ex.: 1250,50)',
          ),
          '0,01',
        );
        t.view.viewInsets = const FakeViewPadding(bottom: 280);
        await t.pumpAndSettle();
        await pressFinance(t, find.widgetWithText(FilledButton, 'Guardar'));
        t.view.resetViewInsets();
        await t.pumpAndSettle();
        final old = (await repo.all('FinancialTransactions')).single;
        expect(old['amount_cents'], 1);
        expect(old['currency'], currency);
        expect(old['day'], '2026-11-11');
        expect(old['kind'], 'expense');
        await pressFinance(t, find.text('Despesa exacta'));
        await t.enterText(
          find.widgetWithText(
            TextFormField,
            'Valor em ${currencyUnit(currency)} (ex.: 1250,50)',
          ),
          '90071992547409,91',
        );
        await pressFinance(t, find.widgetWithText(FilledButton, 'Guardar'));
        final edited = (await repo.all('FinancialTransactions')).single;
        expect(edited, {...old, 'amount_cents': 9007199254740991});
        await pressFinance(t, find.byTooltip('Mês seguinte'));
        expect(
          find.text('Sem movimentos neste mês em $currency.'),
          findsOneWidget,
        );
        await pressFinance(t, find.text('Registar movimento'));
        expect(find.text('Data: 01/12/2026'), findsOneWidget);
        await pressFinance(t, find.text('Cancelar'));
        await pressFinance(t, find.byTooltip('Mês anterior'));
        expect((await repo.all('FinancialTransactions')).single, edited);
        expect(await repo.all('ExperienceEvents'), isEmpty);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox.shrink());
        await t.pumpAndSettle();
      },
    );
  }
  testWidgets(
    'invalid and zero monetary input never writes, retains draft and reports errors',
    (t) async {
      smallFinance(t);
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = TudoAkiRepository(db);
      await bootFinance(t, repo);
      final before = await financeSnapshot(repo);
      await pressFinance(t, find.text('Registar movimento'));
      await pressFinance(t, find.widgetWithText(FilledButton, 'Guardar'));
      expect(find.text('Preencha este campo'), findsNWidgets(2));
      await t.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Rascunho preservado',
      );
      final input = find.widgetWithText(
        TextFormField,
        'Valor em MT (ex.: 1250,50)',
      );
      for (final value in [
        '0',
        '-1',
        'abc',
        '1,001',
        '90071992547409,92',
        'NaN',
      ]) {
        await t.enterText(input, value);
        await pressFinance(t, find.widgetWithText(FilledButton, 'Guardar'));
        expect(find.byType(Editor), findsOneWidget);
        expect(find.text('Rascunho preservado'), findsOneWidget);
        expect(await financeSnapshot(repo), before);
      }
      await pressFinance(t, find.text('Cancelar'));
      expect(await financeSnapshot(repo), before);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'currency and month selectors only read, keep savings all-time and isolate totals',
    (t) async {
      smallFinance(t, width: 360, scale: 1);
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = TudoAkiRepository(db);
      await seedFinance(repo);
      final before = await financeSnapshot(repo);
      await bootFinance(t, repo);
      for (final entry in {
        'USD': '994,95 USD',
        'EUR': '-110,01 EUR',
        'ZAR': '-120,01 ZAR',
        'MZN': '22.749,75 MT',
      }.entries) {
        await pressFinance(
          t,
          find.widgetWithText(
            DropdownButtonFormField<String>,
            'Moeda apresentada',
          ),
        );
        await pressFinance(t, find.text(currencyLabels[entry.key]!).last);
        expect(financeValue('finance-result', entry.value), findsOneWidget);
      }
      await expandFinance(t, 'finance-savings');
      expect(find.text('1.050,25 MT'), findsOneWidget);
      await pressFinance(t, find.byTooltip('Mês anterior'));
      expect(find.text('1.050,25 MT'), findsOneWidget);
      expect(financeValue('finance-result', '-1.549,99 MT'), findsOneWidget);
      expect(await financeSnapshot(repo), before);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'recurring review, cancel, confirm, locked edit and replay keep exact amounts and occurrence history',
    (t) async {
      smallFinance(t);
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = TudoAkiRepository(db);
      await seedFinance(repo);
      await bootFinance(t, repo);
      final before = await financeSnapshot(repo);
      await expandFinance(t, 'finance-recurring');
      await pressFinance(t, find.text('Renda mensal'));
      await pressFinance(t, find.text('Rever vencimentos'));
      expect(find.text('01/11/2026'), findsOneWidget);
      expect(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.text('500,00 MT'),
            )
            .first
            .hitTestable(),
        findsOneWidget,
      );
      expect(await financeSnapshot(repo), before);
      await pressFinance(t, find.widgetWithText(TextButton, 'Cancelar'));
      expect(await financeSnapshot(repo), before);
      await pressFinance(t, find.text('Rever vencimentos'));
      await pressFinance(t, find.text('Confirmar registo'));
      final after = await financeSnapshot(repo);
      expect(
        after['FinancialTransactions']!.length,
        before['FinancialTransactions']!.length + 1,
      );
      expect(after['RecurringOccurrences']!.length, 2);
      await pressFinance(t, find.text('Rever vencimentos'));
      expect(await financeSnapshot(repo), after);
      await pressFinance(t, find.text('Editar regra'));
      expect(
        t
            .widget<DropdownButtonFormField<String>>(
              find.widgetWithText(
                DropdownButtonFormField<String>,
                'Frequência',
              ),
            )
            .onChanged,
        isNull,
      );
      expect(
        find.textContaining('O calendário com registos está preservado.'),
        findsOneWidget,
      );
      await pressFinance(t, find.text('Cancelar'));
      expect(await financeSnapshot(repo), after);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'long totals retain every digit, currency, keyboard scrolling and full semantic label',
    (t) async {
      smallFinance(t);
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = TudoAkiRepository(db);
      await seedFinance(repo, longValues: true);
      final budget = (await repo.all('Budgets')).single;
      await repo.save('Budgets', {
        'limit_cents': 9007199254740991,
      }, id: budget['id'] as int);
      final before = await financeSnapshot(repo);
      await bootFinance(t, repo);
      final expected = formatMoney(
        BigInt.from(9007199254740991) * BigInt.from(3) + BigInt.from(2274975),
      );
      final result = find.byKey(const ValueKey('finance-result'));
      expect(
        find.descendant(of: result, matching: find.text(expected)),
        findsOneWidget,
      );
      final paragraph = t.renderObject<RenderParagraph>(
        find.descendant(of: result, matching: find.text(expected)),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      final value = t.widget<Text>(
        find.descendant(of: result, matching: find.text(expected)),
      );
      expect(value.softWrap, isFalse);
      expect(value.overflow, isNull);
      final horizontal = find.descendant(
        of: result,
        matching: find.byType(SingleChildScrollView),
      );
      expect(horizontal, findsOneWidget);
      final scroll = t.widget<SingleChildScrollView>(horizontal).controller!;
      expect(scroll.position.maxScrollExtent, greaterThan(0));
      Focus.of(
        t.element(find.descendant(of: result, matching: find.text(expected))),
      ).requestFocus();
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.pumpAndSettle();
      expect(scroll.offset, greaterThan(0));
      final semantics = t.ensureSemantics();
      expect(t.getSemantics(result).label, contains(expected));
      expect(t.getSemantics(result).label, contains('Metical (MZN)'));
      semantics.dispose();
      await expandFinance(t, 'finance-budgets');
      final limit = find.descendant(
        of: find.byKey(const ValueKey('finance-budgets')),
        matching: find.byWidgetPredicate(
          (w) => w is FinanceAmount && w.label == 'Limite',
        ),
      );
      final limitScroll = t.widget<SingleChildScrollView>(
        find.descendant(
          of: limit,
          matching: find.byType(SingleChildScrollView),
        ),
      );
      expect(
        limitScroll.controller!.offset,
        0,
        reason:
            'A newly revealed amount must not inherit the vertical page offset.',
      );
      expect(await financeSnapshot(repo), before);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'finance read error supports retry and never presents a zero balance',
    (t) async {
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = FinanceTestRepo(db)..failRead = true;
      await bootFinance(t, repo);
      expect(find.text('Não foi possível abrir os dados.'), findsOneWidget);
      expect(find.byType(FinanceAmount), findsNothing);
      repo.failRead = false;
      await pressFinance(t, find.text('Tentar novamente'));
      expect(financeValue('finance-result', '0,00 MT'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('finance loading is distinct from an empty month', (t) async {
    final db = TudoAkiDatabase.memory();
    addTearDown(db.close);
    final repo = FinanceTestRepo(db)..gate = Completer<void>();
    await bootFinance(t, repo, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('Sem movimentos neste mês'), findsNothing);
    repo.gate!.complete();
    await t.pumpAndSettle();
    expect(financeValue('finance-result', '0,00 MT'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'navigation and financial form cancel preserve every financial row',
    (t) async {
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = TudoAkiRepository(db);
      await seedFinance(repo);
      await repo.save('FinancialTransactions', {
        'title': 'Movimento mais antigo',
        'kind': 'expense',
        'amount_cents': 1,
        'category': 'Geral',
        'day': '2026-11-08',
        'currency': 'MZN',
      });
      await bootFinance(t, repo);
      final before = await financeSnapshot(repo);
      expect(find.text('Movimento mais antigo'), findsNothing);
      await pressFinance(t, find.text('Ver todos os movimentos (4)'));
      expect(find.text('Movimento mais antigo'), findsOneWidget);
      expect(await financeSnapshot(repo), before);
      await pressFinance(t, find.text('Mostrar só recentes'));
      expect(find.text('Movimento mais antigo'), findsNothing);
      expect(await financeSnapshot(repo), before);
      for (final pair in [
        ('finance-budgets', 'Adicionar orçamento'),
        ('finance-savings', 'Criar poupança'),
        ('finance-recurring', 'Nova recorrência'),
      ]) {
        await expandFinance(t, pair.$1);
        await pressFinance(t, find.text(pair.$2));
        await pressFinance(t, find.text('Cancelar'));
        expect(await financeSnapshot(repo), before);
      }
      final router = GoRouter.of(t.element(find.byType(FinancePanel)));
      for (final route in ['/academics', '/goals', '/plan', '/finance']) {
        router.go(route);
        await t.pumpAndSettle();
        expect(await financeSnapshot(repo), before);
      }
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'saving type and long association remain inside their fields at 320dp and 200%',
    (t) async {
      smallFinance(t);
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = TudoAkiRepository(db);
      const name = 'Reserva para uma viagem e formação profissional';
      await repo.save('SavingsGoals', {
        'title': name,
        'target_cents': 1000050,
        'currency': 'MZN',
      });
      await bootFinance(t, repo);
      await expandFinance(t, 'finance-savings');
      await pressFinance(t, find.text('Registar contribuição'));
      for (final text in ['Contribuição para poupança', name]) {
        final field = find.widgetWithText(
          text == name
              ? DropdownButtonFormField<int>
              : DropdownButtonFormField<String>,
          text,
        );
        await t.ensureVisible(field);
        await t.pumpAndSettle();
        final paragraph = find
            .descendant(of: field, matching: find.text(text))
            .first;
        final outer = t.getRect(field);
        final inner = t.getRect(paragraph);
        expect(inner.bottom, lessThanOrEqualTo(outer.bottom));
        RenderObject? ancestor = t
            .renderObject<RenderParagraph>(paragraph)
            .parent;
        while (ancestor != null) {
          if (ancestor is RenderIndexedStack) {
            final top = ancestor.localToGlobal(Offset.zero);
            expect(
              inner.bottom,
              lessThanOrEqualTo(top.dy + ancestor.size.height),
            );
            break;
          }
          ancestor = ancestor.parent;
        }
        expect(
          t.renderObject<RenderParagraph>(paragraph).didExceedMaxLines,
          isFalse,
        );
      }
      await pressFinance(t, find.text('Cancelar'));
      expect(await repo.all('FinancialTransactions'), isEmpty);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'budget and recurring editors keep errors, keyboard access and cancellation at 320dp and 200%',
    (t) async {
      smallFinance(t);
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = TudoAkiRepository(db);
      await bootFinance(t, repo);
      final before = await financeSnapshot(repo);
      for (final item in [
        ('finance-budgets', 'Adicionar orçamento', 'Limite em MT'),
        ('finance-recurring', 'Nova recorrência', 'Valor em MT'),
      ]) {
        await expandFinance(t, item.$1);
        await pressFinance(t, find.text(item.$2));
        if (item.$1 == 'finance-recurring') {
          await t.enterText(
            find.widgetWithText(TextFormField, 'Título'),
            'Conta mensal',
          );
        }
        final amount = find.widgetWithText(TextFormField, item.$3);
        await t.enterText(amount, '0');
        t.view.viewInsets = const FakeViewPadding(bottom: 280);
        await t.pumpAndSettle();
        await pressFinance(t, find.widgetWithText(FilledButton, 'Guardar'));
        expect(find.text('Valor fora do intervalo permitido'), findsOneWidget);
        expect(await financeSnapshot(repo), before);
        await pressFinance(t, find.text('Cancelar'));
        t.view.resetViewInsets();
        await t.pumpAndSettle();
        expect(await financeSnapshot(repo), before);
      }
      expect(t.takeException(), isNull);
    },
  );
  test(
    'financial fixtures retain exact totals and relationships after synthetic file reopens',
    () async {
      final dir = await Directory.systemTemp.createTemp('finance-c3d-');
      final file = File('${dir.path}/synthetic.sqlite');
      var db = TudoAkiDatabase(NativeDatabase(file));
      var repo = TudoAkiRepository(db);
      try {
        await seedFinance(repo, longValues: true);
        final before = await financeSnapshot(repo);
        await db.close();
        db = TudoAkiDatabase(NativeDatabase(file));
        repo = TudoAkiRepository(db);
        expect(await financeSnapshot(repo), before);
        expect(
          (await repo.query('PRAGMA user_version')).single.values.single,
          5,
        );
        expect(await repo.query('PRAGMA foreign_key_check'), isEmpty);
        final rows = await repo.all('FinancialTransactions');
        expect(
          transactionTotal(
            rows,
            (r) =>
                rowCurrency(r) == 'MZN' &&
                r['kind'] == 'income' &&
                (r['day'] as String).startsWith('2026-11'),
          ),
          BigInt.from(9007199254740991) * BigInt.from(3) + BigInt.from(2500050),
        );
      } finally {
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
