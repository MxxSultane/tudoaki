import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/database/database.dart';
import 'progress_rules.dart';

final progressClockProvider = Provider<DateTime Function()>(
  (_) => DateTime.now,
);

class ProgressPanel extends ConsumerWidget {
  const ProgressPanel({
    required this.data,
    required this.gamification,
    super.key,
  });
  final Map<String, List<DataRowMap>> data;
  final bool gamification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = activityWeek(data, ref.watch(progressClockProvider)());
    final maximum = week.fold<int>(
      1,
      (max, d) => math.max(max, d.tasks + d.habits + d.studies),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Actividade nos últimos 7 dias',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Text(
          'Tarefas, registos de hábitos e sessões de estudo concluídas. Os valores reflectem os registos actuais; não medem o seu valor pessoal.',
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (final day in week)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${DateFormat('dd MMM', 'pt').format(day.day)}: ${day.tasks} tarefas · ${day.habits} hábitos · ${day.studies} estudos',
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value:
                              (day.tasks + day.habits + day.studies) / maximum,
                          semanticsLabel:
                              'Total de actividades em ${DateFormat('dd MMM', 'pt').format(day.day)}',
                          semanticsValue:
                              '${day.tasks + day.habits + day.studies}',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (gamification) ...[
          Text('Conquistas', style: Theme.of(context).textTheme.titleLarge),
          const Text(
            'Reconhecem o histórico de XP, incluindo registos anteriores. Sem XP adicional. Descansar não retira conquistas.',
          ),
          for (final achievement in achievementCatalog)
            Builder(
              builder: (context) {
                final unlocked = data['Achievements']!
                    .where((row) => row['code'] == achievement.code)
                    .firstOrNull;
                final count = data['ExperienceEvents']!
                    .where(
                      (e) => (e['source'] as String).startsWith(
                        achievement.prefix,
                      ),
                    )
                    .length;
                return Card(
                  child: ListTile(
                    leading: Icon(
                      unlocked != null
                          ? Icons.emoji_events_outlined
                          : Icons.lock_outline,
                    ),
                    title: Text(achievement.title),
                    subtitle: Text(
                      '${achievement.detail}\n${unlocked != null ? 'Alcançada em ${DateFormat('dd/MM/yyyy').format(maputoCivil(DateTime.parse(unlocked['unlocked_at'] as String)))}' : '${math.min(count, achievement.target)} de ${achievement.target}'}',
                    ),
                  ),
                );
              },
            ),
        ],
      ],
    );
  }
}
