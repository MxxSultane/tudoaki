import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/widgets/skeleton_page.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) => SkeletonPage(
    title: 'Hoje',
    description: 'Um dia de exemplo.',
    children: [
      const _WeekStrip(),
      const SizedBox(height: 32),
      InsetGroup(
        children: [
          for (final item in const [
            ('09:00', 'Reunião de equipa', 'Evento · 30 min'),
            ('11:30', 'Enviar proposta', 'Tarefa'),
            ('16:00', 'Caminhada', 'Evento · 30 min'),
          ])
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    item.$1,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$2,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.$3,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context) {
    // Static example week, matching the example agenda rather than real records.
    const weekdays = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(
          constraints.maxWidth / 7,
          MediaQuery.textScalerOf(context).scale(24) + 16,
        );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                SizedBox(
                  width: width,
                  child: Semantics(
                    label:
                        '${weekdays[i]}, ${19 + i} de Outubro de 2026${i == 6 ? ', dia de exemplo seleccionado' : ''}',
                    excludeSemantics: true,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: i == 6
                            ? Theme.of(context).colorScheme.surface
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        border: i == 6
                            ? Border.all(color: Theme.of(context).dividerColor)
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            weekdays[i],
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${19 + i}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
