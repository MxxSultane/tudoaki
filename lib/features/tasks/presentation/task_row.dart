import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../core/database/database.dart';
import '../../../core/widgets/workspace_page.dart';
import '../../forms.dart';

class TaskRow extends ConsumerStatefulWidget {
  const TaskRow({required this.task, this.subtitle, super.key});
  final DataRowMap task;
  final String? subtitle;
  @override
  ConsumerState<TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends ConsumerState<TaskRow> {
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final done = task['completed'] == 1;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Semantics(
        label: 'Concluir ${task['title']}',
        child: Checkbox(
          value: done,
          onChanged: busy
              ? null
              : (value) async {
                  setState(() => busy = true);
                  final container = ProviderScope.containerOf(
                    context,
                    listen: false,
                  );
                  await applyWorkspace(context, ref, () async {
                    await container
                        .read(repositoryProvider)
                        .taskDone(task['id'] as int, value!);
                    HapticFeedback.selectionClick();
                    if (task['reminder'] == 1) {
                      try {
                        final reminders = container.read(remindersProvider);
                        if (value) {
                          await reminders.cancel(task['id'] as int);
                        } else if (task['due'] != null) {
                          await reminders.schedule(
                            task['id'] as int,
                            task['title'] as String,
                            DateTime.parse(task['due'] as String),
                          );
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Tarefa guardada; verifica o lembrete.',
                              ),
                            ),
                          );
                        }
                      }
                    }
                  });
                  if (mounted) setState(() => busy = false);
                },
        ),
      ),
      title: Text(
        task['title'] as String,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          decoration: done ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        widget.subtitle ??
            (task['due'] == null
                ? 'Sem data'
                : DateFormat(
                    'dd MMM · HH:mm',
                    'pt',
                  ).format(DateTime.parse(task['due'] as String))),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: () => showEditor(context, 'Tarefa', existing: task, compact: true),
    );
  }
}
