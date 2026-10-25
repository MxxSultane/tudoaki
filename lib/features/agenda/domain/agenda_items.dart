import '../../../core/database/database.dart';
import '../../academics/academic_rules.dart';

class AgendaItem {
  const AgendaItem({
    required this.row,
    required this.start,
    this.end,
    this.task = false,
  });
  final DataRowMap row;
  final DateTime start;
  final DateTime? end;
  final bool task;
  bool get allDay => task && isDateOnly(row['due'] as String?);
}

List<AgendaItem> agendaItemsForDay(WorkspaceSnapshot data, DateTime day) {
  final items = <AgendaItem>[];
  for (final event in [
    ...data['CalendarEvents']!,
    ...academicEventsForDay(data, day),
  ]) {
    final start = occurrenceOn(event, day);
    if (start == null) continue;
    final duration = DateTime.parse(
      event['end'] as String,
    ).difference(DateTime.parse(event['start'] as String));
    items.add(AgendaItem(row: event, start: start, end: start.add(duration)));
  }
  for (final task in data['Tasks']!) {
    final due = DateTime.tryParse(task['due'] as String? ?? '');
    if (due != null && dayKey(due) == dayKey(day)) {
      items.add(AgendaItem(row: task, start: due, task: true));
    }
  }
  items.sort((a, b) {
    final order = a.start.compareTo(b.start);
    return order != 0
        ? order
        : (a.row['title'] as String).compareTo(b.row['title'] as String);
  });
  return items;
}

bool agendaConflict(AgendaItem item, List<AgendaItem> items) => items.any((
  other,
) {
  if (identical(item, other) || item.allDay || other.allDay) return false;
  if (item.task && item.row['completed'] == 1 ||
      other.task && other.row['completed'] == 1) {
    return false;
  }
  if (item.task && other.task) return item.start == other.start;
  if (item.task) {
    return !item.start.isBefore(other.start) && item.start.isBefore(other.end!);
  }
  if (other.task) {
    return !other.start.isBefore(item.start) && other.start.isBefore(item.end!);
  }
  return item.start.isBefore(other.end!) && item.end!.isAfter(other.start);
});
