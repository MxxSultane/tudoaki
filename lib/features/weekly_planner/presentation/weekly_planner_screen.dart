import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../core/database/database.dart';
import '../../../core/widgets/workspace_page.dart';
import '../../academics/academic_editor.dart';
import '../../agenda/domain/agenda_items.dart';
import '../../forms.dart';
import '../../tasks/presentation/task_row.dart';
import '../domain/weekly_planner_cubit.dart';

class WeeklyPlannerScreen extends ConsumerStatefulWidget {
  const WeeklyPlannerScreen({super.key});
  @override
  ConsumerState<WeeklyPlannerScreen> createState() =>
      _WeeklyPlannerScreenState();
}

class _WeeklyPlannerScreenState extends ConsumerState<WeeklyPlannerScreen> {
  bool editing = false;
  final dayKeys = List.generate(7, (_) => GlobalKey());

  Future<void> edit(WeeklySelection selection, {DataRowMap? task}) async {
    if (editing) return;
    setState(() => editing = true);
    final container = ProviderScope.containerOf(context, listen: false);
    final kind = selection.kind == PlanKind.task ? 'Tarefa' : 'Evento';
    try {
      final id = await showEditor(
        context,
        kind,
        existing: task,
        compact: true,
        dayOnlyTask: kind == 'Tarefa',
        requireTaskDate: kind == 'Tarefa',
        initialDate: DateTime(
          selection.day.year,
          selection.day.month,
          selection.day.day,
          9,
        ),
      );
      if (id == null || !mounted) return;
      final rows = await container
          .read(repositoryProvider)
          .all(kind == 'Tarefa' ? 'Tasks' : 'CalendarEvents');
      if (!mounted) return;
      final row = rows.where((r) => r['id'] == id).firstOrNull;
      final at = DateTime.tryParse(
        row?[kind == 'Tarefa' ? 'due' : 'start'] as String? ?? '',
      );
      if (at != null) context.read<WeeklyPlannerCubit>().selectDate(at);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o registo.')),
        );
      }
    } finally {
      if (mounted) setState(() => editing = false);
    }
  }

  Future<void> chooseTask(
    WeeklySelection selection,
    List<DataRowMap> tasks,
  ) async {
    final task = await showModalBottomSheet<DataRowMap>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Escolher tarefa',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final task in tasks)
                      ListTile(
                        title: Text(task['title'] as String),
                        subtitle: const Text('Sem data'),
                        onTap: () => Navigator.pop(context, task),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (task != null && mounted) await edit(selection, task: task);
  }

  Widget entry(AgendaItem item, List<AgendaItem> items) {
    final conflict = agendaConflict(item, items);
    final time = item.allDay ? 'Sem hora' : DateFormat.Hm().format(item.start);
    if (item.task) {
      return TaskRow(
        key: ValueKey('weekly-task-${item.row['id']}'),
        task: item.row,
        subtitle: '$time${conflict ? ' · Conflito de horário' : ''}',
      );
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.row['title'] as String),
      subtitle: Text(
        '$time – ${DateFormat.Hm().format(item.end!)}${conflict ? '\nConflito de horário' : ''}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: () {
        final kind = item.row['academic_kind'] as String?;
        if (kind == 'Estudo') {
          context.push('/academics');
        } else if (kind != null) {
          showAcademicEditor(
            context,
            kind,
            existing: item.row['academic_row'] as DataRowMap,
          );
        } else {
          showEditor(context, 'Evento', existing: item.row, compact: true);
        }
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<WeeklyPlannerCubit, WeeklySelection>(
    listenWhen: (previous, next) => previous.dayIndex != next.dayIndex,
    listener: (context, selection) =>
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final target = dayKeys[selection.dayIndex].currentContext;
          if (target != null) {
            Scrollable.ensureVisible(
              target,
              alignment: .1,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
            );
          }
        }),
    builder: (context, selection) => WorkspaceData(
      builder: (data) {
        final cubit = context.read<WeeklyPlannerCubit>();
        final unscheduled = data['Tasks']!
            .where((t) => t['completed'] == 0 && t['due'] == null)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                key: const ValueKey('weekly-days'),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Text(
                    'O que vais adicionar?',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    children: [
                      for (final kind in PlanKind.values)
                        TextButton(
                          key: ValueKey('plan-kind-${kind.name}'),
                          onPressed: () => cubit.kind(kind),
                          child: Text(
                            kind == PlanKind.task ? 'Tarefas' : 'Eventos',
                            style: TextStyle(
                              fontWeight: selection.kind == kind
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Semana anterior',
                        onPressed: cubit.canPrevious
                            ? () => cubit.move(-1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final day = await showDatePicker(
                              context: context,
                              initialDate: selection.day,
                              firstDate: WeeklyPlannerCubit.firstDay,
                              lastDate: WeeklyPlannerCubit.lastDay,
                            );
                            if (day != null && mounted) cubit.selectDate(day);
                          },
                          child: Text(
                            '${DateFormat('d MMM', 'pt').format(selection.monday)} – ${DateFormat('d MMM yyyy', 'pt').format(selection.end)}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Semana seguinte',
                        onPressed: cubit.canNext ? () => cubit.move(1) : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (var index = 0; index < 7; index++)
                    Builder(
                      builder: (context) {
                        final day = DateTime(
                          selection.monday.year,
                          selection.monday.month,
                          selection.monday.day + index,
                        );
                        final items = agendaItemsForDay(data, day);
                        final tasks = items.where((i) => i.task).length;
                        final events = items.length - tasks;
                        final selected = selection.dayIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            key: dayKeys[index],
                            shape: selected
                                ? RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  )
                                : null,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Semantics(
                                  selected: selected,
                                  child: ListTile(
                                    key: ValueKey('plan-day-$index'),
                                    title: Text(
                                      '${['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'][index]} · ${DateFormat('d MMM', 'pt').format(day)}',
                                    ),
                                    subtitle: Text(
                                      items.isEmpty
                                          ? 'Dia livre'
                                          : '$events ${events == 1 ? 'evento' : 'eventos'} · $tasks ${tasks == 1 ? 'tarefa' : 'tarefas'}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    enabled: cubit.allowed(day),
                                    onTap: () => cubit.selectDay(index),
                                  ),
                                ),
                                if (selected &&
                                    (items.isNotEmpty ||
                                        selection.kind == PlanKind.task &&
                                            unscheduled.isNotEmpty))
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      16,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const Divider(height: 1),
                                        for (final item in items)
                                          entry(item, items),
                                        if (selection.kind == PlanKind.task &&
                                            unscheduled.isNotEmpty)
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: TextButton(
                                              onPressed: editing
                                                  ? null
                                                  : () => chooseTask(
                                                      selection,
                                                      unscheduled,
                                                    ),
                                              child: const Text(
                                                'Escolher pendente',
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Os registos ficam na agenda.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    DateFormat('EEEE, d MMM', 'pt').format(selection.day),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: editing ? null : () => edit(selection),
                    child: Text(
                      selection.kind == PlanKind.task
                          ? 'Adicionar tarefa'
                          : 'Adicionar evento',
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}
