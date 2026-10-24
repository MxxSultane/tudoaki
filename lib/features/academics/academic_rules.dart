import '../../core/database/database.dart';

const studyExperiencePoints = 15;
const dailyRewardedStudySessions = 3;

int focusSecondsRemaining(DataRowMap session, DateTime now) {
  if (session['completed'] == 1) return 0;
  final end = session['focus_end'] as String?;
  if (end == null) return session['remaining_seconds'] as int;
  final milliseconds = DateTime.parse(end).difference(now).inMilliseconds;
  return milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();
}

String clockLabel(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
const weekdayLabels = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];

/// Civil recurrence bounded by the school term; no UTC-duration arithmetic.
DateTime? classOn(DataRowMap schedule, DateTime day) {
  final key = dayKey(day);
  if (schedule['weekday'] != day.weekday ||
      key.compareTo(schedule['active_from'] as String) < 0) {
    return null;
  }
  final until = schedule['active_until'] as String?;
  if (until != null && key.compareTo(until) > 0) return null;
  final minute = schedule['start_minute'] as int;
  return DateTime(day.year, day.month, day.day, minute ~/ 60, minute % 60);
}

/// Event-shaped read models join academic planning to the existing agenda.
List<DataRowMap> academicEventsForDay(
  Map<String, List<DataRowMap>> data,
  DateTime day,
) {
  final subjects = {for (final s in data['Subjects']!) s['id']: s['title']};
  final events = <DataRowMap>[];
  void add(
    String kind,
    DataRowMap row,
    String title,
    DateTime start,
    int minutes,
  ) {
    if (dayKey(start) != dayKey(day)) return;
    events.add({
      'id': row['id'],
      'title': title,
      'start': start.toIso8601String(),
      'end': start.add(Duration(minutes: minutes)).toIso8601String(),
      'recurrence': 'none',
      'academic_kind': kind,
      'academic_row': row,
    });
  }

  for (final row in data['ClassSchedules']!) {
    final at = classOn(row, day);
    if (at != null) {
      add(
        'Aula',
        row,
        'Aula · ${subjects[row['subject_id']]}',
        at,
        (row['end_minute'] as int) - (row['start_minute'] as int),
      );
    }
  }
  for (final row in data['Assessments']!) {
    add(
      'Avaliação',
      row,
      '${row['kind']} · ${row['title']}',
      DateTime.parse(row['at'] as String).toLocal(),
      row['minutes'] as int,
    );
  }
  for (final row in data['StudySessions']!) {
    add(
      'Estudo',
      row,
      'Estudo · ${row['title']}',
      DateTime.parse(row['start'] as String).toLocal(),
      row['minutes'] as int,
    );
  }
  return events;
}
