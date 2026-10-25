import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/workspace_page.dart';
import '../../../core/widgets/skeleton_page.dart';
import '../domain/tasks_cubit.dart';
import 'task_row.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<TasksCubit, bool>(
    builder: (context, completed) => WorkspaceData(
      builder: (data) {
        final tasks =
            data['Tasks']!
                .where((t) => (t['completed'] == 1) == completed)
                .toList()
              ..sort((a, b) {
                final important = (b['important'] as int).compareTo(
                  a['important'] as int,
                );
                if (important != 0) return important;
                final priority = (b['priority'] as int).compareTo(
                  a['priority'] as int,
                );
                return priority != 0
                    ? priority
                    : (a['due'] as String? ?? '9999').compareTo(
                        b['due'] as String? ?? '9999',
                      );
              });
        return WorkspacePage(
          title: 'Tarefas',
          description: 'Uma coisa de cada vez.',
          children: [
            Wrap(
              spacing: 16,
              children: [
                for (final value in [false, true])
                  TextButton(
                    onPressed: () =>
                        context.read<TasksCubit>().completed(value),
                    child: Text(
                      value ? 'Concluídas' : 'Pendentes',
                      style: TextStyle(
                        fontWeight: value == completed
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (tasks.isEmpty)
              Text(
                completed
                    ? 'Ainda não há tarefas concluídas.'
                    : 'Ainda não tens tarefas. Usa o +.',
              ),
            if (tasks.isNotEmpty)
              InsetGroup(
                children: [
                  for (final task in tasks)
                    TaskRow(key: ValueKey('task-${task['id']}'), task: task),
                ],
              ),
          ],
        );
      },
    ),
  );
}
