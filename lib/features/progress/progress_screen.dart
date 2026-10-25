import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/workspace_page.dart';
import 'progress_panel.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});
  @override
  Widget build(BuildContext context) => WorkspaceData(
    builder: (data) {
      final enabled = data['UserPreferences']!.single['gamification'] == 1;
      final xp = data['ExperienceEvents']!.fold<int>(
        0,
        (sum, e) => sum + (e['points'] as int),
      );
      return WorkspacePage(
        title: 'Progresso',
        description: 'O teu percurso, ao teu ritmo.',
        more: false,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data['Tasks']!.where((t) => t['completed'] == 1).length} tarefas concluídas',
                  ),
                  Text(
                    '${data['Goals']!.where((g) => g['status'] == 'active').length} metas activas',
                  ),
                  Text(
                    '${data['Goals']!.where((g) => g['status'] == 'completed').length} metas alcançadas',
                  ),
                  if (enabled) ...[
                    const SizedBox(height: 16),
                    Text('$xp XP · Nível ${1 + xp ~/ 100}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ProgressPanel(data: data, gamification: enabled),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.push('/reviews'),
            child: const Text('Fazer uma revisão'),
          ),
        ],
      );
    },
  );
}
