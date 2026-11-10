import '../../../core/database/database.dart';
import 'agenda_items.dart';

/// Read-only projections of the shared snapshot. No task or academic copies.
class TodayContent {
  TodayContent(WorkspaceSnapshot data, DateTime now) {
    final today = dayKey(now);
    for (final task in data['Tasks']!) {
      final due = localTaskDate(task['due'] as String?);
      if (task['completed'] == 1) {
        final completed = localTaskDate(task['completed_at'] as String?);
        if (completed != null && dayKey(completed) == today) {
          completedToday.add(task);
        }
      } else if (due == null) {
        undatedCount++;
      } else if (dayKey(due) == today) {
        pending.add(task);
      } else if (dayKey(due).compareTo(today) < 0) {
        previous.add(task);
      }
    }
    pending.sort(_taskOrder);
    previous.sort((a, b) {
      final date = localTaskDate(
        a['due'] as String,
      )!.compareTo(localTaskDate(b['due'] as String)!);
      return date != 0 ? date : _taskOrder(a, b);
    });
    completedToday.sort(
      (a, b) => localTaskDate(
        b['completed_at'] as String,
      )!.compareTo(localTaskDate(a['completed_at'] as String)!),
    );
    commitments = agendaItemsForDay(
      data,
      now,
    ).where((item) => !item.task).toList();
    upcoming = commitments
        .where((item) => !item.start.isBefore(now) || item.end!.isAfter(now))
        .take(2)
        .toList();
    habits = data['Habits']!
        .where(
          (habit) =>
              habit['paused'] == 0 &&
              (habit['weekdays'] as String)
                  .split(',')
                  .contains('${now.weekday}'),
        )
        .take(3)
        .toList();
  }

  final pending = <DataRowMap>[];
  final previous = <DataRowMap>[];
  final completedToday = <DataRowMap>[];
  int undatedCount = 0;
  late final List<AgendaItem> commitments, upcoming;
  late final List<DataRowMap> habits;
}

DateTime? localTaskDate(String? value) =>
    DateTime.tryParse(value ?? '')?.toLocal();

int _taskOrder(DataRowMap a, DataRowMap b) {
  for (final field in ['important', 'priority']) {
    final order = (b[field] as int).compareTo(a[field] as int);
    if (order != 0) return order;
  }
  final first = isDateOnly(a['due'] as String?);
  final second = isDateOnly(b['due'] as String?);
  if (first != second) return first ? 1 : -1;
  final time = localTaskDate(
    a['due'] as String,
  )!.compareTo(localTaskDate(b['due'] as String)!);
  return time != 0 ? time : (a['id'] as int).compareTo(b['id'] as int);
}
