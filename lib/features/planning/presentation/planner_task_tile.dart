import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/database/database.dart';
import '../../tasks/domain/task_operations.dart';
import '../../tasks/presentation/task_row.dart';
import 'task_schedule_sheet.dart';

typedef PlannerWritten = void Function(TaskWriteResult result, String message);

String plannerFeedback(TaskWriteResult result, String message) =>
    result.reminderFailure == null
    ? message
    : '$message Lembrete indisponível.';

class PlannerTaskTile extends ConsumerStatefulWidget {
  const PlannerTaskTile({
    required this.task,
    required this.onWritten,
    this.subtitle,
    this.showSubtitle = true,
    super.key,
  });
  final DataRowMap task;
  final PlannerWritten onWritten;
  final String? subtitle;
  final bool showSubtitle;
  @override
  ConsumerState<PlannerTaskTile> createState() => _PlannerTaskTileState();
}

class _PlannerTaskTileState extends ConsumerState<PlannerTaskTile> {
  bool _busy = false;
  String? _error;

  Future<void> _act(String action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final onWritten = widget.onWritten;
    final operations = ref.read(taskOperationsProvider);
    final id = widget.task['id'] as int;
    try {
      TaskWriteResult? result;
      if (action == 'day') {
        result = await showTaskScheduleSheet(context, widget.task);
      } else {
        final remove = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Retirar do planeamento?'),
            content: const Text(
              'A tarefa fica em Sem data e o lembrete fica desligado.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Retirar data'),
              ),
            ],
          ),
        );
        if (remove == true) {
          result = await operations.reschedule(id, null);
        }
      }
      // A successful write may remove this row from the current projection.
      if (result != null) {
        onWritten(
          result,
          action == 'day' ? 'Planeamento guardado.' : 'Tarefa sem data.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível guardar. Tenta novamente.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: TaskRow(
              task: widget.task,
              subtitle: widget.subtitle,
              showSubtitle: widget.showSubtitle,
            ),
          ),
          PopupMenuButton<String>(
            key: ValueKey('plan-task-menu-${widget.task['id']}'),
            tooltip: 'Opções de ${widget.task['title']}',
            enabled: !_busy,
            onSelected: _act,
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'day', child: Text('Escolher dia')),
              if (widget.task['due'] != null)
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('Retirar data'),
                ),
            ],
          ),
        ],
      ),
      if (_error != null)
        Semantics(
          liveRegion: true,
          child: Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
    ],
  );
}
