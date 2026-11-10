import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../core/database/database.dart';
import '../../../core/widgets/workspace_page.dart';
import '../../tasks/domain/task_operations.dart';
import '../../weekly_planner/domain/weekly_planner_cubit.dart';
import '../domain/planning_dates.dart';

Future<TaskWriteResult?> showTaskScheduleSheet(
  BuildContext context,
  DataRowMap task, {
  DateTime? initialDay,
}) => showModalBottomSheet<TaskWriteResult>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  isDismissible: false,
  enableDrag: false,
  builder: (_) => TaskScheduleSheet(task: task, initialDay: initialDay),
);

/// Rescheduling only: creation and full editing keep their existing forms.
class TaskScheduleSheet extends ConsumerStatefulWidget {
  const TaskScheduleSheet({required this.task, this.initialDay, super.key});
  final DataRowMap task;
  final DateTime? initialDay;
  @override
  ConsumerState<TaskScheduleSheet> createState() => _TaskScheduleSheetState();
}

class _TaskScheduleSheetState extends ConsumerState<TaskScheduleSheet> {
  DateTime? _day, _time;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final raw = widget.task['due'] as String?;
    final original = DateTime.tryParse(raw ?? '')?.toLocal();
    _day = widget.initialDay ?? original;
    if (original != null && !isDateOnly(raw)) _time = original;
  }

  Future<void> _chooseDay() async {
    final first = WeeklyPlannerCubit.firstDay,
        last = WeeklyPlannerCubit.lastDay;
    final at = _day ?? ref.read(workspaceClockProvider)();
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
    if (selected != null && mounted) setState(() => _day = selected);
  }

  Future<void> _chooseTime() async {
    final value = await showTimePicker(
      context: context,
      initialTime: _time == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay.fromDateTime(_time!),
    );
    if (value != null && mounted) {
      setState(() => _time = DateTime(2000, 1, 1, value.hour, value.minute));
    }
  }

  Future<void> _save() async {
    if (_busy || _day == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(taskOperationsProvider)
          .reschedule(
            widget.task['id'] as int,
            scheduledTaskDue(widget.task['due'] as String?, _day!, time: _time),
          );
      if (mounted) Navigator.pop(context, result);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível guardar. Tenta novamente.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<TaskWriteResult>(
    canPop: !_busy,
    child: SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          24,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Escolher dia',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.task['title'] as String),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _busy ? null : _chooseDay,
              child: Text(
                _day == null
                    ? 'Dia: Escolher'
                    : 'Dia: ${DateFormat('dd/MM/yyyy').format(_day!)}',
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: _busy || _day == null ? null : _chooseTime,
                  child: Text(
                    _time == null
                        ? 'Definir hora'
                        : 'Hora: ${DateFormat.Hm().format(_time!)}',
                  ),
                ),
                if (_time != null)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _time = null),
                    child: const Text('Retirar hora'),
                  ),
              ],
            ),
            Text(
              _time == null
                  ? 'Sem hora, o lembrete fica desligado.'
                  : 'A hora é opcional. A configuração do lembrete será preservada.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_error != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy || _day == null ? null : _save,
              child: Text(_busy ? 'A guardar…' : 'Guardar'),
            ),
            TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    ),
  );
}
