import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../app/providers.dart';
import '../app/brand.dart';
import '../core/database/database.dart';
import 'forms.dart';
import 'goals/goal_plan.dart';
import 'academics/academic_rules.dart';
import 'academics/academic_editor.dart';
import 'academics/academics_panel.dart';
import 'finance/finance_panel.dart';
import 'finance/finance_rules.dart';
import 'progress/progress_panel.dart';

void showQuickCreate(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ListTile(title: Text('Uma pequena acção, um novo começo')),
        for (final item in {
          'Tarefa': Icons.check_circle_outline,
          'Evento': Icons.event_outlined,
          'Meta': Icons.flag_outlined,
          'Hábito': Icons.repeat,
        }.entries)
          ListTile(
            leading: Icon(item.value),
            title: Text(item.key),
            onTap: () {
              Navigator.pop(context);
              showEditor(context, item.key);
            },
          ),
      ],
    ),
  ),
);
String dateLabel(String? value) => value == null
    ? 'Sem data'
    : DateFormat(
        isDateOnly(value) ? 'dd MMM' : 'dd MMM, HH:mm',
        'pt',
      ).format(DateTime.parse(value));

class TudoAkiScreen extends ConsumerStatefulWidget {
  const TudoAkiScreen({
    required this.section,
    this.embedded = false,
    super.key,
  });
  final bool embedded;
  final String section;
  @override
  ConsumerState<TudoAkiScreen> createState() => _TudoAkiScreenState();
}

class _TudoAkiScreenState extends ConsumerState<TudoAkiScreen> {
  DateTime selected = DateTime.now();
  String agendaMode = 'Dia';
  Future<void> act(Future<void> Function() operation) async {
    try {
      await operation();
      ref.invalidate(dataProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível guardar. Tente novamente.'),
          ),
        );
      }
    }
  }

  TudoAkiRepository get repo => ref.read(repositoryProvider);
  Widget heading(String text, {Widget? action}) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?action,
      ],
    ),
  );
  Widget empty(String text, String kind) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => showEditor(context, kind),
            icon: const Icon(Icons.add),
            label: Text('Criar ${kind.toLowerCase()}'),
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => ref
      .watch(dataProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Não foi possível abrir os dados locais.'),
              TextButton(
                onPressed: () => ref.invalidate(dataProvider),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (data) {
          final prefs = data['UserPreferences']!.first;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
            children: [
              if (!widget.embedded) ...[
                TudoAkiBrandHeader(showSlogan: widget.section == 'Hoje'),
                const SizedBox(height: 8),
                Text(
                  widget.section == 'Hoje'
                      ? 'Um passo de cada vez.'
                      : widget.section,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
              if (widget.section == 'Hoje') ...today(data, prefs),
              if (widget.section == 'Agenda') ...agenda(data),
              if (widget.section == 'Metas') ...goals(data),
              if (widget.section == 'Progresso') ...progress(data, prefs),
              if (widget.section == 'Perfil') ...profile(prefs),
              if (widget.section == 'Hábitos') ...habits(data),
              if (widget.section == 'Finanças') ...finance(data),
              if (widget.section == 'Estudos') ...academics(data),
              if (widget.section == 'Revisões') ...reviews(data),
            ],
          );
        },
      );
  List<Widget> today(Map<String, List<DataRowMap>> data, DataRowMap prefs) {
    final now = DateTime.now();
    final tasks = data['Tasks']!.where((t) => t['completed'] == 0).toList()
      ..sort((a, b) => (b['priority'] as int).compareTo(a['priority'] as int));
    final due = tasks
        .where(
          (t) =>
              t['due'] == null ||
              DateTime.parse(
                t['due'] as String,
              ).isBefore(DateTime(now.year, now.month, now.day + 1)),
        )
        .toList();
    final events =
        [...data['CalendarEvents']!, ...academicEventsForDay(data, now)]
            .map((e) => (e, occurrenceOn(e, now)))
            .where((e) => e.$2 != null && e.$2!.isAfter(now))
            .toList()
          ..sort((a, b) => a.$2!.compareTo(b.$2!));
    return [
      Text(DateFormat('EEEE, d MMMM', 'pt').format(now)),
      for (final session in data['StudySessions']!.where(
        (s) => s['completed'] == 0 && s['focus_end'] != null,
      ))
        Card(
          child: ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(
              focusSecondsRemaining(session, now) == 0
                  ? 'Sessão de estudo por registar'
                  : 'Foco em curso',
            ),
            subtitle: Text(session['title'] as String),
            onTap: () => context.go('/academics'),
          ),
        ),

      if (prefs['onboarded'] == 0)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bem-vindo ao ${TudoAkiBrand.name}.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Text(
                  'Escolha uma pequena acção. Pode começar sem configurar nada; os seus dados ficam neste dispositivo.',
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => showEditor(context, 'Meta'),
                      child: const Text('Criar primeira meta'),
                    ),
                    TextButton(
                      onPressed: () => act(() async {
                        await repo.save('UserPreferences', {
                          'onboarded': 1,
                        }, id: 1);
                      }),
                      child: const Text('Começar livremente'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      if (events.isNotEmpty)
        Card(
          child: ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(events.first.$1['title'] as String),
            subtitle: Text(
              'Próximo compromisso · ${DateFormat.Hm().format(events.first.$2!)}',
            ),
            onTap: () => context.go('/agenda'),
          ),
        ),
      heading('Prioridades de hoje'),
      if (due.isEmpty)
        empty(
          'Espaço para o que importa. Ainda não há tarefas para hoje.',
          'Tarefa',
        ),
      ...due.take(3).map((t) => taskCard(t, data)),
      if (due.length > 3) ...[
        heading('Outras acções'),
        ...due.skip(3).map((t) => taskCard(t, data)),
      ],
      heading(
        'Hábitos de hoje',
        action: TextButton(
          onPressed: () => context.go('/habits'),
          child: const Text('Ver todos'),
        ),
      ),
      ...habitCards(data, todayOnly: true),
      if (data['Habits']!.isEmpty)
        empty('Uma rotina pode começar pequena.', 'Hábito'),
      heading('Metas em movimento'),
      ...data['Goals']!
          .where((g) => g['status'] == 'active')
          .take(2)
          .map(goalCard),
      if (data['Goals']!.isEmpty)
        empty('Dê uma direcção às suas próximas acções.', 'Meta'),
    ];
  }

  Widget taskCard(DataRowMap t, Map<String, List<DataRowMap>> data) {
    final linked = data['Goals']!
        .where((g) => g['id'] == t['goal_id'])
        .firstOrNull;
    final done = t['completed'] == 1;
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: done,
          onChanged: (value) => act(() async {
            await repo.taskDone(t['id'] as int, value!);
            if (t['reminder'] == 1) {
              try {
                final service = ref.read(remindersProvider);
                if (value) {
                  await service.cancel(t['id'] as int);
                } else if (t['due'] != null) {
                  await service.schedule(
                    t['id'] as int,
                    t['title'] as String,
                    DateTime.parse(t['due'] as String),
                  );
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Tarefa actualizada; não foi possível actualizar o lembrete.',
                      ),
                    ),
                  );
                }
              }
            }
          }),
        ),
        title: Text(
          t['title'] as String,
          style: TextStyle(
            decoration: done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${dateLabel(t['due'] as String?)} · ${['Baixa', 'Normal', 'Alta'][t['priority'] as int]}${linked == null ? '' : '\nMeta: ${linked['title']}'}',
        ),
        trailing: IconButton(
          tooltip: 'Editar tarefa',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => showEditor(context, 'Tarefa', existing: t),
        ),
      ),
    );
  }

  List<Widget> agenda(Map<String, List<DataRowMap>> data) {
    final first = agendaMode == 'Mês'
        ? DateTime(selected.year, selected.month, 1)
        : agendaMode == 'Semana'
        ? DateTime(
            selected.year,
            selected.month,
            selected.day - selected.weekday + 1,
          )
        : DateTime(selected.year, selected.month, selected.day);
    final days = agendaMode == 'Mês'
        ? DateTime(selected.year, selected.month + 1, 0).day
        : agendaMode == 'Semana'
        ? 7
        : 1;
    return [
      const SizedBox(height: 16),
      SegmentedButton<String>(
        segments: [
          for (final mode in ['Dia', 'Semana', 'Mês'])
            ButtonSegment(value: mode, label: Text(mode)),
        ],
        selected: {agendaMode},
        onSelectionChanged: (s) => setState(() => agendaMode = s.first),
      ),
      Row(
        children: [
          IconButton(
            tooltip: 'Período anterior',
            onPressed: () => setState(
              () => selected = agendaMode == 'Mês'
                  ? DateTime(selected.year, selected.month - 1, 1)
                  : DateTime(
                      selected.year,
                      selected.month,
                      selected.day - days,
                    ),
            ),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: TextButton(
              onPressed: () async {
                final result = await showDatePicker(
                  context: context,
                  initialDate: selected,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (result != null) {
                  setState(() => selected = result);
                }
              },
              child: Text(DateFormat('d MMMM yyyy', 'pt').format(selected)),
            ),
          ),
          IconButton(
            tooltip: 'Período seguinte',
            onPressed: () => setState(
              () => selected = agendaMode == 'Mês'
                  ? DateTime(selected.year, selected.month + 1, 1)
                  : DateTime(
                      selected.year,
                      selected.month,
                      selected.day + days,
                    ),
            ),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      for (var i = 0; i < days; i++)
        ...agendaDay(data, DateTime(first.year, first.month, first.day + i)),
      heading('Sem data'),
      ...data['Tasks']!
          .where((t) => t['due'] == null)
          .map((t) => taskCard(t, data)),
    ];
  }

  List<Widget> agendaDay(Map<String, List<DataRowMap>> data, DateTime day) {
    final events =
        [...data['CalendarEvents']!, ...academicEventsForDay(data, day)]
            .map((e) => (e, occurrenceOn(e, day)))
            .where((e) => e.$2 != null)
            .toList()
          ..sort((a, b) => a.$2!.compareTo(b.$2!));
    final tasks = data['Tasks']!.where(
      (t) =>
          t['due'] != null &&
          dayKey(DateTime.parse(t['due'] as String)) == dayKey(day),
    );
    return [
      heading(DateFormat('EEE, d MMM', 'pt').format(day)),
      if (events.isEmpty && tasks.isEmpty)
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text('Sem compromissos. Espaço também para descansar.'),
        ),
      for (var i = 0; i < events.length; i++)
        Builder(
          builder: (context) {
            final event = events[i].$1;
            final start = events[i].$2!;
            final length = DateTime.parse(
              event['end'] as String,
            ).difference(DateTime.parse(event['start'] as String));
            final end = start.add(length);
            final conflict = events.asMap().entries.any((entry) {
              if (entry.key == i) {
                return false;
              }
              final other = entry.value;
              final otherEnd = other.$2!.add(
                DateTime.parse(
                  other.$1['end'] as String,
                ).difference(DateTime.parse(other.$1['start'] as String)),
              );
              return start.isBefore(otherEnd) && end.isAfter(other.$2!);
            });
            return Card(
              child: ListTile(
                leading: Icon(
                  conflict ? Icons.warning_amber : Icons.event_outlined,
                ),
                title: Text(event['title'] as String),
                subtitle: Text(
                  '${DateFormat.Hm().format(start)} – ${DateFormat.Hm().format(end)}${event['recurrence'] == 'none' ? '' : ' · recorrente'}${conflict ? '\nConflito de horário' : ''}',
                ),
                onTap: () {
                  final kind = event['academic_kind'] as String?;
                  if (kind == 'Estudo') {
                    context.go('/academics');
                  } else if (kind != null) {
                    showAcademicEditor(
                      context,
                      kind,
                      existing: event['academic_row'] as DataRowMap,
                    );
                  } else {
                    showEditor(context, 'Evento', existing: event);
                  }
                },
              ),
            );
          },
        ),
      ...tasks.map((t) => taskCard(t, data)),
    ];
  }

  List<Widget> goals(Map<String, List<DataRowMap>> data) => [
    const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'Meça resultados reais. As tarefas são os passos para lá chegar.',
      ),
    ),
    if (data['Goals']!.isEmpty)
      empty('Qual é o seu próximo objectivo?', 'Meta'),
    ...data['Goals']!.map(goalCard),
  ];
  Widget goalCard(DataRowMap g) {
    final data = ref.watch(dataProvider).valueOrNull!;
    final parent = data['Goals']!
        .where((p) => p['id'] == g['parent_id'])
        .firstOrNull;
    final value = goalProgress(
      g['initial'] as num,
      g['target'] as num,
      g['current'] as num,
    );
    return Card(
      key: ValueKey('goal-${g['id']}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    g['title'] as String,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Editar meta',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => showEditor(context, 'Meta', existing: g),
                ),
              ],
            ),
            Text(
              '${g['horizon']} · ${g['category']}${g['due'] == null ? '' : ' · até ${DateFormat.yMd('pt').format(DateTime.parse(g['due'] as String))}'}',
            ),
            if (parent != null) Text('Submeta de: ${parent['title']}'),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: value,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              semanticsLabel: 'Progresso da meta',
              semanticsValue: '${(value * 100).round()} por cento',
            ),
            const SizedBox(height: 8),
            Text(
              '${g['current']} / ${g['target']} ${g['unit']} · ${(value * 100).round()}%',
            ),
            Wrap(
              children: [
                TextButton(
                  onPressed: () => metric(g),
                  child: const Text('Registar progresso'),
                ),
                TextButton(
                  onPressed: () =>
                      showEditor(context, 'Tarefa', goalId: g['id'] as int),
                  child: const Text('Adicionar acção'),
                ),
                TextButton(
                  onPressed: () =>
                      showEditor(context, 'Meta', parentGoalId: g['id'] as int),
                  child: const Text('Criar submeta'),
                ),
              ],
            ),
            GoalPlan(goal: g, taskBuilder: (task) => taskCard(task, data)),
          ],
        ),
      ),
    );
  }

  Future<void> metric(DataRowMap goal) async {
    final value = await showDialog<double>(
      context: context,
      builder: (_) => MetricDialog(goal: goal),
    );
    if (value != null) {
      await act(() => repo.updateMetric(goal['id'] as int, value));
    }
  }

  List<Widget> habitCards(
    Map<String, List<DataRowMap>> data, {
    bool todayOnly = false,
  }) {
    final today = DateTime.now();
    return data['Habits']!
        .where(
          (h) =>
              !todayOnly ||
              h['paused'] == 0 &&
                  (h['weekdays'] as String)
                      .split(',')
                      .contains('${today.weekday}'),
        )
        .map((h) {
          final done = data['HabitCompletions']!.any(
            (c) => c['habit_id'] == h['id'] && c['day'] == dayKey(today),
          );
          final count = data['HabitCompletions']!
              .where((c) => c['habit_id'] == h['id'])
              .length;
          return Card(
            child: ListTile(
              leading: Checkbox(
                value: done,
                onChanged: h['paused'] == 1
                    ? null
                    : (_) => act(() => repo.toggleHabit(h['id'] as int, today)),
              ),
              title: Text(h['title'] as String),
              subtitle: Text(
                '${h['cue']}\n$count dias registados${h['paused'] == 1 ? ' · Em pausa' : ''}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                tooltip: 'Editar hábito',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => showEditor(context, 'Hábito', existing: h),
              ),
            ),
          );
        })
        .toList();
  }

  List<Widget> habits(Map<String, List<DataRowMap>> data) => [
    const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'Consistência com flexibilidade. Pode pausar e retomar quando precisar.',
      ),
    ),
    if (data['Habits']!.isEmpty)
      empty('Comece com uma rotina pequena.', 'Hábito'),
    ...habitCards(data),
  ];
  List<Widget> progress(Map<String, List<DataRowMap>> data, DataRowMap prefs) {
    final done = data['Tasks']!.where((t) => t['completed'] == 1).length;
    final active = data['Goals']!.where((g) => g['status'] == 'active').length;
    final completed = data['Goals']!
        .where((g) => g['status'] == 'completed')
        .length;
    final xp = data['ExperienceEvents']!.fold<int>(
      0,
      (sum, e) => sum + (e['points'] as int),
    );
    return [
      heading('O seu percurso'),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$done tarefas concluídas'),
              Text('$active metas activas · $completed metas alcançadas'),
              Text('${data['HabitCompletions']!.length} registos de hábitos'),
              Text(
                '${data['StudySessions']!.where((s) => s['completed'] == 1).length} sessões de estudo concluídas',
              ),
              if (prefs['gamification'] == 1) ...[
                const Divider(),
                Text('$xp XP · Nível ${1 + xp ~/ 100}'),
                const Text(
                  'Reconhecemos o seu esforço. Descansar também faz parte.',
                ),
              ],
            ],
          ),
        ),
      ),
      ProgressPanel(data: data, gamification: prefs['gamification'] == 1),
      heading('Resultados das metas'),
      ...data['Goals']!.map(goalCard),
      heading('Histórico recente de hábitos'),
      ...data['HabitCompletions']!.reversed
          .take(14)
          .map(
            (c) => ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(
                data['Habits']!
                            .where((h) => h['id'] == c['habit_id'])
                            .firstOrNull?['title']
                        as String? ??
                    'Hábito',
              ),
              subtitle: Text(c['day'] as String),
            ),
          ),
      heading('Histórico de resultados'),
      ...data['GoalProgress']!.reversed
          .take(10)
          .map(
            (p) => ListTile(
              title: Text(
                data['Goals']!
                            .where((g) => g['id'] == p['goal_id'])
                            .firstOrNull?['title']
                        as String? ??
                    'Meta',
              ),
              subtitle: Text(
                '${p['value']} · ${dateLabel(p['recorded_at'] as String)}',
              ),
            ),
          ),
      TextButton.icon(
        onPressed: () => context.push('/reviews'),
        icon: const Icon(Icons.rate_review_outlined),
        label: const Text('Fazer uma revisão'),
      ),
    ];
  }

  List<Widget> profile(DataRowMap prefs) => [
    if (!widget.embedded) ...[
      heading('Organize as suas áreas'),
      for (final item in {
        '/habits': ('Hábitos e bem-estar', Icons.spa_outlined),
        '/academics': ('Estudos', Icons.school_outlined),
        '/finance': ('Finanças', Icons.account_balance_wallet_outlined),
        '/reviews': ('Revisões', Icons.rate_review_outlined),
      }.entries)
        Card(
          child: ListTile(
            leading: Icon(item.value.$2),
            title: Text(item.value.$1),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(item.key),
          ),
        ),
    ],
    heading('Preferências'),
    DropdownButtonFormField<String>(
      key: ValueKey('theme-${prefs['theme']}'),
      initialValue: prefs['theme'] as String,
      decoration: const InputDecoration(labelText: 'Aparência'),
      items: const [
        DropdownMenuItem(value: 'system', child: Text('Seguir sistema')),
        DropdownMenuItem(value: 'light', child: Text('Claro')),
        DropdownMenuItem(value: 'dark', child: Text('Escuro')),
      ],
      onChanged: (value) => act(() async {
        await repo.save('UserPreferences', {'theme': value}, id: 1);
      }),
    ),
    const SizedBox(height: 16),
    DropdownButtonFormField<String>(
      key: ValueKey('default-currency-${prefs['currency']}'),
      initialValue: prefs['currency'] as String,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Moeda para novos registos'),
      items: [
        for (final entry in currencyLabels.entries)
          DropdownMenuItem(
            value: entry.key,
            child: Text(
              entry.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) => act(() async {
        if (value != null) {
          await repo.save('UserPreferences', {'currency': value}, id: 1);
        }
      }),
    ),
    const Text(
      'Aplica-se a novos registos. Os valores existentes mantêm a moeda original. Sem conversão cambial.',
    ),
    SwitchListTile(
      title: const Text('Gamificação'),
      subtitle: const Text('XP opcional, sem penalizações.'),
      value: prefs['gamification'] == 1,
      onChanged: (value) => act(() async {
        await repo.save('UserPreferences', {
          'gamification': value ? 1 : 0,
        }, id: 1);
      }),
    ),
    heading('Os seus dados'),
    const Text(
      'Guardados localmente neste dispositivo. A aplicação não implementa encriptação. Sem conta nem analytics externos.',
    ),
    ListTile(
      leading: const Icon(Icons.ios_share),
      title: const Text('Exportar dados JSON'),
      onTap: () => act(() async {
        final json = await repo.exportJson();
        await SharePlus.instance.share(
          ShareParams(
            text: json,
            subject: '${TudoAkiBrand.name} — exportação de dados',
          ),
        );
      }),
    ),
    ListTile(
      leading: const Icon(Icons.delete_outline),
      title: const Text('Apagar todos os dados'),
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Apagar todos os dados?'),
            content: const Text(
              'Esta acção não pode ser desfeita. Exporte primeiro se quiser guardar uma cópia.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Apagar'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await act(() async {
            await ref.read(remindersProvider).cancelAll();
            await repo.erase();
          });
        }
      },
    ),
  ];
  List<Widget> finance(Map<String, List<DataRowMap>> data) => [
    const FinancePanel(),
  ];
  List<Widget> academics(Map<String, List<DataRowMap>> data) => [
    AcademicsPanel(taskBuilder: (task) => taskCard(task, data)),
  ];
  List<Widget> reviews(Map<String, List<DataRowMap>> data) => [
    heading(
      'Olhar para trás',
      action: TextButton(
        onPressed: () => showEditor(context, 'Revisão'),
        child: const Text('Nova'),
      ),
    ),
    if (data['PeriodicReviews']!.isEmpty)
      empty(
        'Uma breve reflexão pode ajudar a escolher o próximo passo.',
        'Revisão',
      ),
    ...data['PeriodicReviews']!.reversed.map(
      (r) => Card(
        child: ExpansionTile(
          title: Text('${r['period']} · ${r['day']}'),
          childrenPadding: const EdgeInsets.all(16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Realizações\n${r['achieved']}'),
            const SizedBox(height: 12),
            Text('Pendentes\n${r['pending']}'),
            const SizedBox(height: 12),
            Text('Obstáculos\n${r['obstacles']}'),
            const SizedBox(height: 12),
            Text('Próximas prioridades\n${r['next']}'),
          ],
        ),
      ),
    ),
  ];
}

class MetricDialog extends StatefulWidget {
  const MetricDialog({required this.goal, super.key});
  final DataRowMap goal;
  @override
  State<MetricDialog> createState() => _MetricDialogState();
}

class _MetricDialogState extends State<MetricDialog> {
  late final controller = TextEditingController(
    text: '${widget.goal['current']}',
  );
  String? error;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Resultado actual'),
    content: TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: '${widget.goal['unit']}',
        errorText: error,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          final number = double.tryParse(controller.text.replaceAll(',', '.'));
          if (number != null && number.isFinite) {
            Navigator.pop(context, number);
          } else {
            setState(() => error = 'Introduza um número válido');
          }
        },
        child: const Text('Guardar'),
      ),
    ],
  );
}
