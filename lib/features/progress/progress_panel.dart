import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/database/database.dart';
import 'progress_activity.dart';
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
    final xp = data['ExperienceEvents']!.fold<int>(
      0,
      (sum, e) => sum + (e['points'] as int),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Últimos sete dias',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Text(
          'Contagens de tarefas, hábitos e estudo. Não incluem registos de valores de metas.',
        ),
        for (final day in week)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '${DateFormat('dd MMM', 'pt').format(day.day)}: ${day.tasks} tarefas · ${day.habits} hábitos · ${day.studies} estudos',
            ),
          ),
        if (gamification) ...[
          Text('$xp XP · Nível ${1 + xp ~/ 100}'),
          Text('Conquistas', style: Theme.of(context).textTheme.titleLarge),
          const Text(
            'Reconhecimento do histórico de XP, sem XP adicional ou penalização por descanso.',
          ),
          for (final a in achievementCatalog)
            Builder(
              builder: (context) {
                final unlocked = data['Achievements']!
                    .where((r) => r['code'] == a.code)
                    .firstOrNull;
                final date = progressDate(unlocked?['unlocked_at']);
                final count = data['ExperienceEvents']!
                    .where((r) => (r['source'] as String).startsWith(a.prefix))
                    .length;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    unlocked == null
                        ? Icons.lock_outline
                        : Icons.emoji_events_outlined,
                  ),
                  title: Text(a.title),
                  subtitle: Text(
                    '${a.detail}\n${unlocked == null
                        ? '${math.min(count, a.target)} de ${a.target}'
                        : date == null
                        ? 'Alcançada · Data não registada'
                        : 'Alcançada em ${DateFormat('dd/MM/yyyy').format(date)}'}',
                  ),
                );
              },
            ),
        ],
      ],
    );
  }
}

class ProgressXpHistory extends StatefulWidget {
  const ProgressXpHistory({required this.rows, super.key});
  final List<DataRowMap> rows;
  @override
  State<ProgressXpHistory> createState() => _ProgressXpHistoryState();
}

class _ProgressXpHistoryState extends State<ProgressXpHistory> {
  int limit = 20;
  final _scroll = ScrollController(keepScrollOffset: false);
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  late final List<DataRowMap> rows;
  @override
  void initState() {
    super.initState();
    rows = widget.rows.toList()
      ..sort((a, b) {
        final ad = progressDate(a['created']), bd = progressDate(b['created']);
        if (ad == null) return bd == null ? 0 : 1;
        if (bd == null) return -1;
        return progressTimeKey(bd).compareTo(progressTimeKey(ad));
      });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scroll,
      primary: false,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Histórico de XP',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar histórico de XP',
                      autofocus: true,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Text(
                  'Reconhecimento guardado. Não é o histórico completo de actividade nem recupera títulos de registos eliminados.',
                ),
                if (rows.isEmpty) const Text('Sem registos de XP.'),
              ],
            ),
          ),
        ),
        SliverList.builder(
          itemCount: rows.take(limit).length,
          itemBuilder: (context, i) {
            final row = rows[i], date = progressDate(row['created']);
            final source = row['source'] as String;
            final kind = source.startsWith('task:')
                ? 'Tarefa'
                : source.startsWith('habit:')
                ? 'Hábito'
                : source.startsWith('study:')
                ? 'Estudo'
                : 'Outro reconhecimento';
            return ListTile(
              title: Text('$kind · ${row['points']} XP'),
              subtitle: Text(
                date == null
                    ? 'Data não registada'
                    : DateFormat('dd/MM/yyyy HH:mm').format(date),
              ),
            );
          },
        ),
        if (rows.length > limit)
          SliverToBoxAdapter(
            child: TextButton(
              onPressed: () => setState(() => limit += 20),
              child: const Text('Carregar mais XP'),
            ),
          ),
      ],
    );
  }
}
