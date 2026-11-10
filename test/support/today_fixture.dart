import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/database/schema.dart';
import 'package:tudo_aki/core/widgets/workspace_page.dart';
import '../quick_task_sheet_test.dart' show QuickReminders;

/// Synthetic SQLite and a deterministic clock; production operations stay real.
class TodayRepository extends TudoAkiRepository {
  TodayRepository(super.db, this.clock);
  final DateTime Function() clock;
  bool failCompletion = false, failRead = false;
  @override
  Future<void> taskDone(int id, bool done, {DateTime? at}) {
    if (failCompletion) return Future.error(StateError('disk failure'));
    return super.taskDone(id, done, at: at ?? clock());
  }

  @override
  Future<List<DataRowMap>> all(String table) {
    if (failRead && table == 'Tasks') {
      return Future.error(StateError('read failure'));
    }
    return super.all(table);
  }
}

Future<void> bootToday(WidgetTester tester, TodayRepository repo) async {
  await initializeDateFormatting('pt');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        workspaceClockProvider.overrideWithValue(repo.clock),
        remindersProvider.overrideWithValue(QuickReminders()),
      ],
      child: const TudoAkiApp(),
    ),
  );
  await tester.runAsync(() => GoogleFonts.pendingFonts());
  await tester.pumpAndSettle();
}

Future<void> revealToday(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final scrollable = find
        .descendant(
          of: find.byKey(const PageStorageKey('today-overview')),
          matching: find.byType(Scrollable),
        )
        .first;
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pumpAndSettle();
  }
  for (var i = 0; finder.evaluate().isEmpty && i < 30; i++) {
    await tester.drag(
      find.byKey(const PageStorageKey('today-overview')),
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();
  }
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> tapToday(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  if (finder.evaluate().isEmpty &&
      find
          .byKey(const PageStorageKey('today-overview'))
          .evaluate()
          .isNotEmpty) {
    await revealToday(tester, finder);
  } else {
    await tester.ensureVisible(finder);
  }
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<int> todayTask(
  TudoAkiRepository repo,
  String title,
  String? due, {
  int priority = 1,
  int important = 0,
}) => repo.save('Tasks', {
  'title': title,
  'due': due,
  'priority': priority,
  'important': important,
  'created': '2026-11-10T08:00:00',
});

Future<void> todayEvent(
  TudoAkiRepository repo,
  String title,
  DateTime day,
  int hour, {
  int minutes = 60,
}) => repo
    .save('CalendarEvents', {
      'title': title,
      'start': DateTime(day.year, day.month, day.day, hour).toIso8601String(),
      'end': DateTime(
        day.year,
        day.month,
        day.day,
        hour,
      ).add(Duration(minutes: minutes)).toIso8601String(),
    })
    .then((_) {});

Future<WorkspaceSnapshot> todaySnapshot(TudoAkiRepository repo) async => {
  for (final table in exportTables) table: await repo.all(table),
};
