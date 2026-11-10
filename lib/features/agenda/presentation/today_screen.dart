import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/navigation/app_routes.dart';
import '../../../app/providers.dart';
import '../../../core/database/database.dart';
import '../../../core/widgets/workspace_page.dart';
import '../../academics/academic_editor.dart';
import '../../forms.dart';
import '../../tasks/domain/task_operations.dart';
import '../../tasks/domain/tasks_cubit.dart';
import '../../planning/domain/planning_view.dart';
import '../../tasks/presentation/quick_task_sheet.dart';
import '../../tasks/presentation/task_row.dart';
import '../domain/agenda_cubit.dart';
import '../domain/agenda_items.dart';
import '../domain/today_content.dart';
import 'agenda_browser.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});
  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen>
    with WidgetsBindingObserver {
  late DateTime _now;
  Timer? _clockTick;
  bool _browse = false;
  TaskWriteResult? _saved;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _now = ref.read(workspaceClockProvider)();
    _scheduleClock();
  }

  void _scheduleClock() {
    _clockTick?.cancel();
    // Minute boundaries also refresh upcoming blocks while the app stays open.
    final next = DateTime(
      _now.year,
      _now.month,
      _now.day,
      _now.hour,
      _now.minute + 1,
    );
    _clockTick = Timer(next.difference(_now), _refreshClock);
  }

  void _refreshClock() {
    if (!mounted) return;
    final now = ref.read(workspaceClockProvider)();
    final cubit = context.read<AgendaCubit>();
    if (dayKey(now) != dayKey(_now) &&
        !_browse &&
        cubit.state.mode == 'Dia' &&
        dayKey(cubit.state.day) == dayKey(_now)) {
      cubit.select(now);
    }
    setState(() => _now = now);
    _scheduleClock();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshClock();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _clockTick?.cancel();
    }
  }

  @override
  void dispose() {
    _clockTick?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _create() async {
    // Read the current civil date again if the sheet opens across midnight.
    final now = ref.read(workspaceClockProvider)();
    final result = await showQuickTaskSheet(context, initialDate: now);
    if (result != null && mounted) setState(() => _saved = result);
  }

  void _openTasks() {
    context.read<TasksCubit>().completed(false);
    context.go(AppRoutes.tasks);
  }

  void _showToday() {
    final cubit = context.read<AgendaCubit>();
    cubit.select(ref.read(workspaceClockProvider)());
    cubit.mode('Dia');
    setState(() => _browse = false);
    _refreshClock();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AgendaCubit, AgendaSelection>(
        builder: (context, selection) {
          if (_browse ||
              selection.mode != 'Dia' ||
              dayKey(selection.day) != dayKey(_now)) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _showToday,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Voltar a Hoje'),
                  ),
                ),
                const Expanded(child: AgendaBrowser()),
              ],
            );
          }
          return WorkspaceData(builder: (data) => _overview(context, data));
        },
      );

  Widget _heading(String title, {Widget? action}) => Padding(
    padding: const EdgeInsets.only(top: 32, bottom: 8),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?action,
      ],
    ),
  );

  Widget _task(DataRowMap task, {bool previous = false}) {
    final date = localTaskDate(task['due'] as String?);
    final time = date == null || isDateOnly(task['due'] as String?)
        ? 'Sem hora'
        : DateFormat.Hm().format(date);
    return TaskRow(
      key: ValueKey('today-task-${task['id']}'),
      task: task,
      showSubtitle:
          previous || (date != null && !isDateOnly(task['due'] as String?)),
      subtitle: previous && date != null
          ? '${DateFormat('d MMM', 'pt').format(date)} · $time'
          : time,
    );
  }

  Widget _commitment(AgendaItem item) => ListTile(
    key: ValueKey(
      'today-event-${item.row['academic_kind'] ?? 'personal'}-${item.row['id']}',
    ),
    contentPadding: EdgeInsets.zero,
    minVerticalPadding: 12,
    title: Text(item.row['title'] as String),
    subtitle: Text(
      '${DateFormat.Hm().format(item.start)} – ${DateFormat.Hm().format(item.end!)}',
    ),
    trailing: const Icon(Icons.chevron_right, size: 20),
    onTap: () {
      final kind = item.row['academic_kind'] as String?;
      if (kind == 'Estudo') {
        context.push(AppRoutes.academics);
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

  Widget _overview(BuildContext context, WorkspaceSnapshot data) {
    final content = TodayContent(data, _now);
    final saved = _saved == null
        ? null
        : data['Tasks']!.where((task) => task['id'] == _saved!.id).firstOrNull;
    final savedDate = localTaskDate(saved?['due'] as String?);
    final outside =
        saved != null &&
        (savedDate == null || dayKey(savedDate) != dayKey(_now));
    return ListView(
      key: const PageStorageKey('today-overview'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 112),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Hoje',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.areas),
              child: const Text('Mais'),
            ),
          ],
        ),
        Text(
          DateFormat("EEEE, d 'de' MMMM", 'pt').format(_now),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (content.completedToday.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${content.completedToday.length} ${content.completedToday.length == 1 ? 'tarefa concluída hoje' : 'tarefas concluídas hoje'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 16),
        // Existing calendar modes remain directly reachable during this phase.
        Wrap(
          spacing: 16,
          children: [
            for (final mode in ['Dia', 'Semana', 'Mês'])
              Semantics(
                selected: mode == 'Dia',
                child: TextButton(
                  onPressed: () => context.read<AgendaCubit>().mode(mode),
                  child: Text(
                    mode,
                    style: TextStyle(
                      fontWeight: mode == 'Dia'
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
          ],
        ),
        _heading(
          'Compromissos',
          action: TextButton(
            onPressed: () => setState(() => _browse = true),
            child: const Text('Ver dia completo'),
          ),
        ),
        if (content.upcoming.isEmpty)
          Text(
            content.commitments.isEmpty
                ? 'Sem compromissos para hoje.'
                : 'Sem mais compromissos com hora para hoje.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        for (final item in content.upcoming) _commitment(item),
        _heading(
          'Tarefas de hoje',
          action: TextButton.icon(
            onPressed: _create,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Adicionar tarefa'),
          ),
        ),
        if (_saved != null)
          Semantics(
            liveRegion: true,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  _saved!.reminderFailure != null
                      ? 'Tarefa guardada; lembrete indisponível.'
                      : outside && savedDate == null
                      ? 'Tarefa guardada sem data.'
                      : outside
                      ? 'Tarefa guardada para ${DateFormat('d MMM', 'pt').format(savedDate!)}.'
                      : 'Tarefa guardada.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (outside)
                  TextButton(
                    onPressed: _openTasks,
                    child: const Text('Ver tarefas'),
                  ),
              ],
            ),
          ),
        if (content.pending.isEmpty)
          Text(
            content.completedToday.isEmpty
                ? 'O dia está em aberto. Adiciona uma tarefa quando quiseres.'
                : 'As tarefas de hoje estão feitas.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        for (final task in content.pending) _task(task),
        if (content.previous.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: ExpansionTile(
              key: const PageStorageKey('today-previous'),
              tilePadding: EdgeInsets.zero,
              title: Text('De dias anteriores · ${content.previous.length}'),
              children: [
                for (final task in content.previous)
                  _task(task, previous: true),
              ],
            ),
          ),
        _heading(
          'Hábitos',
          action: TextButton(
            onPressed: () => context.push(AppRoutes.habits),
            child: const Text('Ver hábitos'),
          ),
        ),
        if (content.habits.isEmpty)
          Text(
            'Sem rotinas previstas para hoje.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        for (final habit in content.habits)
          _TodayHabit(
            key: ValueKey('today-habit-${habit['id']}'),
            habit: habit,
            today: _now,
            done: data['HabitCompletions']!.any(
              (row) =>
                  row['habit_id'] == habit['id'] && row['day'] == dayKey(_now),
            ),
          ),
        if (content.completedToday.isNotEmpty)
          ExpansionTile(
            key: const PageStorageKey('today-completed'),
            tilePadding: EdgeInsets.zero,
            title: Text('Concluídas hoje · ${content.completedToday.length}'),
            children: [for (final task in content.completedToday) _task(task)],
          ),
        const SizedBox(height: 24),
        const Divider(),
        Wrap(
          spacing: 16,
          children: [
            TextButton(
              onPressed: () => context.push(
                AppRoutes.weeklyPlanner,
                extra: PlanningView.tomorrow,
              ),
              child: const Text('Planear amanhã'),
            ),
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.weeklyPlanner),
              icon: const Icon(Icons.calendar_view_week_outlined, size: 20),
              label: const Text('Planear semana'),
            ),
            TextButton(
              onPressed: _openTasks,
              child: Text(
                content.undatedCount == 0
                    ? 'Ver todas as tarefas'
                    : 'Sem data · ${content.undatedCount}',
              ),
            ),
            if (data['StudySessions']!.any(
              (row) => row['focus_started_at'] != null && row['completed'] == 0,
            ))
              TextButton(
                onPressed: () => context.push(AppRoutes.academics),
                child: const Text('Retomar estudo'),
              ),
          ],
        ),
      ],
    );
  }
}

class _TodayHabit extends ConsumerStatefulWidget {
  const _TodayHabit({
    required this.habit,
    required this.today,
    required this.done,
    super.key,
  });
  final DataRowMap habit;
  final DateTime today;
  final bool done;
  @override
  ConsumerState<_TodayHabit> createState() => _TodayHabitState();
}

class _TodayHabitState extends ConsumerState<_TodayHabit> {
  bool _busy = false;
  @override
  Widget build(BuildContext context) => CheckboxListTile(
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    title: Text(widget.habit['title'] as String),
    value: widget.done,
    onChanged: _busy
        ? null
        : (_) async {
            setState(() => _busy = true);
            await applyWorkspace(
              context,
              ref,
              () => ref
                  .read(repositoryProvider)
                  .toggleHabit(widget.habit['id'] as int, widget.today),
            );
            if (mounted) setState(() => _busy = false);
          },
  );
}
