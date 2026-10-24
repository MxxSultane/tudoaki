import 'dart:io';
import 'dart:convert';
import 'package:drift/drift.dart' show MigrationStrategy;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/database/schema.dart';
import 'package:tudo_aki/features/academics/academic_rules.dart';
import 'package:tudo_aki/features/academics/study_repository.dart';

void main() {
  group('study sessions', () {
    late TudoAkiDatabase db;
    late TudoAkiRepository repo;
    final t0 = DateTime.utc(2026, 10, 24, 10);
    setUp(() {
      db = TudoAkiDatabase.memory();
      repo = TudoAkiRepository(db);
    });
    tearDown(() => db.close());
    Future<int> study() =>
        repo.saveStudy(title: 'Álgebra', start: t0, minutes: 1);

    test(
      'pause and resume preserve remaining time and reject early completion',
      () async {
        final id = await study();
        await repo.startStudy(id, now: t0);
        final end = (await repo.studyById(id))['focus_end'];
        await repo.startStudy(id, now: t0.add(const Duration(seconds: 2)));
        expect((await repo.studyById(id))['focus_end'], end);
        await expectLater(
          repo.completeStudy(id, now: t0.add(const Duration(seconds: 59))),
          throwsFormatException,
        );
        await repo.pauseStudy(id, now: t0.add(const Duration(seconds: 10)));
        final paused = await repo.studyById(id);
        expect(paused['remaining_seconds'], 50);
        expect(
          focusSecondsRemaining(paused, t0.add(const Duration(hours: 2))),
          50,
        );
        final resume = t0.add(const Duration(hours: 2));
        await repo.startStudy(id, now: resume);
        final running = await repo.studyById(id);
        expect(running['focus_started_at'], t0.toIso8601String());
        expect(
          focusSecondsRemaining(
            running,
            resume.add(const Duration(milliseconds: 49999)),
          ),
          1,
        );
        await repo.completeStudy(
          id,
          now: resume.add(const Duration(seconds: 50)),
        );
        await repo.completeStudy(id, now: resume.add(const Duration(days: 1)));
        expect((await repo.studyById(id))['completed'], 1);
        expect((await repo.all('ExperienceEvents')).single['points'], 15);
        await expectLater(
          repo.startStudy(id, now: resume),
          throwsFormatException,
        );
        await expectLater(
          repo.saveStudy(id: id, title: 'Alterar', start: t0, minutes: 10),
          throwsFormatException,
        );
      },
    );

    test(
      'one active focus session is enforced by repository and SQLite',
      () async {
        final first = await study();
        final second = await study();
        await repo.startStudy(first, now: t0);
        await expectLater(
          repo.startStudy(second, now: t0),
          throwsFormatException,
        );
        await expectLater(
          repo.save('StudySessions', {
            'focus_end': t0.add(const Duration(minutes: 1)).toIso8601String(),
          }, id: second),
          throwsA(isA<Exception>()),
        );
        await repo.pauseStudy(first, now: t0.add(const Duration(seconds: 1)));
        await repo.startStudy(second, now: t0.add(const Duration(seconds: 1)));
        expect((await repo.studyById(second))['focus_end'], isNotNull);
      },
    );

    test(
      'study XP is idempotent and capped at three rewarded sessions per day',
      () async {
        for (var i = 0; i < 4; i++) {
          final id = await study();
          final at = t0.add(Duration(minutes: i * 2));
          await repo.startStudy(id, now: at);
          await repo.completeStudy(id, now: at.add(const Duration(minutes: 1)));
          await repo.completeStudy(id, now: at.add(const Duration(minutes: 2)));
        }
        expect(
          (await repo.all(
            'StudySessions',
          )).where((s) => s['completed'] == 1).length,
          4,
        );
        expect((await repo.all('ExperienceEvents')).length, 3);
        expect(
          (await repo.query(
            'SELECT SUM(points) AS xp FROM ExperienceEvents',
          )).single['xp'],
          45,
        );
        final next = await study();
        await repo.startStudy(next, now: t0.add(const Duration(days: 1)));
        await repo.completeStudy(
          next,
          now: t0.add(const Duration(days: 1, minutes: 1)),
        );
        expect((await repo.all('ExperienceEvents')).length, 4);
      },
    );

    test('disabled gamification records focus without awarding XP', () async {
      await repo.save('UserPreferences', {'gamification': 0}, id: 1);
      final id = await study();
      await repo.startStudy(id, now: t0);
      await repo.completeStudy(id, now: t0.add(const Duration(minutes: 1)));
      expect((await repo.studyById(id))['completed'], 1);
      expect(await repo.all('ExperienceEvents'), isEmpty);
    });

    test(
      'duration validation, editing planned sessions and deleting active sessions',
      () async {
        await expectLater(
          repo.saveStudy(title: '', start: t0, minutes: 25),
          throwsFormatException,
        );
        await expectLater(
          repo.saveStudy(title: 'Teste', start: t0, minutes: 0),
          throwsFormatException,
        );
        await expectLater(
          repo.saveStudy(title: 'Teste', start: t0, minutes: 181),
          throwsFormatException,
        );
        final id = await study();
        await repo.saveStudy(
          id: id,
          title: 'Geometria',
          start: t0,
          minutes: 10,
        );
        expect((await repo.studyById(id))['remaining_seconds'], 600);
        await repo.startStudy(id, now: t0);
        await expectLater(
          repo.saveStudy(id: id, title: 'Editar', start: t0, minutes: 2),
          throwsFormatException,
        );
        await repo.delete('StudySessions', id);
        final next = await study();
        await repo.startStudy(next, now: t0);
        expect((await repo.studyById(next))['focus_end'], isNotNull);
        await expectLater(repo.startStudy(id, now: t0), throwsFormatException);
      },
    );

    test(
      'export and erase include academic planning and active focus',
      () async {
        final subject = await repo.save('Subjects', {'title': 'Matemática'});
        await repo.save('ClassSchedules', {
          'subject_id': subject,
          'weekday': 1,
          'start_minute': 480,
          'end_minute': 540,
          'active_from': '2026-10-24',
        });
        await repo.save('Assessments', {
          'title': 'Teste',
          'at': t0.toIso8601String(),
        });
        final id = await study();
        await repo.startStudy(id, now: t0);
        final exported =
            jsonDecode(await repo.exportJson()) as Map<String, dynamic>;
        expect(exported['schemaVersion'], 4);
        expect((exported['ClassSchedules'] as List).length, 1);
        expect((exported['Assessments'] as List).length, 1);
        expect(
          (exported['StudySessions'] as List).single['focus_end'],
          isNotNull,
        );
        await repo.erase();
        for (final table in [
          'ClassSchedules',
          'Assessments',
          'StudySessions',
          'Subjects',
          'ExperienceEvents',
        ]) {
          expect(await repo.all(table), isEmpty);
        }
        final next = await study();
        await repo.startStudy(next, now: t0);
        expect(next, greaterThan(id));
      },
    );
    test(
      'deleting a subject preserves assessments, study history and tasks',
      () async {
        final subject = await repo.save('Subjects', {'title': 'Matemática'});
        await repo.saveStudy(
          title: 'Álgebra',
          start: t0,
          minutes: 25,
          subjectId: subject,
        );
        await repo.save('Assessments', {
          'title': 'Teste',
          'at': t0.toIso8601String(),
          'subject_id': subject,
        });
        await repo.save('ClassSchedules', {
          'subject_id': subject,
          'weekday': 1,
          'start_minute': 480,
          'end_minute': 540,
          'active_from': '2026-10-24',
        });
        await repo.save('Tasks', {
          'subject_id': subject,
          'title': 'Trabalho',
          'created': t0.toIso8601String(),
        });
        await repo.delete('Subjects', subject);
        expect((await repo.all('StudySessions')).single['subject_id'], isNull);
        expect((await repo.all('Assessments')).single['subject_id'], isNull);
        expect((await repo.all('Tasks')).single['subject_id'], isNull);
        expect(await repo.all('ClassSchedules'), isEmpty);
        expect(await repo.query('PRAGMA foreign_key_check'), isEmpty);
      },
    );
  });

  test(
    'academic occurrences respect term dates and join classes, exams and study',
    () {
      final data = {for (final table in exportTables) table: <DataRowMap>[]};
      data['Subjects']!.add({'id': 1, 'title': 'Matemática'});
      final schedule = {
        'id': 1,
        'subject_id': 1,
        'weekday': 1,
        'start_minute': 540,
        'end_minute': 600,
        'active_from': '2026-10-26',
        'active_until': '2026-10-30',
      };
      data['ClassSchedules']!.add(schedule);
      data['Assessments']!.add({
        'id': 1,
        'title': 'Álgebra',
        'kind': 'Exame',
        'at': '2026-10-26T09:30:00',
        'minutes': 60,
      });
      data['StudySessions']!.add({
        'id': 1,
        'title': 'Rever álgebra',
        'start': '2026-10-26T11:00:00',
        'minutes': 25,
      });
      final day = DateTime(2026, 10, 26);
      final events = academicEventsForDay(data, day);
      expect(events.map((e) => e['academic_kind']), [
        'Aula',
        'Avaliação',
        'Estudo',
      ]);
      expect(occurrenceOn(events.first, day), DateTime(2026, 10, 26, 9));
      expect(classOn(schedule, DateTime(2026, 10, 19)), isNull);
      expect(classOn(schedule, DateTime(2026, 10, 27)), isNull);
      expect(classOn(schedule, DateTime(2026, 11, 2)), isNull);
      expect(academicEventsForDay(data, DateTime(2026, 11, 2)), isEmpty);
      expect(clockLabel(1440), '24:00');
    },
  );

  test(
    'v2 migrates to v4 and a running deadline survives database reopening',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'tudo-aki-study-migration-',
      );
      final file = File('${directory.path}/db.sqlite');
      final legacy = LegacyV2Database(NativeDatabase(file));
      final old = TudoAkiRepository(legacy);
      final subject = await old.save('Subjects', {'title': 'Matemática'});
      final planned = await old.save('StudySessions', {
        'subject_id': subject,
        'start': '2026-10-24T10:00:00',
        'minutes': 25,
      });
      final completed = await old.save('StudySessions', {
        'subject_id': subject,
        'start': '2026-10-23T10:00:00',
        'minutes': 10,
        'completed': 1,
      });
      await old.save('FinancialTransactions', {
        'title': 'Poupança',
        'kind': 'saving',
        'amount_cents': 125050,
        'day': '2026-10-24',
      });
      await legacy.close();
      final current = TudoAkiDatabase(NativeDatabase(file));
      final repo = TudoAkiRepository(current);
      final now = DateTime.utc(2026, 10, 24, 10);
      try {
        expect(
          (await repo.query('PRAGMA user_version')).single.values.single,
          4,
        );
        expect((await repo.studyById(planned))['remaining_seconds'], 1500);
        expect((await repo.studyById(completed))['remaining_seconds'], 0);
        expect((await repo.studyById(completed))['completed'], 1);
        expect(
          (await repo.all('FinancialTransactions')).single['amount_cents'],
          125050,
        );
        await repo.startStudy(planned, now: now);
      } finally {
        await current.close();
      }
      final reopened = TudoAkiDatabase(NativeDatabase(file));
      try {
        final data = TudoAkiRepository(reopened);
        final row = await data.studyById(planned);
        expect(
          focusSecondsRemaining(row, now.add(const Duration(seconds: 20))),
          1480,
        );
        await data.pauseStudy(
          planned,
          now: now.add(const Duration(seconds: 20)),
        );
        expect((await data.studyById(planned))['remaining_seconds'], 1480);
        expect(await data.query('PRAGMA foreign_key_check'), isEmpty);
      } finally {
        await reopened.close();
      }
      final again = TudoAkiDatabase(NativeDatabase(file));
      try {
        final paused = await TudoAkiRepository(again).studyById(planned);
        expect(
          focusSecondsRemaining(paused, now.add(const Duration(days: 2))),
          1480,
        );
        expect(paused['focus_end'], isNull);
      } finally {
        await again.close();
        await directory.delete(recursive: true);
      }
    },
  );
}

class LegacyV2Database extends TudoAkiDatabase {
  LegacyV2Database(super.executor);
  @override
  int get schemaVersion => 2;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {
      for (final sql in [...schemaV1, ...schemaV2]) {
        await customStatement(sql);
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
