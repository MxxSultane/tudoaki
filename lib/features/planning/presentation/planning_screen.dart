import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/navigation/app_routes.dart';
import '../../../core/database/database.dart';
import '../../../core/widgets/workspace_page.dart';
import '../../academics/academic_editor.dart';
import '../../agenda/domain/agenda_items.dart';
import '../../agenda/domain/today_content.dart';
import '../../forms.dart';
import '../../tasks/domain/task_operations.dart';
import '../../tasks/presentation/quick_task_sheet.dart';
import '../../weekly_planner/domain/weekly_planner_cubit.dart';
import '../../weekly_planner/presentation/weekly_planner_screen.dart';
import '../domain/planning_items.dart';
import '../domain/planning_view.dart';
import 'planner_task_tile.dart';
import 'task_schedule_sheet.dart';

class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({
    this.initialView = PlanningView.week,
    this.request,
    super.key,
  });
  final PlanningView initialView;
  final PlanningRequest? request;
  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen>
    with WidgetsBindingObserver {
  late PlanningView _view;
  late DateTime _now;
  DateTime? _pickedDay;
  Timer? _tick;
  bool _opening = false;
  String? _status;
  TaskWriteResult? _created;

  DateTime get _day =>
      _pickedDay ??
      DateTime(
        _now.year,
        _now.month,
        _now.day + (_view == PlanningView.tomorrow ? 1 : 0),
      );

  @override
  void initState() {
    super.initState();
    _view = widget.request?.view ?? widget.initialView;
    _now = ref.read(workspaceClockProvider)();
    WidgetsBinding.instance.addObserver(this);
    _scheduleClock();
  }

  @override
  void didUpdateWidget(covariant PlanningScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.request != null && widget.request != oldWidget.request) {
      _select(widget.request!.view);
    }
  }

  void _scheduleClock() {
    _tick?.cancel();
    final next = DateTime(
      _now.year,
      _now.month,
      _now.day,
      _now.hour,
      _now.minute + 1,
    );
    _tick = Timer(next.difference(_now), _refreshClock);
  }

  void _refreshClock() {
    if (!mounted) return;
    setState(() => _now = ref.read(workspaceClockProvider)());
    _scheduleClock();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshClock();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _tick?.cancel();
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _select(PlanningView view) {
    setState(() {
      _view = view;
      _pickedDay = null;
      _status = null;
      _created = null;
    });
    _refreshClock();
  }

  void _written(TaskWriteResult result, String message) {
    if (mounted) {
      setState(() {
        _status = plannerFeedback(result, message);
        _created = null;
      });
    }
  }

  Future<void> _create() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final result = await showQuickTaskSheet(
        context,
        initialDate: _view == PlanningView.undated ? null : _day,
      );
      if (result != null && mounted) {
        setState(() {
          _created = result;
          _status = null;
        });
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _chooseDay() async {
    final first = WeeklyPlannerCubit.firstDay,
        last = WeeklyPlannerCubit.lastDay;
    final at = _day;
    final selected = await showDatePicker(
      context: context,
      initialDate: at.isBefore(first)
          ? first
          : at.isAfter(last)
          ? last
          : at,
      firstDate: first,
      lastDate: last,
    );
    if (selected != null && mounted) {
      setState(() {
        _pickedDay = selected;
        _created = null;
        _status = null;
      });
    }
  }

  Future<void> _chooseTask(List<DataRowMap> tasks) async {
    if (_opening) return;
    setState(() => _opening = true);
    // Freeze the explicit target while the picker is open, even across midnight.
    final day = _day;
    try {
      final task = await showModalBottomSheet<DataRowMap>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
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
                          subtitle: Text(
                            task['due'] == null
                                ? 'Sem data'
                                : DateFormat(
                                    isDateOnly(task['due'] as String?)
                                        ? 'd MMM yyyy'
                                        : 'd MMM yyyy · HH:mm',
                                    'pt',
                                  ).format(
                                    localTaskDate(task['due'] as String?)!,
                                  ),
                          ),
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
      if (task != null && mounted) {
        final result = await showTaskScheduleSheet(
          context,
          task,
          initialDay: day,
        );
        if (result != null) _written(result, 'Planeamento guardado.');
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Widget _heading(String title, {Widget? action}) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
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

  Widget _task(DataRowMap row, List<AgendaItem> items) {
    final date = localTaskDate(row['due'] as String?);
    final item = items
        .where((i) => i.task && i.row['id'] == row['id'])
        .firstOrNull;
    final conflict = item != null && agendaConflict(item, items);
    final time = date == null || isDateOnly(row['due'] as String?)
        ? null
        : DateFormat.Hm().format(date);
    return PlannerTaskTile(
      key: ValueKey('plan-task-${row['id']}'),
      task: row,
      onWritten: _written,
      showSubtitle: time != null || conflict,
      subtitle:
          '${time ?? 'Sem hora'}${conflict ? ' · Conflito de horário' : ''}',
    );
  }

  Widget _event(AgendaItem item, List<AgendaItem> items) => ListTile(
    key: ValueKey(
      'plan-event-${item.row['academic_kind'] ?? 'personal'}-${item.row['id']}',
    ),
    contentPadding: EdgeInsets.zero,
    title: Text(item.row['title'] as String),
    subtitle: Text(
      '${DateFormat.Hm().format(item.start)} – ${DateFormat.Hm().format(item.end!)}${agendaConflict(item, items) ? '\nConflito de horário' : ''}',
    ),
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

  Widget _dayView(WorkspaceSnapshot data) {
    final undated = _view == PlanningView.undated;
    final day = _day;
    final items = undated ? <AgendaItem>[] : planningItemsForDay(data, day);
    final tasks = undated
        ? data['Tasks']!.where((t) => t['due'] == null).toList()
        : items.where((i) => i.task).map((i) => i.row).toList();
    final pending = tasks.where((t) => t['completed'] == 0).toList();
    final done = tasks.where((t) => t['completed'] == 1).toList();
    final candidates = data['Tasks']!.where((task) {
      if (task['completed'] == 1) return false;
      final at = localTaskDate(task['due'] as String?);
      return at == null || dayKey(at) != dayKey(day);
    }).toList();
    final events = items.where((i) => !i.task).toList();
    final saved = _created == null
        ? null
        : data['Tasks']!.where((t) => t['id'] == _created!.id).firstOrNull;
    final savedDay = localTaskDate(saved?['due'] as String?);
    final outside =
        saved != null &&
        (undated
            ? savedDay != null
            : savedDay == null || dayKey(savedDay) != dayKey(day));
    final confirmation = _created == null
        ? _status
        : plannerFeedback(
            _created!,
            outside && savedDay == null
                ? 'Tarefa guardada sem data.'
                : outside
                ? 'Tarefa guardada para ${DateFormat('d MMM', 'pt').format(savedDay!)}.'
                : 'Tarefa guardada.',
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            key: PageStorageKey(
              'planning-items-${undated ? 'undated' : dayKey(day)}',
            ),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              if (undated) ...[
                Semantics(
                  header: true,
                  child: Text(
                    'Sem data',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Text('Escolhe um dia quando fizer sentido.'),
              ] else
                TextButton.icon(
                  onPressed: _opening ? null : _chooseDay,
                  icon: const Icon(Icons.calendar_today_outlined, size: 20),
                  label: Text(
                    DateFormat("EEEE, d 'de' MMMM yyyy", 'pt').format(day),
                  ),
                ),
              _heading(
                'Tarefas',
                action: !undated && candidates.isNotEmpty
                    ? TextButton(
                        onPressed: _opening
                            ? null
                            : () => _chooseTask(candidates),
                        child: const Text('Escolher pendente'),
                      )
                    : null,
              ),
              if (pending.isEmpty)
                Text(
                  undated
                      ? 'Não há tarefas pendentes sem data.'
                      : _view == PlanningView.tomorrow && _pickedDay == null
                      ? 'Ainda não há tarefas para amanhã.'
                      : 'Ainda não há tarefas para este dia.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              for (final task in pending) _task(task, items),
              if (done.isNotEmpty)
                ExpansionTile(
                  key: PageStorageKey(
                    'plan-completed-${undated ? 'undated' : dayKey(day)}',
                  ),
                  tilePadding: EdgeInsets.zero,
                  title: Text('Concluídas · ${done.length}'),
                  children: [for (final task in done) _task(task, items)],
                ),
              if (!undated) ...[
                _heading(
                  'Compromissos',
                  action: TextButton(
                    onPressed: _opening
                        ? null
                        : () => showEditor(
                            context,
                            'Evento',
                            compact: true,
                            initialDate: DateTime(
                              day.year,
                              day.month,
                              day.day,
                              9,
                            ),
                          ),
                    child: const Text('Adicionar evento'),
                  ),
                ),
                if (events.isEmpty)
                  Text(
                    'Sem compromissos neste dia.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                for (final event in events) _event(event, items),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (confirmation != null)
                Semantics(liveRegion: true, child: Text(confirmation)),
              if (outside)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _view = savedDay == null
                          ? PlanningView.undated
                          : PlanningView.today;
                      _pickedDay = savedDay;
                    }),
                    child: const Text('Ver tarefa'),
                  ),
                ),
              Text(
                undated
                    ? 'Sem data'
                    : DateFormat('d MMM yyyy', 'pt').format(day),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _opening ? null : _create,
                child: const Text('Adicionar tarefa'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 4,
          children: [
            for (final item in const {
              PlanningView.today: 'Hoje',
              PlanningView.tomorrow: 'Amanhã',
              PlanningView.week: 'Semana',
              PlanningView.undated: 'Sem data',
            }.entries)
              Semantics(
                selected: _view == item.key && _pickedDay == null,
                child: TextButton(
                  key: ValueKey('planning-view-${item.key.name}'),
                  onPressed: _opening ? null : () => _select(item.key),
                  child: Text(
                    item.value,
                    style: TextStyle(
                      fontWeight: _view == item.key && _pickedDay == null
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () => context.push(AppRoutes.tasks),
          child: const Text('Todas as tarefas'),
        ),
      ),
      Expanded(
        child: _view == PlanningView.week
            ? const WeeklyPlannerScreen()
            : WorkspaceData(builder: _dayView),
      ),
    ],
  );
}
