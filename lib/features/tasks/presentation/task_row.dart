import 'package:flutter/material.dart';
import '../../../core/theme/premium_theme.dart';
import '../../../core/theme/premium_tokens.dart';
import '../../../core/widgets/premium_components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../core/database/database.dart';
import '../../../core/widgets/workspace_page.dart';
import '../../forms.dart';

class TaskRow extends ConsumerStatefulWidget {
  const TaskRow({
    required this.task,
    this.subtitle,
    this.showSubtitle = true,
    super.key,
  });
  final DataRowMap task;
  final String? subtitle;
  final bool showSubtitle;
  @override
  ConsumerState<TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends ConsumerState<TaskRow> {
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final done = task['completed'] == 1;
    final tile = ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Semantics(
        label: '${done ? 'Reabrir' : 'Concluir'} ${task['title']}',
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
                    final failure = await container
                        .read(taskOperationsProvider)
                        .setCompleted(
                          task,
                          value!,
                          onPersisted: () {
                            HapticFeedback.selectionClick();
                          },
                          refreshConsumers: false,
                        );
                    if (failure != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tarefa guardada; verifica o lembrete.',
                          ),
                        ),
                      );
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
      subtitle: !widget.showSubtitle
          ? null
          : Text(
              widget.subtitle ??
                  (task['due'] == null
                      ? 'Sem data'
                      : DateFormat(
                          isDateOnly(task['due'] as String?)
                              ? 'dd MMM · \'sem hora\''
                              : 'dd MMM · HH:mm',
                          'pt',
                        ).format(DateTime.parse(task['due'] as String))),
              style: Theme.of(context).textTheme.bodySmall,
            ),
      onTap: () => showEditor(
        PremiumScope.legacyContextOf(context),
        'Tarefa',
        existing: task,
        compact: true,
      ),
    );
    if (!PremiumTokens.active(context)) return tile;
    return PremiumFocusOutline(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: PremiumTokens.of(context).soft),
          ),
        ),
        child: tile,
      ),
    );
  }
}
