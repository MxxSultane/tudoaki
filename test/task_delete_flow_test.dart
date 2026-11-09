import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'phase1_task_flows_test.dart' as flows;

void main() {
  testWidgets(
    'task deletion through the existing editor cancels its reminder',
    (tester) async {
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = TudoAkiRepository(db);
      final id = await repo.save('Tasks', {
        'title': 'Eliminar consulta',
        'created': '2026-11-09T10:00:00',
        'due': '2090-01-02T09:00:00.000',
        'reminder': 1,
      });
      await repo.taskDone(id, true);
      await repo.taskDone(id, false);
      final experience = await repo.all('ExperienceEvents');
      final reminders = flows.RecordingReminders();
      await flows.openTasks(tester, repo, reminders);
      await flows.tap(tester, find.text('Eliminar consulta'));
      await flows.tap(tester, find.widgetWithText(TextButton, 'Eliminar'));
      await flows.tap(tester, find.widgetWithText(TextButton, 'Cancelar'));
      expect(await repo.all('Tasks'), hasLength(1));
      expect(reminders.cancelled, isEmpty);
      await flows.tap(tester, find.widgetWithText(TextButton, 'Eliminar'));
      await flows.tap(tester, find.widgetWithText(FilledButton, 'Eliminar'));
      expect(reminders.cancelled, [id]);
      expect(await repo.all('Tasks'), isEmpty);
      expect(find.text('Eliminar consulta'), findsNothing);
      expect(await repo.all('ExperienceEvents'), experience);
      expect(tester.takeException(), isNull);
    },
  );
}
