import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/database/database.dart';
import '../../../core/widgets/workspace_page.dart';
import '../../tasks/presentation/task_row.dart';
import '../domain/agenda_items.dart';
import 'package:intl/intl.dart';

class DailySummary extends ConsumerWidget {
  const DailySummary({required this.data, required this.today, super.key});
  final WorkspaceSnapshot data;
  final DateTime today;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priorities =
        data['Tasks']!
            .where(
              (t) =>
                  t['completed'] == 0 &&
                  t['due'] != null &&
                  dayKey(
                        DateTime.parse(t['due'] as String),
                      ).compareTo(dayKey(today)) <=
                      0,
            )
            .toList()
          ..sort(
            (a, b) => ((b['important'] as int) * 3 + (b['priority'] as int))
                .compareTo(
                  (a['important'] as int) * 3 + (a['priority'] as int),
                ),
          );
    final habits = data['Habits']!
        .where(
          (h) =>
              h['paused'] == 0 &&
              (h['weekdays'] as String).split(',').contains('${today.weekday}'),
        )
        .toList();
    final next = agendaItemsForDay(
      data,
      today,
    ).where((item) => !item.task && !item.start.isBefore(today)).firstOrNull;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('O meu dia'),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (next != null) ...[
          const Text(
            'Próximo compromisso',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Text('${DateFormat.Hm().format(next.start)} · ${next.row['title']}'),
          const SizedBox(height: 24),
        ],
        const Text(
          'Três prioridades',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        if (priorities.isEmpty)
          const Text('Sem tarefas programadas para hoje.'),
        for (final task in priorities.take(3)) TaskRow(task: task),
        const SizedBox(height: 16),
        const Text(
          'Rotinas de hoje',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        if (habits.isEmpty)
          TextButton(
            onPressed: () => context.push('/habits'),
            child: const Text('Definir uma rotina'),
          ),
        for (final habit in habits)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(habit['title'] as String),
            value: data['HabitCompletions']!.any(
              (c) => c['habit_id'] == habit['id'] && c['day'] == dayKey(today),
            ),
            onChanged: (_) => applyWorkspace(
              context,
              ref,
              () => ref
                  .read(repositoryProvider)
                  .toggleHabit(habit['id'] as int, today),
            ),
          ),
        const SizedBox(height: 16),
        for (final goal
            in data['Goals']!.where((g) => g['status'] == 'active').take(2))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(goal['title'] as String),
            subtitle: Text(
              '${goal['current']} / ${goal['target']} ${goal['unit']}',
            ),
            onTap: () => context.push('/goal/${goal['id']}'),
          ),
        if (data['StudySessions']!.any(
          (s) => s['focus_started_at'] != null && s['completed'] == 0,
        ))
          TextButton(
            onPressed: () => context.push('/academics'),
            child: const Text('Retomar estudo'),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
