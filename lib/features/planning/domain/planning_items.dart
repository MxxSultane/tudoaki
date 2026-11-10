import '../../../core/database/database.dart';
import '../../agenda/domain/agenda_items.dart';
import '../../agenda/domain/today_content.dart';

/// Existing event occurrences plus a local-civil projection of the same Tasks.
/// UTC task strings remain untouched, as in the new Hoje.
List<AgendaItem> planningItemsForDay(WorkspaceSnapshot data, DateTime day) {
  final items = agendaItemsForDay(
    data,
    day,
  ).where((item) => !item.task).toList();
  for (final row in data['Tasks']!) {
    final due = localTaskDate(row['due'] as String?);
    if (due != null && dayKey(due) == dayKey(day)) {
      items.add(AgendaItem(row: row, start: due, task: true));
    }
  }
  items.sort((a, b) {
    final time = a.start.compareTo(b.start);
    return time != 0
        ? time
        : (a.row['title'] as String).compareTo(b.row['title'] as String);
  });
  return items;
}
