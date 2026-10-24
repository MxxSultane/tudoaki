import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/providers.dart';
import '../../core/database/database.dart';
import '../forms.dart';

/// Details stay collapsed until needed; measured results remain on the goal card.
class GoalPlan extends ConsumerWidget {
  const GoalPlan({required this.goal, required this.taskBuilder, super.key});
  final DataRowMap goal;
  final Widget Function(DataRowMap task) taskBuilder;

  Future<void> _apply(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
      if (context.mounted) ref.invalidate(dataProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível actualizar a etapa. Tente novamente.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dataProvider).valueOrNull;
    if (data == null) return const SizedBox.shrink();
    final children = data['Goals']!
        .where((g) => g['parent_id'] == goal['id'])
        .toList();
    final milestones = data['GoalMilestones']!
        .where((m) => m['goal_id'] == goal['id'])
        .toList();
    final tasks = data['Tasks']!
        .where((t) => t['goal_id'] == goal['id'])
        .toList();
    final completed = milestones.where((m) => m['completed'] == 1).length;
    final completedTasks = tasks.where((t) => t['completed'] == 1).length;
    return ExpansionTile(
      key: PageStorageKey('goal-plan-${goal['id']}'),
      tilePadding: EdgeInsets.zero,
      title: const Text('Plano desta meta'),
      subtitle: Text(
        '${children.length} submetas · $completed/${milestones.length} etapas · $completedTasks/${tasks.length} tarefas',
      ),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (children.isNotEmpty) ...[
          const Text('Submetas', style: TextStyle(fontWeight: FontWeight.bold)),
          for (final child in children)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.subdirectory_arrow_right),
              title: Text(child['title'] as String),
              subtitle: Text(
                '${child['horizon']} · ${child['current']} / ${child['target']} ${child['unit']}',
              ),
              trailing: IconButton(
                tooltip: 'Editar submeta',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => showEditor(context, 'Meta', existing: child),
              ),
            ),
        ],
        const SizedBox(height: 8),
        const Text('Etapas', style: TextStyle(fontWeight: FontWeight.bold)),
        if (milestones.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Divida o caminho em etapas pequenas e claras.'),
          ),
        for (final milestone in milestones)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Checkbox(
              value: milestone['completed'] == 1,
              onChanged: (value) => _apply(context, ref, () async {
                await ref.read(repositoryProvider).save('GoalMilestones', {
                  'completed': value! ? 1 : 0,
                }, id: milestone['id'] as int);
              }),
            ),
            title: Text(milestone['title'] as String),
            subtitle: milestone['due'] == null
                ? null
                : Text(
                    'Até ${DateFormat('dd/MM/yyyy').format(DateTime.parse(milestone['due'] as String))}',
                  ),
            trailing: IconButton(
              tooltip: 'Editar etapa',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  showEditor(context, 'Etapa', existing: milestone),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () =>
                showEditor(context, 'Etapa', goalId: goal['id'] as int),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar etapa'),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Acções associadas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        if (tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Use “Adicionar acção” para planear o próximo passo.'),
          ),
        ...tasks.map(taskBuilder),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Etapas e tarefas organizam o trabalho. Os resultados de cada meta são registados separadamente.',
          ),
        ),
      ],
    );
  }
}
