import '../../core/database/database.dart';

const achievementCatalog = [
  (
    code: 'first_task',
    title: 'Primeiro passo',
    detail: 'Concluir uma tarefa com XP.',
    prefix: 'task:',
    target: 1,
  ),
  (
    code: 'ten_tasks',
    title: 'Passo a passo',
    detail: 'Concluir dez tarefas distintas com XP.',
    prefix: 'task:',
    target: 10,
  ),
  (
    code: 'seven_habits',
    title: 'Pequenas rotinas',
    detail: 'Somar sete registos de hábitos com XP, sem exigir dias seguidos.',
    prefix: 'habit:',
    target: 7,
  ),
  (
    code: 'three_studies',
    title: 'Tempo para aprender',
    detail: 'Concluir três sessões de estudo com XP.',
    prefix: 'study:',
    target: 3,
  ),
];

extension ProgressRepository on TudoAkiRepository {
  Future<void> syncAchievements() => db.transaction(() async {
    if ((await all('UserPreferences')).single['gamification'] != 1) return;
    final events = await all('ExperienceEvents');
    for (final achievement in achievementCatalog) {
      final dates =
          events
              .where(
                (e) => (e['source'] as String).startsWith(achievement.prefix),
              )
              .map((e) => DateTime.parse(e['created'] as String))
              .toList()
            ..sort();
      if (dates.length >= achievement.target) {
        await write(
          'INSERT OR IGNORE INTO Achievements(code, unlocked_at) VALUES(?,?)',
          [achievement.code, dates[achievement.target - 1].toIso8601String()],
        );
      }
    }
  });
}

// UTC timestamps are displayed in Maputo; timestamps without an offset already
// represent a local civil date in the existing storage format.
DateTime maputoCivil(DateTime date) =>
    date.isUtc ? date.add(const Duration(hours: 2)) : date;

List<({DateTime day, int tasks, int habits, int studies})> activityWeek(
  Map<String, List<DataRowMap>> data,
  DateTime now,
) {
  final today = maputoCivil(now);
  int count(String table, String field, DateTime day) =>
      data[table]!.where((row) {
        if (table != 'HabitCompletions' && row['completed'] != 1) return false;
        final date = DateTime.tryParse(row[field] as String? ?? '');
        return date != null && dayKey(maputoCivil(date)) == dayKey(day);
      }).length;
  return List.generate(7, (index) {
    final day = DateTime(today.year, today.month, today.day - 6 + index);
    return (
      day: day,
      tasks: count('Tasks', 'completed_at', day),
      habits: count('HabitCompletions', 'day', day),
      studies: count('StudySessions', 'completed_at', day),
    );
  });
}
