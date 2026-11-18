import '../../core/database/database.dart';
import 'progress_rules.dart';

/// Presentation projection only. No new persisted event or business operation.
enum ProgressKind { task, habit, study, goal }

final _progressDatePattern = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?(?:Z|[+-]\d{2}:?\d{2})?)?$',
);

DateTime? progressDate(Object? raw) {
  if (raw is! String) return null;
  final match = _progressDatePattern.firstMatch(raw);
  if (match == null) return null;
  final y = int.parse(match[1]!),
      m = int.parse(match[2]!),
      d = int.parse(match[3]!);
  final civil = DateTime(y, m, d);
  if (civil.year != y || civil.month != m || civil.day != d) return null;
  if (int.parse(match[4] ?? '0') > 23 ||
      int.parse(match[5] ?? '0') > 59 ||
      int.parse(match[6] ?? '0') > 59) {
    return null;
  }
  final parsed = DateTime.tryParse(raw);
  return parsed == null ? null : maputoCivil(parsed);
}

int progressTimeKey(DateTime date) => DateTime.utc(
  date.year,
  date.month,
  date.day,
  date.hour,
  date.minute,
  date.second,
  date.millisecond,
  date.microsecond,
).microsecondsSinceEpoch;
String progressNumber(Object? value) => value is num && value.isFinite
    ? value.toString().replaceAll('.', ',')
    : 'Valor não disponível';

class ProgressEntry {
  ProgressEntry({
    required this.key,
    required this.kind,
    required this.title,
    required this.detail,
    required this.at,
    required this.dateOnly,
    this.route,
    this.origin,
  });
  final String key, title, detail;
  final ProgressKind kind;
  final DateTime? at;
  final bool dateOnly;
  final String? route, origin;
  late final String day = at == null ? '' : dayKey(at!);
}

class ProgressView {
  ProgressView(this.data, DateTime now) {
    final goals = {for (final r in data['Goals']!) r['id']: r};
    final habits = {for (final r in data['Habits']!) r['id']: r};
    void add(
      String table,
      DataRowMap row,
      ProgressKind kind,
      String title,
      String detail,
      String field,
      String? route,
      String? origin,
    ) {
      final raw = row[field];
      final at = progressDate(raw);
      final entry = ProgressEntry(
        key: '$table:${row['id']}',
        kind: kind,
        title: title,
        detail: detail,
        at: at,
        dateOnly: raw is String && raw.length == 10,
        route: route,
        origin: origin,
      );
      if (at == null) {
        undated.add(entry);
      } else if (entry.day.compareTo(dayKey(maputoCivil(now))) > 0) {
        future.add(entry);
      } else {
        history.add(entry);
      }
    }

    for (final r in data['Tasks']!.where((r) => r['completed'] == 1)) {
      add(
        'Tasks',
        r,
        ProgressKind.task,
        r['title'] as String? ?? 'Tarefa sem título',
        'Tarefa concluída',
        'completed_at',
        '/tasks',
        'Ver tarefas',
      );
    }
    for (final r in data['HabitCompletions']!) {
      final h = habits[r['habit_id']];
      add(
        'HabitCompletions',
        r,
        ProgressKind.habit,
        h?['title'] as String? ?? 'Hábito indisponível',
        'Hábito registado',
        'day',
        h == null ? null : '/habits',
        h == null ? null : 'Ver hábitos',
      );
    }
    for (final r in data['StudySessions']!.where((r) => r['completed'] == 1)) {
      add(
        'StudySessions',
        r,
        ProgressKind.study,
        r['title'] as String? ?? 'Sessão de estudo',
        'Sessão concluída · ${r['minutes']} min',
        'completed_at',
        '/academics',
        'Ver estudos',
      );
    }
    for (final r in data['GoalProgress']!) {
      final g = goals[r['goal_id']];
      add(
        'GoalProgress',
        r,
        ProgressKind.goal,
        g?['title'] as String? ?? 'Meta indisponível',
        'Valor registado: ${progressNumber(r['value'])}',
        'recorded_at',
        g == null ? null : '/goal/${r['goal_id']}',
        g == null ? null : 'Ver meta',
      );
    }
    history.sort((a, b) {
      final day = b.day.compareTo(a.day);
      if (day != 0) return day;
      if (a.dateOnly != b.dateOnly) return a.dateOnly ? 1 : -1;
      int time(ProgressEntry e) =>
          e.at!.hour * 3600000000 +
          e.at!.minute * 60000000 +
          e.at!.second * 1000000 +
          e.at!.millisecond * 1000 +
          e.at!.microsecond;
      final timed = time(b).compareTo(time(a));
      return timed != 0 ? timed : a.key.compareTo(b.key);
    });
    final today = maputoCivil(now);
    final start = dayKey(DateTime(today.year, today.month, today.day - 6));
    recent = history
        .where((e) => e.day.compareTo(start) >= 0)
        .toList(growable: false);
  }
  final Map<String, List<DataRowMap>> data;
  final history = <ProgressEntry>[],
      undated = <ProgressEntry>[],
      future = <ProgressEntry>[];
  late final List<ProgressEntry> recent;
  bool get gamification => data['UserPreferences']!.single['gamification'] == 1;
}
