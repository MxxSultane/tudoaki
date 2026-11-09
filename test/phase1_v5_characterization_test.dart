import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/database/schema.dart';
import 'package:tudo_aki/features/progress/progress_rules.dart';

void main() {
  for (final due in <String?>[null, '2090-01-02', '2090-01-02T09:30:00.000']) {
    test(
      'v5 reopen preserves task identity, links and date precision: $due',
      () async {
        // Synthetic fixture only: never open TudoAkiDatabase.local() in tests.
        final directory = Directory.systemTemp.createTempSync(
          'tudoaki-phase1-',
        );
        final file = File('${directory.path}/fixture.sqlite');
        var db = TudoAkiDatabase(NativeDatabase(file));
        addTearDown(() async {
          await db.close();
          directory.deleteSync(recursive: true);
        });
        var repo = TudoAkiRepository(db);
        final goal = await repo.save('Goals', {
          'title': 'Ler',
          'target': 12,
          'created': '2026-10-26T10:00:00',
        });
        final subject = await repo.save('Subjects', {'title': 'Português'});
        final reminder = due != null && !isDateOnly(due) ? 1 : 0;
        final id = await repo.save('Tasks', {
          'title': 'Capítulo',
          'created': '2026-10-26T10:00:00',
          'due': due,
          'goal_id': goal,
          'subject_id': subject,
          'reminder': reminder,
          'priority': 2,
          'important': 1,
        });
        expect(
          await repo.save('Tasks', {'title': 'Capítulo revisto'}, id: id),
          id,
        );
        expect(await repo.save('Tasks', {'due': '2090-01-03'}, id: id), id);
        expect(await repo.all('Tasks'), hasLength(1));
        // Return to the original precision, preserving every unrelated field.
        await repo.save('Tasks', {'due': due}, id: id);
        await repo.taskDone(id, true, at: DateTime(2026, 10, 26, 11));
        await repo.syncAchievements();
        final recognition = await repo.all('Achievements');
        expect(recognition.single['code'], 'first_task');
        final experience = await repo.all('ExperienceEvents');
        expect(experience.single['source'], 'task:$id');
        expect(experience.single['points'], 10);
        await repo.taskDone(id, false);
        await repo.taskDone(id, true);
        await repo.taskDone(id, false);
        await repo.syncAchievements();
        expect(await repo.all('ExperienceEvents'), experience);
        expect(await repo.all('Achievements'), recognition);
        expect((await repo.all('Goals')).single['current'], 0);
        final row = (await repo.all('Tasks')).single;
        expect(row, containsPair('id', id));
        expect(row, containsPair('title', 'Capítulo revisto'));
        expect(row, containsPair('goal_id', goal));
        expect(row, containsPair('subject_id', subject));
        expect(row, containsPair('due', due));
        expect(row, containsPair('reminder', reminder));
        expect(row, containsPair('priority', 2));
        expect(row, containsPair('important', 1));
        expect(row, containsPair('completed', 0));
        expect(row['completed_at'], isNull);
        final before = jsonDecode(await repo.exportJson()) as Map;
        expect(before['schemaVersion'], 5);
        for (final table in exportTables) {
          expect(before, contains(table));
        }
        final schema = await repo.query(
          'SELECT name, sql FROM sqlite_master ORDER BY name',
        );
        await db.close();
        db = TudoAkiDatabase(NativeDatabase(file));
        repo = TudoAkiRepository(db);
        expect(
          (await repo.query('PRAGMA user_version')).single.values.single,
          5,
        );
        expect(await repo.query('PRAGMA foreign_key_check'), isEmpty);
        expect(
          await repo.query('SELECT name, sql FROM sqlite_master ORDER BY name'),
          schema,
        );
        final after = jsonDecode(await repo.exportJson()) as Map;
        for (final table in exportTables) {
          expect(after[table], before[table], reason: table);
        }
      },
    );
  }
}
