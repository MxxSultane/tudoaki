import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/features/agenda/presentation/today_screen.dart';
import 'package:tudo_aki/features/tasks/presentation/quick_task_sheet.dart';
import 'support/planning_fixture.dart';
import 'support/today_fixture.dart';

void viewport(WidgetTester tester, Size size, double scale) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewInsets);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  for (final width in [320.0, 360.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final dark in [false, true]) {
        for (final count in [0, 2, 30]) {
          testWidgets(
            'Hoje $width scale$scale dark$dark tasks$count separates creation from content',
            (tester) async {
              viewport(tester, Size(width, 844), scale);
              final db = TudoAkiDatabase.memory();
              addTearDown(db.close);
              final repo = PlanningRepository(
                db,
                () => DateTime(2026, 11, 11, 10),
              );
              await repo.save('UserPreferences', {
                'theme': dark ? 'dark' : 'light',
              }, id: 1);
              for (var i = 0; i < count; i++) {
                await todayTask(repo, 'Tarefa $i', '2026-11-11');
              }
              await repo.save('Habits', {'title': 'Caminhar'});
              await bootPlanning(tester, repo, navigate: false);
              final list = find
                  .descendant(
                    of: find.byType(TodayScreen),
                    matching: find.byType(Scrollable),
                  )
                  .first;
              final fab = find.byType(FloatingActionButton);
              final bar = find.byType(NavigationBar);
              // The action participates in the header layout, rather than
              // floating above arbitrary rows while the list scrolls.
              expect(
                find.descendant(of: find.byType(TodayScreen), matching: fab),
                findsOneWidget,
              );
              expect(
                tester.getRect(fab).bottom,
                lessThanOrEqualTo(tester.getRect(bar).top),
              );
              final habits = find.widgetWithText(TextButton, 'Ver hábitos');
              await tester.scrollUntilVisible(habits, 250, scrollable: list);
              await tester.ensureVisible(habits);
              await tester.pumpAndSettle();
              if (fab.evaluate().isNotEmpty) {
                expect(
                  tester.getRect(habits).overlaps(tester.getRect(fab)),
                  isFalse,
                );
              } else {
                expect(fab.hitTestable(), findsNothing);
              }
              expect(habits.hitTestable(), findsOneWidget);
              await tester.tap(habits);
              await tester.pumpAndSettle();
              expect(find.text('Caminhar'), findsOneWidget);
              await tester.binding.handlePopRoute();
              await tester.pumpAndSettle();
              await tester.scrollUntilVisible(fab, -300, scrollable: list);
              await tester.ensureVisible(fab);
              await tester.pumpAndSettle();
              await tester.tap(fab);
              await tester.pumpAndSettle();
              expect(find.widgetWithText(ListTile, 'Tarefa'), findsOneWidget);
              await tester.binding.handlePopRoute();
              await tester.pumpAndSettle();
              expect(await repo.all('Tasks'), hasLength(count));
              expect(tester.takeException(), isNull);
            },
          );
        }
        for (final landscape in [false, true]) {
          testWidgets(
            'quick $width scale$scale dark$dark landscape$landscape wraps and saves',
            (tester) async {
              viewport(
                tester,
                landscape ? Size(800, width) : Size(width, 800),
                scale,
              );
              final db = TudoAkiDatabase.memory();
              addTearDown(db.close);
              final repo = PlanningRepository(
                db,
                () => DateTime(2026, 11, 11, 10),
              );
              await repo.save('UserPreferences', {
                'theme': dark ? 'dark' : 'light',
              }, id: 1);
              await bootPlanning(tester, repo, navigate: false);
              await tapPlanning(tester, find.text('Adicionar tarefa'));
              tester.view.viewInsets = FakeViewPadding(
                bottom: landscape ? 100 : 280,
              );
              await tester.enterText(
                find.widgetWithText(TextFormField, 'Título'),
                'Primeira',
              );
              await tester.pumpAndSettle();
              final another = find.widgetWithText(
                TextButton,
                'Guardar e adicionar outra',
              );
              // Both actions must be fully visible before any manual scroll.
              final rect = tester.getRect(another);
              expect(rect.top, greaterThanOrEqualTo(24));
              expect(
                rect.bottom,
                lessThanOrEqualTo(
                  (landscape ? width : 800) - (landscape ? 100 : 280),
                ),
              );
              expect(another.hitTestable(), findsOneWidget);
              final text = find.descendant(
                of: another,
                matching: find.byType(RichText),
              );
              final paragraph = tester.renderObject<RenderParagraph>(text);
              expect(paragraph.didExceedMaxLines, isFalse);
              final label = paragraph.text.toPlainText();
              for (final word in RegExp(r'\S+').allMatches(label)) {
                for (final box in paragraph.getBoxesForSelection(
                  TextSelection(baseOffset: word.start, extentOffset: word.end),
                )) {
                  expect(
                    box.bottom,
                    lessThanOrEqualTo(paragraph.size.height + 1),
                  );
                  expect(
                    box.right,
                    lessThanOrEqualTo(paragraph.size.width + 1),
                  );
                }
              }
              expect(tester.getSize(another).height, greaterThanOrEqualTo(48));
              expect(another.hitTestable(), findsOneWidget);
              await tester.tap(another);
              await tester.pumpAndSettle();
              expect(await repo.all('Tasks'), hasLength(1));
              expect(find.byType(QuickTaskSheet), findsOneWidget);
              await tester.enterText(
                find.widgetWithText(TextFormField, 'Título'),
                'Segunda',
              );
              await savePlan(tester);
              expect(find.byType(QuickTaskSheet), findsNothing);
              expect(await repo.all('Tasks'), hasLength(2));
              tester.view.resetViewInsets();
              await tester.pumpAndSettle();
              await tapPlanning(tester, find.text('Adicionar tarefa'));
              await tapPlanning(tester, find.text('Cancelar'));
              expect(await repo.all('Tasks'), hasLength(2));
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
}
