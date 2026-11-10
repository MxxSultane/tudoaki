import 'package:flutter_test/flutter_test.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/features/planning/domain/planning_dates.dart';
import 'package:tudo_aki/features/planning/domain/planning_items.dart';
import 'support/today_fixture.dart';

void main() {
  test('date-only, null and explicit midnight stay distinct', () {
    final day = DateTime(2026, 11, 11);
    expect(scheduledTaskDue(null, day), '2026-11-11');
    expect(scheduledTaskDue('2026-11-10', day), '2026-11-11');
    expect(
      scheduledTaskDue(
        '2026-11-10T00:00:00',
        day,
        time: DateTime(2026, 11, 10),
      ),
      '2026-11-11T00:00:00.000',
    );
  });

  test('unchanged UTC or offset timestamp is preserved byte for byte', () {
    for (final raw in [
      '2026-11-10T12:34:56.123456Z',
      '2026-11-10T12:34:56.123+02:00',
    ]) {
      final local = DateTime.parse(raw).toLocal();
      expect(scheduledTaskDue(raw, local, time: local), raw);
    }
  });

  test(
    'moving a timed task keeps local time and subsecond precision; explicit removal drops time',
    () {
      const raw = '2026-11-10T12:34:56.123456Z';
      final time = DateTime.parse(raw).toLocal();
      final target = DateTime(time.year, time.month, time.day + 1);
      final changed = DateTime.parse(
        scheduledTaskDue(raw, target, time: time),
      ).toLocal();
      expect(dayKey(changed), dayKey(target));
      expect(changed.hour, time.hour);
      expect(changed.minute, time.minute);
      expect(changed.second, time.second);
      expect(changed.millisecond, time.millisecond);
      expect(changed.microsecond, time.microsecond);
      expect(scheduledTaskDue(raw, target), dayKey(target));
    },
  );

  test(
    'planning projects UTC tasks into local civil day without changing rows or duplicating academics',
    () async {
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = TudoAkiRepository(db);
      final day = DateTime(2026, 11, 10);
      final task = await todayTask(
        repo,
        'UTC',
        DateTime(2026, 11, 10, 0, 15).toUtc().toIso8601String(),
      );
      final subject = await repo.save('Subjects', {'title': 'História'});
      await repo.save('ClassSchedules', {
        'subject_id': subject,
        'weekday': day.weekday,
        'start_minute': 600,
        'end_minute': 660,
        'active_from': '2026-01-01',
      });
      await todayEvent(repo, 'Reunião', day, 10);
      final before = await todaySnapshot(repo);
      final items = planningItemsForDay(before, day);
      expect(items.where((i) => i.task).single.row['id'], task);
      expect(items.where((i) => !i.task), hasLength(2));
      expect(
        items.where((i) => i.row['academic_kind'] == 'Aula'),
        hasLength(1),
      );
      expect(await todaySnapshot(repo), before);
    },
  );
}
