import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/notifications/reminders.dart';
import 'package:tudo_aki/features/tasks/presentation/task_row.dart';

class UnavailableReminders extends Reminders {
  UnavailableReminders(this.fail);
  final bool fail;
  final cancelled = <int>[];
  final scheduled = <int>[];
  @override
  Future<bool> schedule(int id, String title, DateTime date) async {
    scheduled.add(id);
    if (fail) throw StateError('Native alarm unavailable');
    return false;
  }

  @override
  Future<void> cancel(int id) async => cancelled.add(id);
}

void main() {
  for (final fail in [false, true]) {
    testWidgets(
      'reopening persists and warns when reminder ${fail ? 'throws' : 'is refused'}',
      (tester) async {
        await initializeDateFormatting('pt');
        final db = TudoAkiDatabase.memory();
        addTearDown(db.close);
        final repo = TudoAkiRepository(db);
        final id = await repo.save('Tasks', {
          'title': 'Consulta',
          'created': '2026-10-26T10:00:00',
          'due': '2090-01-01T09:00:00',
          'reminder': 1,
        });
        await repo.taskDone(id, true);
        final xp = (await repo.all('ExperienceEvents')).length;
        final task = (await repo.all('Tasks')).single;
        final reminders = UnavailableReminders(fail);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              repositoryProvider.overrideWithValue(repo),
              remindersProvider.overrideWithValue(reminders),
            ],
            child: MaterialApp(
              home: Scaffold(body: TaskRow(task: task)),
            ),
          ),
        );
        expect(find.bySemanticsLabel('Reabrir Consulta'), findsOneWidget);
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();
        expect((await repo.all('Tasks')).single['completed'], 0);
        expect((await repo.all('ExperienceEvents')).length, xp);
        expect(reminders.scheduled, [id]);
        expect(
          find.text('Tarefa guardada; verifica o lembrete.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
