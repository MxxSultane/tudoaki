import '../../../app/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database.dart';
import '../../../core/theme/premium_theme.dart';
import '../../../core/theme/premium_tokens.dart';
import '../../../core/widgets/premium_components.dart';
import '../../../core/widgets/workspace_page.dart';
import '../domain/goals_cubit.dart';
import '../goal_deadline.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});
  @override
  Widget build(BuildContext context) => PremiumScope(
    child: Builder(
      builder: (context) => BlocBuilder<GoalsCubit, bool>(
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
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final value in [false, true])
                      PremiumFilter(
                        label: value ? 'Alcançadas' : 'Activas',
                        selected: value == completed,
                        onPressed: () =>
                            context.read<GoalsCubit>().completed(value),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (goals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExcludeSemantics(
                          child: Icon(
                            Icons.flag_outlined,
                            size: 32,
                            color: PremiumTokens.of(context).action,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          completed
                              ? 'Ainda não há metas alcançadas.'
                              : 'Ainda sem metas activas.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          completed
                              ? 'Os resultados alcançados continuam disponíveis neste filtro.'
                              : 'Usa o + para definir uma meta e o que queres medir.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                for (var i = 0; i < goals.length; i++) ...[
                  _GoalSummary(goal: goals[i], highlighted: i == 0),
                  const SizedBox(height: 16),
                ],
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _GoalSummary extends StatefulWidget {
  const _GoalSummary({required this.goal, required this.highlighted});
  final DataRowMap goal;
  final bool highlighted;
  @override
  State<_GoalSummary> createState() => _GoalSummaryState();
}

class _GoalSummaryState extends State<_GoalSummary> {
  bool _pressed = false;
  DataRowMap get goal => widget.goal;
  bool get highlighted => widget.highlighted;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = PremiumTokens.of(context);
    final current = NumberFormat.decimalPattern('pt').format(goal['current']);
    final target = NumberFormat.decimalPattern('pt').format(goal['target']);
    return PremiumFocusOutline(
      radius: highlighted ? 20 : 16,
      child: PremiumSurface(
        clay: highlighted,
        pressed: _pressed,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onHighlightChanged: (value) => setState(() => _pressed = value),
            borderRadius: BorderRadius.circular(highlighted ? 20 : 16),
            onTap: () => context.push(AppRoutes.goalDetail(goal['id'])),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal['title'] as String,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${goal['horizon']} · ${goal['category']}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      goal['due'] == null
                          ? 'Sem prazo'
                          : 'Até ${goalDeadlineLabel(goal['due'] as String?)}',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    // Keep the existing numeric model, calculation and semantics.
                    LinearProgressIndicator(
                      value: goalProgress(
                        goal['initial'] as num,
                        goal['target'] as num,
                        goal['current'] as num,
                      ),
                      color: t.action,
                      backgroundColor: highlighted ? t.surface : t.soft,
                      minHeight: 6,
                      semanticsLabel: 'Progresso de ${goal['title']}',
                      semanticsValue: '$current de $target ${goal['unit']}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$current / $target ${goal['unit']}',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
