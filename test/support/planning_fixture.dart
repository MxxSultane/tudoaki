import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/widgets/workspace_page.dart';
import 'package:tudo_aki/features/planning/domain/planning_view.dart';
import '../quick_task_sheet_test.dart';
import 'today_fixture.dart';

class PlanningRepository extends TodayRepository {
  PlanningRepository(super.db, super.clock);
  bool failSave = false;
  @override
  Future<int> save(String table, DataRowMap data, {int? id}) {
    if (failSave && table == 'Tasks') {
      return Future.error(StateError('disk failure'));
    }
    return super.save(table, data, id: id);
  }
}

class PlanningReminders extends QuickReminders {
  bool throws = false;
  @override
  Future<bool> schedule(int id, String title, DateTime date) async {
    final result = await super.schedule(id, title, date);
    if (throws) throw StateError('platform failure');
    return result;
  }
}

Future<void> bootPlanning(
  WidgetTester tester,
  PlanningRepository repo, {
  PlanningReminders? reminders,
  PlanningView view = PlanningView.week,
  bool navigate = true,
}) async {
  await initializeDateFormatting('pt');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        remindersProvider.overrideWithValue(reminders ?? PlanningReminders()),
        workspaceClockProvider.overrideWithValue(repo.clock),
      ],
      child: const TudoAkiApp(),
    ),
  );
  await tester.runAsync(() => GoogleFonts.pendingFonts());
  await tester.pumpAndSettle();
  if (navigate) {
    GoRouter.of(
      tester.element(find.byType(TudoAkiShell)),
    ).push('/weekly-planner', extra: view);
    await tester.pumpAndSettle();
  }
}

Future<void> tapPlanning(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  if (finder.evaluate().isEmpty) {
    final scrollable = find.byType(Scrollable).hitTestable().last;
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(finder, 250, scrollable: scrollable);
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> planView(WidgetTester tester, PlanningView view) =>
    tapPlanning(tester, find.byKey(ValueKey('planning-view-${view.name}')));
Future<void> savePlan(WidgetTester tester) =>
    tapPlanning(tester, find.widgetWithText(FilledButton, 'Guardar'));
Future<void> planMenu(WidgetTester tester, int id, String action) async {
  await tapPlanning(tester, find.byKey(ValueKey('plan-task-menu-$id')));
  await tapPlanning(tester, find.text(action));
}

Future<void> pickPlanDate(WidgetTester tester, String date) async {
  final locale = MaterialLocalizations.of(
    tester.element(find.byType(DatePickerDialog)),
  );
  await tapPlanning(tester, find.byTooltip(locale.inputDateModeButtonLabel));
  await tester.enterText(find.byType(TextFormField).last, date);
  await tapPlanning(tester, find.text('OK'));
}
