import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../app/providers.dart';
import '../core/database/database.dart';
import 'goals/goal_tree.dart';

Future<void> showEditor(
  BuildContext context,
  String kind, {
  DataRowMap? existing,
  int? goalId,
  int? subjectId,
  int? parentGoalId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => Editor(
    kind: kind,
    existing: existing,
    goalId: goalId,
    subjectId: subjectId,
    parentGoalId: parentGoalId,
  ),
);

class Editor extends ConsumerStatefulWidget {
  const Editor({
    required this.kind,
    this.existing,
    this.goalId,
    this.subjectId,
    this.parentGoalId,
    super.key,
  });
  final String kind;
  final DataRowMap? existing;
  final int? goalId;
  final int? subjectId;
  final int? parentGoalId;
  @override
  ConsumerState<Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<Editor> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  late String category, horizon, recurrence, transactionKind, period;
  late int priority;
  late bool important, paused;
  bool busy = false, remind = false;
  String? error;
  DateTime? due;
  late DateTime start, end;
  int? goalId, subjectId, savingsId, parentGoalId;
  late Set<int> weekdays;
  DataRowMap get original => widget.existing ?? {};
  TextEditingController c(String key, [String fallback = '']) =>
      fields.putIfAbsent(
        key,
        () => TextEditingController(text: '${original[key] ?? fallback}'),
      );
  @override
  void initState() {
    super.initState();
    category = original['category'] as String? ?? 'Pessoal';
    parentGoalId = original['parent_id'] as int? ?? widget.parentGoalId;
    final parent = ref
        .read(dataProvider)
        .valueOrNull?['Goals']
        ?.where((g) => g['id'] == parentGoalId)
        .firstOrNull;
    horizon =
        original['horizon'] as String? ??
        nextGoalHorizon(parent?['horizon'] as String?);
    recurrence = original['recurrence'] as String? ?? 'none';
    transactionKind = original['kind'] as String? ?? 'expense';
    period = original['period'] as String? ?? 'Semanal';
    priority = original['priority'] as int? ?? 1;
    important = original['important'] == 1;
    paused = original['paused'] == 1;
    remind = original['reminder'] == 1;
    goalId = original['goal_id'] as int? ?? widget.goalId;
    subjectId = original['subject_id'] as int? ?? widget.subjectId;
    savingsId = original['savings_id'] as int?;
    due = original['due'] == null
        ? null
        : DateTime.parse(original['due'] as String);
    start = original['start'] == null
        ? DateTime.now().add(const Duration(hours: 1))
        : DateTime.parse(original['start'] as String);
    end = original['end'] == null
        ? start.add(const Duration(hours: 1))
        : DateTime.parse(original['end'] as String);
    weekdays = (original['weekdays'] as String? ?? '1,2,3,4,5,6,7')
        .split(',')
        .map(int.parse)
        .toSet();
    if (widget.kind == 'Transacção' && original['amount_cents'] != null) {
      final cents = original['amount_cents'] as int;
      fields['amount'] = TextEditingController(
        text: '${cents ~/ 100},${(cents % 100).toString().padLeft(2, '0')}',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget text(
    String key,
    String label, {
    String fallback = '',
    bool required = false,
    bool numeric = false,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: c(key, fallback),
      decoration: InputDecoration(labelText: label),
      maxLines: lines,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : lines > 1
          ? TextInputType.multiline
          : TextInputType.text,
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'Preencha este campo';
        }
        if (numeric && value != null && value.isNotEmpty) {
          final n = double.tryParse(value.replaceAll(',', '.'));
          if (n == null || !n.isFinite) {
            return 'Introduza um número válido';
          }
        }
        return null;
      },
    ),
  );
  Widget choice(
    String label,
    String value,
    Map<String, String> options,
    void Function(String) change,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: options.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (v) => setState(() => change(v!)),
    ),
  );
  Widget relation(
    String label,
    int? value,
    List<DataRowMap> rows,
    void Function(int?) change,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem<int>(child: Text('Sem associação')),
        ...rows.map(
          (r) => DropdownMenuItem<int>(
            value: r['id'] as int,
            child: Text(r['title'] as String, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (v) => setState(() => change(v)),
    ),
  );
  Future<DateTime?> pick(DateTime initial) async {
    final day = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (day == null || !mounted) {
      return null;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) {
      return null;
    }
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  Widget dateButton(
    String label,
    DateTime? date,
    void Function(DateTime?) change, {
    bool clear = false,
  }) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () async {
            final result = await pick(
              date ?? DateTime.now().add(const Duration(hours: 1)),
            );
            if (result != null && mounted) {
              setState(() => change(result));
            }
          },
          icon: const Icon(Icons.event),
          label: Text(
            '$label: ${date == null ? 'Escolher' : DateFormat('dd/MM/yyyy HH:mm').format(date)}',
          ),
        ),
      ),
      if (clear && date != null)
        IconButton(
          tooltip: 'Remover data',
          onPressed: () => setState(() => change(null)),
          icon: const Icon(Icons.close),
        ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(dataProvider).valueOrNull;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.existing == null ? 'Criar' : 'Editar'} ${widget.kind.toLowerCase()}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              if (widget.kind != 'Revisão')
                text('title', 'Título', required: true),
              if (widget.kind == 'Tarefa') ...[
                dateButton('Quando', due, (v) => due = v, clear: true),
                const SizedBox(height: 12),
                choice('Prioridade', '$priority', {
                  '0': 'Baixa',
                  '1': 'Normal',
                  '2': 'Alta',
                }, (v) => priority = int.parse(v)),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Importante'),
                  subtitle: const Text(
                    'Priorize também o que tem impacto a longo prazo.',
                  ),
                  value: important,
                  onChanged: (v) => setState(() => important = v),
                ),
                relation(
                  'Meta associada',
                  goalId,
                  data['Goals']!,
                  (v) => goalId = v,
                ),
                relation(
                  'Disciplina',
                  subjectId,
                  data['Subjects']!,
                  (v) => subjectId = v,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Lembrete local'),
                  subtitle: const Text(
                    'Android · horário de Maputo · entrega aproximada. Sem acesso exacto a alarmes.',
                  ),
                  value: remind,
                  onChanged: due == null
                      ? null
                      : (v) => setState(() => remind = v),
                ),
              ],
              if (widget.kind == 'Etapa') ...[
                relation(
                  'Meta associada',
                  goalId,
                  data['Goals']!,
                  (v) => goalId = v,
                ),
                dateButton('Prazo', due, (v) => due = v, clear: true),
                const Text(
                  'Concluir uma etapa não altera a métrica de resultado da meta.',
                ),
              ],
              if (widget.kind == 'Meta') ...[
                relation(
                  'Meta principal (opcional)',
                  parentGoalId,
                  availableGoalParents(data['Goals']!, original['id'] as int?),
                  (v) => parentGoalId = v,
                ),
                text('description', 'Porque é importante?', lines: 2),
                choice('Horizonte', horizon, {
                  for (final h in ['Anual', 'Trimestral', 'Mensal', 'Semanal'])
                    h: h,
                }, (v) => horizon = v),
                text('category', 'Área de vida', fallback: 'Pessoal'),
                text(
                  'unit',
                  'Métrica de sucesso (ex.: livros)',
                  fallback: 'unidades',
                  required: true,
                ),
                text(
                  'initial',
                  'Valor inicial',
                  fallback: '0',
                  required: true,
                  numeric: true,
                ),
                text(
                  'target',
                  'Valor pretendido',
                  fallback: '1',
                  required: true,
                  numeric: true,
                ),
                dateButton('Prazo', due, (v) => due = v, clear: true),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'O progresso usa resultados medidos. Concluir tarefas não altera esta métrica.',
                  ),
                ),
              ],
              if (widget.kind == 'Evento') ...[
                dateButton('Início', start, (v) => start = v!),
                dateButton('Fim', end, (v) => end = v!),
                const SizedBox(height: 12),
                choice('Repetir', recurrence, {
                  'none': 'Não repetir',
                  'daily': 'Todos os dias',
                  'weekly': 'Todas as semanas',
                }, (v) => recurrence = v),
                const Text('Editar um evento recorrente altera toda a série.'),
              ],
              if (widget.kind == 'Hábito') ...[
                text('cue', 'Quando acontecer X, farei Y', lines: 2),
                text('category', 'Área (ex.: bem-estar)', fallback: 'Pessoal'),
                relation(
                  'Meta associada',
                  goalId,
                  data['Goals']!,
                  (v) => goalId = v,
                ),
                const Text('Dias da semana'),
                Wrap(
                  spacing: 4,
                  children: [
                    for (var i = 1; i <= 7; i++)
                      FilterChip(
                        label: Text(
                          ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'][i -
                              1],
                        ),
                        selected: weekdays.contains(i),
                        onSelected: (v) => setState(() {
                          v ? weekdays.add(i) : weekdays.remove(i);
                        }),
                      ),
                  ],
                ),
                SwitchListTile(
                  title: const Text('Em pausa'),
                  value: paused,
                  onChanged: (v) => setState(() => paused = v),
                ),
              ],
              if (widget.kind == 'Transacção') ...[
                text('amount', 'Valor em MT (ex.: 1250,50)', required: true),
                choice('Tipo', transactionKind, {
                  'income': 'Receita',
                  'expense': 'Despesa',
                  'saving': 'Contribuição para poupança',
                }, (v) => transactionKind = v),
                text('category', 'Categoria', fallback: 'Geral'),
                if (transactionKind == 'saving')
                  relation(
                    'Meta de poupança',
                    savingsId,
                    data['SavingsGoals']!,
                    (v) => savingsId = v,
                  ),
              ],
              if (widget.kind == 'Poupança')
                text('amount', 'Valor pretendido em MT', required: true),
              if (widget.kind == 'Revisão') ...[
                choice('Período', period, {
                  'Semanal': 'Semanal',
                  'Mensal': 'Mensal',
                }, (v) => period = v),
                text('achieved', 'O que consegui realizar?', lines: 3),
                text('pending', 'O que ficou pendente?', lines: 3),
                text('obstacles', 'Quais foram os obstáculos?', lines: 3),
                text(
                  'next',
                  'O que quero priorizar a seguir?',
                  required: true,
                  lines: 3,
                ),
              ],
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: busy ? null : save,
                child: Text(busy ? 'A guardar…' : 'Guardar'),
              ),
              if (widget.existing != null)
                TextButton(
                  onPressed: busy ? null : remove,
                  child: const Text('Eliminar'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String value(String key, [String fallback = '']) =>
      c(key, fallback).text.trim();
  double number(String key, [String fallback = '0']) =>
      double.parse(value(key, fallback).replaceAll(',', '.'));
  String get table => switch (widget.kind) {
    'Tarefa' => 'Tasks',
    'Meta' => 'Goals',
    'Etapa' => 'GoalMilestones',
    'Evento' => 'CalendarEvents',
    'Hábito' => 'Habits',
    'Transacção' => 'FinancialTransactions',
    'Poupança' => 'SavingsGoals',
    'Disciplina' => 'Subjects',
    'Revisão' => 'PeriodicReviews',
    _ => throw StateError('Tipo desconhecido'),
  };
  Future<void> save() async {
    if (!form.currentState!.validate()) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final now = DateTime.now();
      final id = original['id'] as int?;
      final row = <String, dynamic>{};
      if (widget.kind != 'Revisão') {
        row['title'] = value('title');
      }
      switch (widget.kind) {
        case 'Tarefa':
          row.addAll({
            'due': due?.toIso8601String(),
            'priority': priority,
            'important': important ? 1 : 0,
            'reminder': remind && due != null ? 1 : 0,
            'goal_id': goalId,
            'subject_id': subjectId,
          });
          if (id == null) {
            row['created'] = now.toIso8601String();
          }
        case 'Etapa':
          if (goalId == null) {
            throw const FormatException('Escolha a meta desta etapa.');
          }
          row.addAll({'goal_id': goalId, 'due': due?.toIso8601String()});
        case 'Meta':
          final initial = number('initial');
          final target = number('target', '1');
          if (target <= initial) {
            throw const FormatException('O alvo deve superar o valor inicial.');
          }
          row.addAll({
            'description': value('description'),
            'category': value('category', 'Pessoal'),
            'horizon': horizon,
            'parent_id': parentGoalId,
            'unit': value('unit', 'unidades'),
            'initial': initial,
            'target': target,
            'due': due?.toIso8601String(),
          });
          if (id == null) {
            row.addAll({'current': initial, 'created': now.toIso8601String()});
          } else {
            row['status'] = (original['current'] as num) >= target
                ? 'completed'
                : 'active';
          }
        case 'Evento':
          if (!end.isAfter(start)) {
            throw const FormatException('O fim deve ser posterior ao início.');
          }
          row.addAll({
            'start': start.toIso8601String(),
            'end': end.toIso8601String(),
            'recurrence': recurrence,
          });
        case 'Hábito':
          if (weekdays.isEmpty) {
            throw const FormatException('Escolha pelo menos um dia.');
          }
          row.addAll({
            'cue': value('cue'),
            'category': value('category', 'Pessoal'),
            'weekdays': (weekdays.toList()..sort()).join(','),
            'paused': paused ? 1 : 0,
            'goal_id': goalId,
          });
        case 'Transacção':
          if (transactionKind == 'saving' && savingsId == null) {
            throw const FormatException('Escolha uma meta de poupança.');
          }
          row.addAll({
            'amount_cents': moneyCents(value('amount')),
            'kind': transactionKind,
            'category': value('category', 'Geral'),
            'day': original['day'] ?? dayKey(now),
            'savings_id': transactionKind == 'saving' ? savingsId : null,
          });
        case 'Poupança':
          row['target_cents'] = moneyCents(value('amount'));
        case 'Disciplina':
          break;
        case 'Revisão':
          row.addAll({
            'period': period,
            'day': dayKey(now),
            'achieved': value('achieved'),
            'pending': value('pending'),
            'obstacles': value('obstacles'),
            'next': value('next'),
          });
      }
      final savedId = await ref
          .read(repositoryProvider)
          .save(table, row, id: id);
      String? warning;
      if (widget.kind == 'Tarefa' && (remind || original['reminder'] == 1)) {
        try {
          final reminders = ref.read(remindersProvider);
          await reminders.cancel(savedId);
          if (remind &&
              original['completed'] != 1 &&
              due != null &&
              !await reminders.schedule(savedId, value('title'), due!)) {
            warning =
                'Tarefa guardada. Lembrete indisponível: verifique a permissão, a data futura e o suporte Android.';
          }
        } catch (_) {
          warning =
              'Tarefa guardada, mas não foi possível configurar o lembrete.';
        }
      }
      ref.invalidate(dataProvider);
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      if (warning != null) {
        messenger.showSnackBar(SnackBar(content: Text(warning)));
      }
    } on FormatException catch (e) {
      if (mounted) {
        setState(() => error = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Não foi possível guardar. Verifique os dados; títulos de disciplinas não podem repetir-se.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar este registo?'),
        content: Text(
          widget.kind == 'Meta'
              ? 'As etapas e o histórico desta meta serão eliminados. As submetas, tarefas e hábitos serão preservados sem ligação a esta meta.'
              : widget.kind == 'Disciplina'
              ? 'Os horários desta disciplina serão eliminados. As tarefas, avaliações e sessões de estudo serão preservadas sem associação.'
              : widget.kind == 'Etapa'
              ? 'A etapa será eliminada. A meta e as tarefas serão preservadas.'
              : 'Esta acção não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    setState(() => busy = true);
    try {
      if (widget.kind == 'Tarefa' && original['reminder'] == 1) {
        await ref.read(remindersProvider).cancel(original['id'] as int);
      }
      await ref.read(repositoryProvider).delete(table, original['id'] as int);
      ref.invalidate(dataProvider);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'Não foi possível eliminar. Tente novamente.';
          busy = false;
        });
      }
    }
  }
}
