import '../../../core/database/database.dart';
import '../../../core/notifications/reminders.dart';

enum TaskReminderFailure { unavailable, failed }

class TaskWriteResult {
  const TaskWriteResult(this.id, this.reminderFailure);
  final int id;
  final TaskReminderFailure? reminderFailure;
}

/// Coordinates existing SQLite operations and Android reminders, without
/// owning another task store. UI-specific messages remain with the callers.
class TaskOperations {
  TaskOperations(this.repository, this.reminders, {required this.refresh});
  final TudoAkiRepository repository;
  final Reminders reminders;
  final void Function() refresh;

  Future<DataRowMap> _task(int id) async =>
      (await repository.all(
        'Tasks',
      )).where((row) => row['id'] == id).firstOrNull ??
      {};

  Future<TaskWriteResult> create(
    DataRowMap fields, {
    bool? reconcileReminders,
  }) => _save(
    {'created': DateTime.now().toIso8601String(), ...fields},
    previous: const {},
    reconcileReminders: reconcileReminders,
  );

  Future<TaskWriteResult> edit(
    int id,
    DataRowMap fields, {
    DataRowMap? previous,
    bool? reconcileReminders,
  }) async => _save(
    fields,
    id: id,
    previous: previous ?? await _task(id),
    reconcileReminders: reconcileReminders,
  );

  Future<TaskWriteResult> reschedule(int id, String? due) async {
    final previous = await _task(id);
    return edit(id, {
      'due': due,
      if (due == null || isDateOnly(due)) 'reminder': 0,
    }, previous: previous);
  }

  Future<TaskWriteResult> _save(
    DataRowMap fields, {
    int? id,
    required DataRowMap previous,
    bool? reconcileReminders,
  }) async {
    final saved = await repository.save('Tasks', fields, id: id);
    final effective = {...previous, ...fields};
    TaskReminderFailure? failure;
    if (reconcileReminders ??
        (effective['reminder'] == 1 || previous['reminder'] == 1)) {
      try {
        await reminders.cancel(saved);
        final due = effective['due'] as String?;
        if (effective['reminder'] == 1 &&
            previous['completed'] != 1 &&
            due != null &&
            !isDateOnly(due) &&
            !await reminders.schedule(
              saved,
              effective['title'] as String,
              DateTime.parse(due),
            )) {
          failure = TaskReminderFailure.unavailable;
        }
      } catch (_) {
        // Saving succeeds even when the platform reminder is unavailable.
        failure = TaskReminderFailure.failed;
      }
    }
    refresh();
    return TaskWriteResult(saved, failure);
  }

  Future<TaskReminderFailure?> setCompleted(
    DataRowMap task,
    bool done, {
    void Function()? onPersisted,
    bool refreshConsumers = true,
  }) async {
    await repository.taskDone(task['id'] as int, done);
    onPersisted?.call();
    TaskReminderFailure? failure;
    if (task['reminder'] == 1) {
      try {
        if (done) {
          await reminders.cancel(task['id'] as int);
        } else if (task['due'] != null &&
            !await reminders.schedule(
              task['id'] as int,
              task['title'] as String,
              DateTime.parse(task['due'] as String),
            )) {
          failure = TaskReminderFailure.unavailable;
        }
      } catch (_) {
        failure = TaskReminderFailure.failed;
      }
    }
    // Legacy action wrappers already refresh after showing their warning.
    if (refreshConsumers) refresh();
    return failure;
  }

  Future<void> delete(DataRowMap task) async {
    if (task['reminder'] == 1) {
      // Preserve the existing ordering: cancellation failure prevents deletion.
      await reminders.cancel(task['id'] as int);
    }
    await repository.delete('Tasks', task['id'] as int);
    refresh();
  }
}
