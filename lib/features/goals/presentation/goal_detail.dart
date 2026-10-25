import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../core/database/database.dart';
import '../../../core/widgets/workspace_page.dart';
import '../../forms.dart';
import '../../tasks/presentation/task_row.dart';
import '../goal_plan.dart';

class GoalDetail extends StatelessWidget {
  const GoalDetail({required this.id, super.key});
  final int id;
  @override
  Widget build(BuildContext context) => WorkspaceData(
    builder: (data) {
      final goal = data['Goals']!.where((g) => g['id'] == id).firstOrNull;
      if (goal == null) {
        return const Center(child: Text('Esta meta já não existe.'));
      }
      return WorkspacePage(
        title: goal['title'] as String,
        description: '${goal['horizon']} · ${goal['category']}',
        more: false,
        children: [
          if ((goal['description'] as String).isNotEmpty) ...[
            Text(goal['description'] as String),
            const SizedBox(height: 24),
          ],
          LinearProgressIndicator(
            value: goalProgress(
              goal['initial'] as num,
              goal['target'] as num,
              goal['current'] as num,
            ),
            minHeight: 3,
            semanticsLabel: 'Progresso da meta',
          ),
          const SizedBox(height: 16),
          Text(
            '${NumberFormat.decimalPattern('pt').format(goal['current'])} / ${NumberFormat.decimalPattern('pt').format(goal['target'])} ${goal['unit']}',
          ),
          if (goal['due'] != null)
            Text(
              'Até ${DateFormat('dd/MM/yyyy').format(DateTime.parse(goal['due'] as String))}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () =>
                showEditor(context, 'Tarefa', goalId: id, compact: true),
            child: const Text('Adicionar acção'),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => _MetricEditor(goal: goal),
                ),
                child: const Text('Registar progresso'),
              ),
              TextButton(
                onPressed: () =>
                    showEditor(context, 'Meta', existing: goal, compact: true),
                child: const Text('Editar meta'),
              ),
              TextButton(
                onPressed: () => showEditor(
                  context,
                  'Meta',
                  parentGoalId: id,
                  compact: true,
                ),
                child: const Text('Criar submeta'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GoalPlan(
            goal: goal,
            taskBuilder: (task) => TaskRow(task: task),
          ),
          const SizedBox(height: 24),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Histórico de resultados'),
            children: [
              for (final row
                  in data['GoalProgress']!
                      .where((p) => p['goal_id'] == id)
                      .toList()
                      .reversed)
                ListTile(
                  title: Text('${row['value']} ${goal['unit']}'),
                  subtitle: Text(
                    DateFormat(
                      'dd/MM/yyyy · HH:mm',
                    ).format(DateTime.parse(row['recorded_at'] as String)),
                  ),
                ),
            ],
          ),
        ],
      );
    },
  );
}

class _MetricEditor extends ConsumerStatefulWidget {
  const _MetricEditor({required this.goal});
  final DataRowMap goal;
  @override
  ConsumerState<_MetricEditor> createState() => _MetricEditorState();
}

class _MetricEditorState extends ConsumerState<_MetricEditor> {
  late final value = TextEditingController(text: '${widget.goal['current']}');
  bool busy = false;
  String? error;
  @override
  void dispose() {
    value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          24,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Registar progresso',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: value,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: 'Resultado em ${widget.goal['unit']}',
                errorText: error,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      final number = double.tryParse(
                        value.text.trim().replaceAll(',', '.'),
                      );
                      if (number == null || !number.isFinite) {
                        setState(() => error = 'Introduz um número válido.');
                        return;
                      }
                      setState(() {
                        busy = true;
                        error = null;
                      });
                      final container = ProviderScope.containerOf(
                        context,
                        listen: false,
                      );
                      try {
                        await container
                            .read(repositoryProvider)
                            .updateMetric(widget.goal['id'] as int, number);
                        container.invalidate(dataProvider);
                        if (context.mounted) Navigator.pop(context);
                      } catch (_) {
                        if (mounted) {
                          setState(() => error = 'Não foi possível guardar.');
                        }
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
              child: Text(busy ? 'A guardar…' : 'Guardar'),
            ),
          ],
        ),
      ),
    ),
  );
}
