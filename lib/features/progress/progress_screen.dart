import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/premium_theme.dart';
import '../../core/theme/premium_tokens.dart';
import '../../core/widgets/premium_components.dart';
import 'progress_activity.dart';
import 'progress_journey.dart';
import 'progress_panel.dart';
import 'progress_read_provider.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});
  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  bool completed = false;
  int limit = 3;
  Future<void> open(String route) async {
    await context.push(route);
    if (mounted) ref.invalidate(progressReadProvider);
  }

  Widget section(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    ),
  );
  @override
  Widget build(BuildContext context) => PremiumScope(
    child: Builder(
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          expansionTileTheme: Theme.of(context).expansionTileTheme.copyWith(
            iconColor: PremiumTokens.of(context).action,
            collapsedIconColor: PremiumTokens.of(context).action,
          ),
        ),
        child: ref
            .watch(progressViewProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Não foi possível abrir o progresso.'),
                    TextButton(
                      onPressed: () => ref.invalidate(progressReadProvider),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
              data: (view) {
                final data = view.data;
                final goals = data['Goals']!
                    .where((g) => (g['status'] == 'completed') == completed)
                    .toList(growable: false);
                final margin = MediaQuery.sizeOf(context).width < 360
                    ? 16.0
                    : 20.0;
                Widget heading(String text) => Semantics(
                  header: true,
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                );
                return CustomScrollView(
                  key: const PageStorageKey('progress-overview'),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(margin, 16, margin, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            heading('Actividade recente'),
                            const Text('Últimos sete dias'),
                            if (view.recent.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  'Sem registos datados neste período.',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: margin),
                      sliver: SliverList.builder(
                        itemCount: view.recent.take(limit).length,
                        itemBuilder: (context, i) => ProgressEntryTile(
                          entry: view.recent[i],
                          open: open,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(margin, 0, margin, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (view.recent.length > limit)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () => setState(() => limit += 20),
                                  child: const Text('Ver mais actividade'),
                                ),
                              ),
                            section('Evolução das metas'),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final v in [false, true])
                                  PremiumFilter(
                                    label: v ? 'Alcançadas' : 'Em curso',
                                    selected: completed == v,
                                    onPressed: () =>
                                        setState(() => completed = v),
                                  ),
                              ],
                            ),
                            if (goals.isEmpty)
                              Text(
                                completed
                                    ? 'Sem metas alcançadas.'
                                    : 'Sem metas em curso.',
                              ),
                            for (var i = 0; i < goals.length && i < 3; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: PremiumSurface(
                                  clay: i == 0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          goals[i]['title'] as String,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        Text(
                                          '${progressNumber(goals[i]['current'])} de ${progressNumber(goals[i]['target'])} ${goals[i]['unit']}',
                                        ),
                                        Text(
                                          'Inicial: ${progressNumber(goals[i]['initial'])} · ${completed ? 'Alcançada' : 'Em curso'}',
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton(
                                            onPressed: () =>
                                                open('/goal/${goals[i]['id']}'),
                                            child: const Text('Ver meta'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () => open('/goals'),
                                child: const Text('Ver todas as metas'),
                              ),
                            ),
                            section('Hábitos e estudo'),
                            Text(
                              '${data['HabitCompletions']!.length} registos de hábitos',
                            ),
                            Text(
                              '${data['StudySessions']!.where((s) => s['completed'] == 1).length} sessões de estudo concluídas',
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                TextButton(
                                  onPressed: () => open('/habits'),
                                  child: const Text('Consultar hábitos'),
                                ),
                                TextButton(
                                  onPressed: () => open('/academics'),
                                  child: const Text('Consultar estudos'),
                                ),
                              ],
                            ),
                            section('Percurso visual'),
                            const Text(
                              'Uma linha do tempo dos mesmos registos datados, com alternativa em lista.',
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: PremiumFocusOutline(
                                child: TextButton(
                                  onPressed: () => showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    builder: (sheet) => SizedBox(
                                      height:
                                          MediaQuery.sizeOf(sheet).height * .9,
                                      child: ProgressJourney(
                                        view: view,
                                        open: (route) {
                                          Navigator.pop(sheet);
                                          open(route);
                                        },
                                      ),
                                    ),
                                  ),
                                  child: const Text('Explorar Percurso'),
                                ),
                              ),
                            ),
                            if (view.undated.isNotEmpty)
                              PremiumFocusOutline(
                                child: ExpansionTile(
                                  key: const PageStorageKey('progress-undated'),
                                  tilePadding: EdgeInsets.zero,
                                  title: Text(
                                    'Registos sem data confirmada (${view.undated.length})',
                                  ),
                                  children: [
                                    const Text(
                                      'Datas de criação e planeamento não substituem datas de conclusão. Estes registos ficam fora da linha do tempo.',
                                    ),
                                    for (final e in view.undated.take(20))
                                      ProgressEntryTile(entry: e, open: open),
                                    if (view.undated.length > 20)
                                      Text(
                                        '${view.undated.length} registos sem data; consulte as origens para os restantes.',
                                      ),
                                  ],
                                ),
                              ),
                            if (view.future.isNotEmpty)
                              Text(
                                '${view.future.length} registos com dia futuro não incluídos nesta consulta.',
                              ),
                            PremiumFocusOutline(
                              child: ExpansionTile(
                                key: const PageStorageKey(
                                  'progress-indicators',
                                ),
                                tilePadding: EdgeInsets.zero,
                                title: const Text('Histórico e indicadores'),
                                expandedCrossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    '${data['Tasks']!.where((r) => r['completed'] == 1).length} tarefas concluídas',
                                  ),
                                  Text(
                                    '${data['Goals']!.where((r) => r['status'] == 'active').length} metas activas · ${data['Goals']!.where((r) => r['status'] == 'completed').length} metas alcançadas',
                                  ),
                                  ProgressPanel(
                                    data: data,
                                    gamification: view.gamification,
                                  ),
                                  if (view.gamification)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton(
                                        onPressed: () =>
                                            showModalBottomSheet<void>(
                                              context: context,
                                              useSafeArea: true,
                                              isScrollControlled: true,
                                              builder: (sheet) => SizedBox(
                                                height:
                                                    MediaQuery.sizeOf(
                                                      sheet,
                                                    ).height *
                                                    .85,
                                                child: ProgressXpHistory(
                                                  rows:
                                                      data['ExperienceEvents']!,
                                                ),
                                              ),
                                            ),
                                        child: const Text('Histórico de XP'),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              'Os nomes e associações são os actuais. A consulta reflecte reaberturas e eliminações, não um arquivo imutável.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () => open('/reviews'),
                                child: const Text('Fazer uma revisão'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
      ),
    ),
  );
}
