import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database.dart';
import '../../../core/widgets/workspace_page.dart';
import '../../../core/widgets/skeleton_page.dart';
import '../domain/goals_cubit.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<GoalsCubit, bool>(
    builder: (context, completed) => WorkspaceData(
      builder: (data) {
        final goals = data['Goals']!
            .where((g) => (g['status'] == 'completed') == completed)
            .toList();
        return WorkspacePage(
          title: 'Metas',
          description: 'Pequenas acções, resultados reais.',
          children: [
            Wrap(
              spacing: 16,
              children: [
                for (final value in [false, true])
                  TextButton(
                    onPressed: () =>
                        context.read<GoalsCubit>().completed(value),
                    child: Text(
                      value ? 'Alcançadas' : 'Activas',
                      style: TextStyle(
                        fontWeight: value == completed
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (goals.isEmpty)
              Text(
                completed
                    ? 'Ainda não há metas alcançadas.'
                    : 'Ainda não tens metas. Usa o +.',
              ),
            if (goals.isNotEmpty)
              InsetGroup(
                children: [
                  for (final goal in goals)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.push('/goal/${goal['id']}'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal['title'] as String,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${goal['horizon']} · ${goal['category']}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: goalProgress(
                                goal['initial'] as num,
                                goal['target'] as num,
                                goal['current'] as num,
                              ),
                              minHeight: 3,
                              semanticsLabel: 'Progresso de ${goal['title']}',
                              semanticsValue:
                                  '${NumberFormat.decimalPattern('pt').format(goal['current'])} de ${NumberFormat.decimalPattern('pt').format(goal['target'])} ${goal['unit']}',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${NumberFormat.decimalPattern('pt').format(goal['current'])} / ${NumberFormat.decimalPattern('pt').format(goal['target'])} ${goal['unit']}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    ),
  );
}
