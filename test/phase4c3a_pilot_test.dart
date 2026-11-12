import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/theme/premium_tokens.dart';
import 'package:tudo_aki/core/widgets/premium_components.dart';
import 'package:tudo_aki/features/forms.dart';
import 'package:tudo_aki/features/goals/presentation/goals_screen.dart';
import 'package:tudo_aki/features/tasks/presentation/task_row.dart';
import 'support/today_fixture.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'pilot $dark: scaled Hoje/Metas retains data, targets, filters, direct form and legacy scope',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final db = TudoAkiDatabase.memory();
        addTearDown(db.close);
        final now = DateTime(2026, 11, 11, 10, 30);
        final repo = TodayRepository(db, () => now);
        await repo.save('UserPreferences', {
          'theme': dark ? 'dark' : 'light',
        }, id: 1);
        final id = await repo.save('Goals', {
          'title': 'Ler livros de história e partilhar o que aprendi',
          'initial': 2,
          'current': 3,
          'target': 12,
          'unit': 'livros',
          'due': '2026-12-31T23:59:00',
          'created': '2026-01-01T08:12:34',
        });
        await repo.save('Goals', {
          'title': 'Meta alcançada',
          'status': 'completed',
          'current': 5,
          'target': 5,
          'unit': 'sessões',
          'created': '2026-01-02',
        });
        await todayTask(repo, 'Preparar apresentação', dayKey(now));
        await todayEvent(repo, 'Consulta', now, 11);
        await repo.save('Habits', {'title': 'Ler um capítulo'});
        final before = await todaySnapshot(repo);
        await bootToday(tester, repo);
        final create = find.byType(FloatingActionButton);
        expect(tester.getSize(create), const Size(56, 56));
        // Today tasks, checkbox and row remain different operable targets.
        await revealToday(tester, find.byType(TaskRow));
        expect(
          tester.getSize(find.byType(Checkbox).first).shortestSide,
          greaterThanOrEqualTo(48),
        );
        expect(
          tester.getSize(find.byType(TaskRow).first).height,
          greaterThanOrEqualTo(48),
        );
        expect(tester.takeException(), isNull);
        final router = GoRouter.of(tester.element(find.byType(TudoAkiShell)));
        router.go('/goals');
        await tester.pumpAndSettle();
        expect(find.text('3 / 12 livros'), findsOneWidget);
        final active = find.widgetWithText(TextButton, 'Activas');
        final completed = find.widgetWithText(TextButton, 'Alcançadas');
        for (final f in [active, completed]) {
          final size = tester.getSize(f);
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));
        }
        final filterSemantics = tester.ensureSemantics();
        expect(
          tester.getSemantics(find.byType(PremiumFilter).first),
          matchesSemantics(
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            isSelected: true,
            hasSelectedState: true,
            label: 'Activas',
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
        filterSemantics.dispose();
        await tester.tap(completed);
        await tester.pumpAndSettle();
        expect(find.text('Meta alcançada'), findsOneWidget);
        await tester.tap(active);
        await tester.pumpAndSettle();
        final progress = tester.widget<LinearProgressIndicator>(
          find.descendant(
            of: find.byType(GoalsScreen),
            matching: find.byType(LinearProgressIndicator),
          ),
        );
        expect(
          progress.value,
          closeTo(.1, .0001),
        ); // initial=2, not fabricated 0.
        expect(progress.semanticsValue, '3 de 12 livros');
        // Keyboard focus is visually distinct from the active check/soft fill.
        Focus.of(
          tester.element(
            find.descendant(of: active, matching: find.byType(Text)),
          ),
        ).requestFocus();
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus!.hasFocus, isTrue);
        final ring =
            tester
                    .widget<DecoratedBox>(
                      find.descendant(
                        of: find.byType(PremiumFilter).first,
                        matching: find.byKey(
                          const ValueKey('premium-focus-ring'),
                        ),
                      ),
                    )
                    .decoration
                as BoxDecoration;
        expect(ring.border!.top.width, 2);
        expect(ring.border!.top.color, PremiumTokens(dark).action);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        expect(find.byType(Editor), findsOneWidget);
        expect(tester.widget<Editor>(find.byType(Editor)).kind, 'Meta');
        expect(
          Theme.of(
            tester.element(find.byType(Editor)),
          ).extension<PremiumTokens>(),
          isNull,
        );
        // Cancel through the existing back operation; no write, conversion or XP.
        router.pop();
        await tester.pumpAndSettle();
        router.go('/plan');
        await tester.pumpAndSettle();
        expect(
          Theme.of(
            tester.element(find.byType(Scaffold).last),
          ).extension<PremiumTokens>(),
          isNull,
        );
        final after = await todaySnapshot(repo);
        expect(after, before);
        expect(
          (await repo.all('Goals')).firstWhere((g) => g['id'] == id)['due'],
          '2026-12-31T23:59:00',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
}
