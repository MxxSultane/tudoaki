import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database.dart';
import '../../../core/widgets/workspace_page.dart';
import '../../../core/widgets/skeleton_page.dart';
import '../../forms.dart';
import '../../academics/academic_editor.dart';
import '../../tasks/presentation/task_row.dart';
import '../domain/agenda_cubit.dart';
import '../domain/agenda_items.dart';
import 'daily_summary.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});
  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) => BlocBuilder<AgendaCubit, AgendaSelection>(
    builder: (context, selection) => WorkspaceData(
      builder: (data) {
        final day = selection.day;
        final today = ref.watch(workspaceClockProvider)();
        final sameDay = dayKey(today) == dayKey(day);
        final first = selection.mode == 'Mês'
            ? DateTime(day.year, day.month, 1)
            : selection.mode == 'Semana'
            ? DateTime(day.year, day.month, day.day - day.weekday + 1)
            : day;
        final count = selection.mode == 'Mês'
            ? DateTime(day.year, day.month + 1, 0).day
            : selection.mode == 'Semana'
            ? 7
            : 1;
        final dates = List.generate(
          count,
          (index) => DateTime(first.year, first.month, first.day + index),
        );
        final untimed = data['Tasks']!
            .where((t) => t['due'] == null && t['completed'] == 0)
            .toList();
        return WorkspacePage(
          title: sameDay && selection.mode == 'Dia' ? 'Hoje' : 'Agenda',
          description: DateFormat('EEEE, d MMMM', 'pt').format(day),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Período anterior',
                  onPressed: () => context.read<AgendaCubit>().move(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final result = await showDatePicker(
                        context: context,
                        initialDate: day,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100, 12, 31),
                      );
                      if (result != null && context.mounted) {
                        context.read<AgendaCubit>().select(result);
                      }
                    },
                    child: Text(DateFormat('d MMM yyyy', 'pt').format(day)),
                  ),
                ),
                IconButton(
                  tooltip: 'Período seguinte',
                  onPressed: () => context.read<AgendaCubit>().move(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Wrap(
              spacing: 16,
              children: [
                for (final mode in ['Dia', 'Semana', 'Mês'])
                  TextButton(
                    onPressed: () => context.read<AgendaCubit>().mode(mode),
                    child: Text(
                      mode,
                      style: TextStyle(
                        fontWeight: mode == selection.mode
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _WeekStrip(day: day),
            const SizedBox(height: 24),
            if (sameDay && selection.mode == 'Dia') ...[
              DailySummary(data: data, today: today),
              const SizedBox(height: 24),
            ],
            if (dates.every((date) => agendaItemsForDay(data, date).isEmpty))
              const Text('Sem compromissos. Usa o + para planear.'),
            for (final date in dates)
              Builder(
                builder: (context) {
                  final items = agendaItemsForDay(data, date);
                  if (items.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (count > 1) ...[
                          Text(
                            DateFormat('EEE, d MMM', 'pt').format(date),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                        ],
                        InsetGroup(
                          children: [
                            for (final item in items)
                              item.task
                                  ? TaskRow(
                                      key: ValueKey(
                                        'agenda-task-${item.row['id']}-${dayKey(date)}',
                                      ),
                                      task: item.row,
                                      subtitle:
                                          '${DateFormat.Hm().format(item.start)}${agendaConflict(item, items) ? ' · Conflito de horário' : ''}',
                                    )
                                  : ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(item.row['title'] as String),
                                      subtitle: Text(
                                        '${DateFormat.Hm().format(item.start)} – ${DateFormat.Hm().format(item.end!)}${agendaConflict(item, items) ? '\nConflito de horário' : ''}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      onTap: () {
                                        final kind =
                                            item.row['academic_kind']
                                                as String?;
                                        if (kind == 'Estudo') {
                                          context.push('/academics');
                                        } else if (kind != null) {
                                          showAcademicEditor(
                                            context,
                                            kind,
                                            existing:
                                                item.row['academic_row']
                                                    as DataRowMap,
                                          );
                                        } else {
                                          showEditor(
                                            context,
                                            'Evento',
                                            existing: item.row,
                                            compact: true,
                                          );
                                        }
                                      },
                                    ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            if (untimed.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Sem data'),
                subtitle: Text('${untimed.length} tarefas pendentes'),
                children: [for (final task in untimed) TaskRow(task: task)],
              ),
            if (!sameDay)
              TextButton(
                onPressed: () => context.read<AgendaCubit>().select(today),
                child: const Text('Voltar a hoje'),
              ),
          ],
        );
      },
    ),
  );
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.day});
  final DateTime day;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = math.max(
        constraints.maxWidth / 7,
        MediaQuery.textScalerOf(context).scale(24) + 16,
      );
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < 7; index++)
              Builder(
                builder: (context) {
                  final date = DateTime(
                    day.year,
                    day.month,
                    day.day - day.weekday + 1 + index,
                  );
                  final selected = dayKey(date) == dayKey(day);
                  return SizedBox(
                    width: width,
                    child: Semantics(
                      selected: selected,
                      button: true,
                      label: DateFormat('EEEE, d MMMM', 'pt').format(date),
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: () => context.read<AgendaCubit>().select(date),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? Theme.of(context).colorScheme.surface
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            border: selected
                                ? Border.all(
                                    color: Theme.of(context).dividerColor,
                                  )
                                : null,
                          ),
                          child: Column(
                            children: [
                              Text(
                                [
                                  'seg',
                                  'ter',
                                  'qua',
                                  'qui',
                                  'sex',
                                  'sáb',
                                  'dom',
                                ][index],
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${date.day}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      );
    },
  );
}
