import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/database/database.dart';
import 'progress_activity.dart';
import 'progress_panel.dart' show progressClockProvider;

const progressTables = [
  'UserPreferences',
  'Tasks',
  'Habits',
  'HabitCompletions',
  'StudySessions',
  'Goals',
  'GoalProgress',
  'ExperienceEvents',
  'Achievements',
];

/// Does not watch dataProvider: that shared loader synchronizes achievements.
final progressReadProvider =
    FutureProvider.autoDispose<Map<String, List<DataRowMap>>>((ref) async {
      final repo = ref.watch(repositoryProvider);
      return {for (final table in progressTables) table: await repo.all(table)};
    });
final progressViewProvider = Provider.autoDispose<AsyncValue<ProgressView>>((
  ref,
) {
  final now = ref.watch(progressClockProvider)();
  return ref
      .watch(progressReadProvider)
      .whenData((data) => ProgressView(data, now));
});
