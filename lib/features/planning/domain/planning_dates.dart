import '../../../core/database/database.dart';

/// Only an explicit save uses this value. Preserve the original string when
/// day/time are unchanged, including UTC notation and subsecond precision.
String scheduledTaskDue(String? original, DateTime day, {DateTime? time}) {
  final before = DateTime.tryParse(original ?? '');
  final local = before?.toLocal();
  if (local != null &&
      dayKey(local) == dayKey(day) &&
      (time == null && isDateOnly(original) ||
          time != null &&
              !isDateOnly(original) &&
              time.hour == local.hour &&
              time.minute == local.minute &&
              time.second == local.second &&
              time.millisecond == local.millisecond &&
              time.microsecond == local.microsecond)) {
    return original!;
  }
  if (time == null) return dayKey(day);
  final at = DateTime(
    day.year,
    day.month,
    day.day,
    time.hour,
    time.minute,
    time.second,
    time.millisecond,
    time.microsecond,
  );
  return (before?.isUtc == true ? at.toUtc() : at).toIso8601String();
}
