import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../core/database/database.dart';
import '../../../core/theme/premium_tokens.dart';
import '../domain/task_operations.dart';

/// Creates tasks only. Existing tasks continue to use the complete Editor.
/// initialDate supplies a civil day, never an implicit appointment time.
Future<TaskWriteResult?> showQuickTaskSheet(
  BuildContext context, {
  DateTime? initialDate,
  int? goalId,
  int? subjectId,
}) => showModalBottomSheet<TaskWriteResult>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  isDismissible: false,
  enableDrag: false,
  builder: (_) => QuickTaskSheet(
    initialDate: initialDate,
    goalId: goalId,
    subjectId: subjectId,
  ),
);

class QuickTaskSheet extends ConsumerStatefulWidget {
  const QuickTaskSheet({
    this.initialDate,
    this.goalId,
    this.subjectId,
    super.key,
  });
  final DateTime? initialDate;
  final int? goalId, subjectId;
  @override
  ConsumerState<QuickTaskSheet> createState() => _QuickTaskSheetState();
}

class _QuickTaskSheetState extends ConsumerState<QuickTaskSheet> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _titleFocus = FocusNode();
  DateTime? _day, _baselineDay;
  TimeOfDay? _time;
  int? _goal, _subject, _baselineGoal, _baselineSubject;
  int _priority = 1;
  bool _important = false, _remind = false, _advanced = false;
  bool _busy = false, _closing = false;
  String? _error, _confirmation;
  TaskWriteResult? _lastSaved;

  @override
  void initState() {
    super.initState();
    final date = widget.initialDate;
    _day = date == null ? null : DateTime(date.year, date.month, date.day);
    _goal = widget.goalId;
    _subject = widget.subjectId;
    _setBaseline();
  }

  void _setBaseline() {
    _baselineDay = _day;
    _baselineGoal = _goal;
    _baselineSubject = _subject;
  }

  bool get _dirty =>
      _title.text.isNotEmpty ||
      _day != _baselineDay ||
      _time != null ||
      _remind ||
      _priority != 1 ||
      _important ||
      _goal != _baselineGoal ||
      _subject != _baselineSubject;

  @override
  void dispose() {
    _title.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_busy || _closing) return;
    _closing = true;
    try {
      if (_dirty) {
        final discard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Descartar alterações?'),
            content: const Text('Só o rascunho actual será descartado.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Continuar a editar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Descartar'),
              ),
            ],
          ),
        );
        if (discard != true) return;
      }
      if (mounted) Navigator.pop(context, _lastSaved);
    } finally {
      _closing = false;
    }
  }

  Future<void> _chooseDay() async {
    final first = DateTime(2000), last = DateTime(2100, 12, 31);
    final date = _day ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: date.isBefore(first)
          ? first
          : date.isAfter(last)
          ? last
          : date,
      firstDate: first,
      lastDate: last,
    );
    if (selected != null && mounted) setState(() => _day = selected);
  }

  Future<void> _chooseTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (selected != null && mounted) setState(() => _time = selected);
  }

  Future<void> _save({bool another = false}) async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final operations = ref.read(taskOperationsProvider);
      final day = _day, time = _time;
      final due = day == null
          ? null
          : time == null
          ? dayKey(day)
          : DateTime(
              day.year,
              day.month,
              day.day,
              time.hour,
              time.minute,
            ).toIso8601String();
      final result = await operations.create({
        'title': _title.text.trim(),
        'due': due,
        'priority': _priority,
        'important': _important ? 1 : 0,
        'reminder': _remind && day != null && time != null ? 1 : 0,
        'goal_id': _goal,
        'subject_id': _subject,
      });
      if (!mounted) return;
      _lastSaved = result;
      if (!another) {
        Navigator.pop(context, result);
        return;
      }
      setState(() {
        _title.clear();
        _time = null;
        _remind = false;
        _priority = 1;
        _important = false;
        _advanced = false;
        _confirmation = result.reminderFailure == null
            ? 'Tarefa guardada.'
            : 'Tarefa guardada; lembrete indisponível.';
        _setBaseline();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _titleFocus.requestFocus();
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível guardar. Tenta novamente.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _relation(
    String label,
    int? selected,
    List<DataRowMap> rows,
    void Function(int?) change,
  ) => DropdownButtonFormField<int>(
    key: ValueKey('quick-$label-$selected'),
    initialValue: selected,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      const DropdownMenuItem<int>(child: Text('Sem associação')),
      if (selected != null && !rows.any((row) => row['id'] == selected))
        DropdownMenuItem(
          value: selected,
          child: const Text('Associação indisponível'),
        ),
      for (final row in rows)
        DropdownMenuItem(
          value: row['id'] as int,
          child: Text(row['title'] as String, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: _busy ? null : (value) => setState(() => change(value)),
  );

  String _associationLabel(List<DataRowMap> rows, int id, String fallback) =>
      rows.where((row) => row['id'] == id).firstOrNull?['title'] as String? ??
      fallback;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(dataProvider);
    final goals = data.valueOrNull?['Goals'] ?? <DataRowMap>[];
    final subjects = data.valueOrNull?['Subjects'] ?? <DataRowMap>[];
    return PopScope<TaskWriteResult>(
      canPop: !_busy && !_dirty && _lastSaved == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Form(
            key: _form,
            child: LayoutBuilder(
              builder: (context, bounds) {
                final fields = Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (PremiumTokens.active(context) &&
                        MediaQuery.textScalerOf(context).scale(1) > 1.3)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              'Nova tarefa',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _busy ? null : _close,
                              child: const Text('Cancelar'),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(
                                'Nova tarefa',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _busy ? null : _close,
                            child: const Text('Cancelar'),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _title,
                      focusNode: _titleFocus,
                      autofocus: true,
                      readOnly: _busy,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        hintText: 'O que queres fazer?',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Escreve um título.'
                          : null,
                      onChanged: (_) => setState(() {}),
                      onEditingComplete: () {},
                      onFieldSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: _busy ? null : _chooseDay,
                          child: Text(
                            'Dia: ${_day == null ? 'Sem data' : DateFormat('d MMM yyyy', 'pt').format(_day!)}',
                          ),
                        ),
                        if (_day != null)
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                    _day = null;
                                    _time = null;
                                    _remind = false;
                                  }),
                            child: const Text('Retirar dia'),
                          ),
                      ],
                    ),
                    if (_goal != null)
                      Text(
                        'Meta: ${_associationLabel(goals, _goal!, 'Meta associada')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (_subject != null)
                      Text(
                        'Disciplina: ${_associationLabel(subjects, _subject!, 'Disciplina associada')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() => _advanced = !_advanced),
                        child: Text(_advanced ? 'Menos opções' : 'Mais opções'),
                      ),
                    ),
                    if (_advanced) ...[
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: _busy || _day == null
                                ? null
                                : _chooseTime,
                            child: Text(
                              _time == null
                                  ? 'Definir hora'
                                  : 'Hora: ${_time!.format(context)}',
                            ),
                          ),
                          if (_time != null)
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => setState(() {
                                      _time = null;
                                      _remind = false;
                                    }),
                              child: const Text('Retirar hora'),
                            ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Lembrete local'),
                        subtitle: const Text(
                          'Exige dia e hora. Entrega aproximada no Android.',
                        ),
                        value: _remind,
                        onChanged: _busy || _day == null || _time == null
                            ? null
                            : (value) => setState(() => _remind = value),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        key: ValueKey('quick-priority-$_priority'),
                        initialValue: _priority,
                        decoration: const InputDecoration(
                          labelText: 'Prioridade',
                        ),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Baixa')),
                          DropdownMenuItem(value: 1, child: Text('Normal')),
                          DropdownMenuItem(value: 2, child: Text('Alta')),
                        ],
                        onChanged: _busy
                            ? null
                            : (value) => setState(() => _priority = value!),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Importante'),
                        value: _important,
                        onChanged: _busy
                            ? null
                            : (value) => setState(() => _important = value),
                      ),
                      if (data.isLoading)
                        const LinearProgressIndicator(
                          semanticsLabel: 'A carregar associações',
                        ),
                      if (data.hasError)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => ref.invalidate(dataProvider),
                          child: const Text(
                            'Repetir carregamento das associações',
                          ),
                        ),
                      _relation(
                        'Meta associada',
                        _goal,
                        goals,
                        (value) => _goal = value,
                      ),
                      const SizedBox(height: 16),
                      _relation(
                        'Disciplina',
                        _subject,
                        subjects,
                        (value) => _subject = value,
                      ),
                    ],
                    if (_error != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    if (_confirmation != null)
                      Semantics(liveRegion: true, child: Text(_confirmation!)),
                  ],
                );
                final footer = LayoutBuilder(
                  builder: (context, constraints) {
                    final actions = <Widget>[
                      FilledButton(
                        onPressed: _busy || _title.text.trim().isEmpty
                            ? null
                            : () => _save(),
                        child: Text(_busy ? 'A guardar…' : 'Guardar'),
                      ),
                      if (_title.text.trim().isNotEmpty || _advanced)
                        TextButton(
                          onPressed: _busy || _title.text.trim().isEmpty
                              ? null
                              : () => _save(another: true),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Guardar e adicionar outra',
                            maxLines: 3,
                            softWrap: true,
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: constraints.maxWidth >= 600
                          ? Row(
                              children: [
                                Expanded(child: actions[0]),
                                if (actions.length > 1) ...[
                                  const SizedBox(width: 8),
                                  Expanded(child: actions[1]),
                                ],
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: actions,
                            ),
                    );
                  },
                );
                // Very short windows (including keyboard/route transitions) need
                // a single scroll surface rather than an overflowing fixed bar.
                final actionLine = MediaQuery.textScalerOf(context).scale(20);
                final minimumHeight = bounds.maxWidth >= 600
                    ? actionLine * 2 + 32
                    : actionLine * 2 + 80;
                if (bounds.maxHeight < minimumHeight) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [fields, footer],
                    ),
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(child: SingleChildScrollView(child: fields)),
                    footer,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
