import 'support/navigation_access.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/notifications/reminders.dart';
import 'package:tudo_aki/features/tasks/presentation/task_row.dart';

class RecordingReminders extends Reminders {
  final cancelled = <int>[];
  final scheduled = <({int id, String title, DateTime date})>[];

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
  }

  @override
  Future<bool> schedule(int id, String title, DateTime date) async {
    scheduled.add((id: id, title: title, date: date));
    return true;
  }
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> openTasks(
  WidgetTester tester,
  TudoAkiRepository repo,
  Reminders reminders,
) async {
  await initializeDateFormatting('pt');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        remindersProvider.overrideWithValue(reminders),
      ],
      child: const TudoAkiApp(),
    ),
  );
  await tester.runAsync(() => GoogleFonts.pendingFonts());
  await tester.pumpAndSettle();
  // Characterizes the current shell only; the 2.0 shell is not implemented.
  expect(find.byType(NavigationDestination), findsNWidgets(4));
  await openGlobalTasks(tester);
}

void main() {
  testWidgets(
    'title-only creation appears immediately and cancel writes nothing',
    (tester) async {
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = TudoAkiRepository(db);
      await openTasks(tester, repo, RecordingReminders());
      await tap(tester, find.byType(FloatingActionButton));
      await tap(tester, find.widgetWithText(ListTile, 'Tarefa'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Comprar pão',
      );
      await tap(tester, find.widgetWithText(FilledButton, 'Guardar'));
      final row = (await repo.all('Tasks')).single;
      expect(row['due'], isNull);
      expect(row['reminder'], 0);
      expect(row['goal_id'], isNull);
      expect(row['subject_id'], isNull);
      expect(find.text('Comprar pão'), findsOneWidget);
      await tap(tester, find.text('Comprar pão'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Não guardar',
      );
      Navigator.of(tester.element(find.byType(TextFormField).first)).pop();
      await tester.pumpAndSettle();
      expect((await repo.all('Tasks')).single, row);
      expect(await repo.all('ExperienceEvents'), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact edits and completion keep links and reminder identity', (
    tester,
  ) async {
    final db = TudoAkiDatabase.memory();
    addTearDown(db.close);
    final repo = TudoAkiRepository(db);
    final goal = await repo.save('Goals', {
      'title': 'Aprender',
      'target': 12,
      'created': '2026-10-26T10:00:00',
    });
    final subject = await repo.save('Subjects', {'title': 'História'});
    final id = await repo.save('Tasks', {
      'title': 'Revisão',
      'created': '2026-10-26T10:00:00',
      'due': '2090-01-02T09:30:00.000',
      'reminder': 1,
      'goal_id': goal,
      'subject_id': subject,
      'priority': 2,
      'important': 1,
    });
    final before = (await repo.all('Tasks')).single;
    final reminders = RecordingReminders();
    await openTasks(tester, repo, reminders);
    await tap(tester, find.text('Revisão'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Rever capítulo',
    );
    await tap(tester, find.widgetWithText(FilledButton, 'Guardar'));
    expect((await repo.all('Tasks')).single, {
      ...before,
      'title': 'Rever capítulo',
    });
    expect(reminders.cancelled, [id]);
    expect(reminders.scheduled.single, (
      id: id,
      title: 'Rever capítulo',
      date: DateTime(2090, 1, 2, 9, 30),
    ));
    await tap(
      tester,
      find.descendant(
        of: find.byType(TaskRow),
        matching: find.byType(Checkbox),
      ),
    );
    expect(reminders.cancelled, [id, id]);
    await tap(tester, find.text('Concluídas'));
    expect(find.text('Rever capítulo'), findsOneWidget);
    await tap(
      tester,
      find.descendant(
        of: find.byType(TaskRow),
        matching: find.byType(Checkbox),
      ),
    );
    expect(reminders.scheduled, hasLength(2));
    expect(reminders.scheduled.last, reminders.scheduled.first);
    await tap(tester, find.text('Pendentes'));
    expect(find.text('Rever capítulo'), findsOneWidget);
    expect((await repo.all('Tasks')).single, {
      ...before,
      'title': 'Rever capítulo',
    });
    expect((await repo.all('ExperienceEvents')).single['points'], 10);
    expect((await repo.all('Achievements')).single['code'], 'first_task');
    expect((await repo.all('Goals')).single['current'], 0);
    expect(tester.takeException(), isNull);
  });
}
