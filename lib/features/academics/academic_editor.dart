import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/providers.dart';
import '../../core/database/database.dart';
import 'academic_rules.dart';
import 'study_repository.dart';

Future<void> showAcademicEditor(
  BuildContext context,
  String kind, {
  DataRowMap? existing,
  int? subjectId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) =>
      AcademicEditor(kind: kind, existing: existing, subjectId: subjectId),
);

class AcademicEditor extends ConsumerStatefulWidget {
  const AcademicEditor({
    required this.kind,
    this.existing,
    this.subjectId,
    super.key,
  });
  final String kind;
  final DataRowMap? existing;
  final int? subjectId;
  @override
  ConsumerState<AcademicEditor> createState() => _AcademicEditorState();
}

class _AcademicEditorState extends ConsumerState<AcademicEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title, duration, location;
  late DateTime at, from;
  DateTime? until;
  int? subject;
  late int weekday, startMinute, endMinute;
  late String assessmentKind;
  bool busy = false;
  String? error;
  DataRowMap get original => widget.existing ?? {};
  String get table => switch (widget.kind) {
    'Aula' => 'ClassSchedules',
    'Avaliação' => 'Assessments',
    _ => 'StudySessions',
  };
  @override
  void initState() {
    super.initState();
    title = TextEditingController(
      text:
          original['title'] as String? ??
          (widget.kind == 'Estudo' ? 'Sessão de estudo' : ''),
    );
    duration = TextEditingController(
      text: '${original['minutes'] ?? (widget.kind == 'Estudo' ? 25 : 60)}',
    );
    location = TextEditingController(
      text: original['location'] as String? ?? '',
    );
    subject = original['subject_id'] as int? ?? widget.subjectId;
    weekday = original['weekday'] as int? ?? DateTime.now().weekday;
    startMinute = original['start_minute'] as int? ?? 480;
    endMinute = original['end_minute'] as int? ?? 540;
    assessmentKind = original['kind'] as String? ?? 'Teste';
    at =
        DateTime.tryParse(
          original[widget.kind == 'Avaliação' ? 'at' : 'start'] as String? ??
              '',
        )?.toLocal() ??
        DateTime.now().add(const Duration(hours: 1));
    from =
        DateTime.tryParse(original['active_from'] as String? ?? '') ??
        DateTime.now();
    until = DateTime.tryParse(original['active_until'] as String? ?? '');
  }

  @override
  void dispose() {
    title.dispose();
    duration.dispose();
    location.dispose();
    super.dispose();
  }

  Widget field(
    TextEditingController controller,
    String label, {
    bool numeric = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Preencha este campo';
        if (numeric) {
          final number = int.tryParse(value);
          final max = widget.kind == 'Estudo' ? 180 : 480;
          if (number == null || number < 1 || number > max) {
            return 'Use um número entre 1 e $max';
          }
        }
        return null;
      },
    ),
  );
  Future<DateTime?> date(DateTime initial) => showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  Future<void> chooseTime(bool start) async {
    final minute = start ? startMinute : endMinute;
    final value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (minute ~/ 60) % 24, minute: minute % 60),
    );
    if (value != null && mounted) {
      setState(() {
        if (start) {
          startMinute = value.hour * 60 + value.minute;
        } else {
          endMinute = value.hour == 0 && value.minute == 0
              ? 1440
              : value.hour * 60 + value.minute;
        }
      });
    }
  }

  Future<void> chooseAt() async {
    final day = await date(at);
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(at),
    );
    if (time != null && mounted) {
      setState(
        () =>
            at = DateTime(day.year, day.month, day.day, time.hour, time.minute),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(dataProvider).valueOrNull;
    if (data == null) return const Center(child: CircularProgressIndicator());
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
              if (widget.kind != 'Aula') field(title, 'Título'),
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: subject,
                decoration: const InputDecoration(labelText: 'Disciplina'),
                items: [
                  if (widget.kind != 'Aula')
                    const DropdownMenuItem<int>(child: Text('Sem disciplina')),
                  for (final row in data['Subjects']!)
                    DropdownMenuItem(
                      value: row['id'] as int,
                      child: Text(
                        row['title'] as String,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => subject = value),
                validator: (value) => widget.kind == 'Aula' && value == null
                    ? 'Escolha uma disciplina'
                    : null,
              ),
              const SizedBox(height: 12),
              if (widget.kind == 'Aula') ...[
                const Text(
                  'O horário repete-se semanalmente no período definido. Editar altera as ocorrências desse período.',
                ),
                DropdownButtonFormField<int>(
                  initialValue: weekday,
                  decoration: const InputDecoration(labelText: 'Dia da semana'),
                  items: [
                    for (var i = 1; i <= 7; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(weekdayLabels[i - 1]),
                      ),
                  ],
                  onChanged: (value) => setState(() => weekday = value!),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => chooseTime(true),
                      child: Text('Início: ${clockLabel(startMinute)}'),
                    ),
                    OutlinedButton(
                      onPressed: () => chooseTime(false),
                      child: Text('Fim: ${clockLabel(endMinute)}'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: location,
                  decoration: const InputDecoration(
                    labelText: 'Local (opcional)',
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final value = await date(from);
                    if (value != null && mounted) setState(() => from = value);
                  },
                  child: Text(
                    'Válido desde: ${DateFormat('dd/MM/yyyy').format(from)}',
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final value = await date(until ?? from);
                          if (value != null && mounted) {
                            setState(() => until = value);
                          }
                        },
                        child: Text(
                          'Até: ${until == null ? 'Sem data final' : DateFormat('dd/MM/yyyy').format(until!)}',
                        ),
                      ),
                    ),
                    if (until != null)
                      IconButton(
                        tooltip: 'Remover data final',
                        onPressed: () => setState(() => until = null),
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ] else ...[
                if (widget.kind == 'Avaliação') ...[
                  DropdownButtonFormField<String>(
                    initialValue: assessmentKind,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: [
                      for (final type in ['Teste', 'Exame', 'Apresentação'])
                        DropdownMenuItem(value: type, child: Text(type)),
                    ],
                    onChanged: (value) =>
                        setState(() => assessmentKind = value!),
                  ),
                  const SizedBox(height: 12),
                ],
                field(duration, 'Duração em minutos', numeric: true),
                OutlinedButton.icon(
                  onPressed: chooseAt,
                  icon: const Icon(Icons.event),
                  label: Text(
                    'Quando: ${DateFormat('dd/MM/yyyy HH:mm').format(at)}',
                  ),
                ),
                if (widget.kind == 'Estudo')
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Planeie o bloco agora e inicie o foco quando estiver pronto. Pode pausar sem perder o tempo restante.',
                    ),
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

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      final repo = ref.read(repositoryProvider);
      final id = original['id'] as int?;
      if (widget.kind == 'Aula') {
        if (endMinute <= startMinute) {
          throw const FormatException(
            'O fim deve ser posterior ao início, no mesmo dia.',
          );
        }
        if (until != null && dayKey(until!).compareTo(dayKey(from)) < 0) {
          throw const FormatException(
            'A data final deve ser igual ou posterior à inicial.',
          );
        }
        await repo.save(table, {
          'subject_id': subject,
          'weekday': weekday,
          'start_minute': startMinute,
          'end_minute': endMinute,
          'location': location.text.trim(),
          'active_from': dayKey(from),
          'active_until': until == null ? null : dayKey(until!),
        }, id: id);
      } else if (widget.kind == 'Estudo') {
        await repo.saveStudy(
          id: id,
          title: title.text,
          start: at,
          minutes: int.parse(duration.text),
          subjectId: subject,
        );
      } else {
        await repo.save(table, {
          'subject_id': subject,
          'title': title.text.trim(),
          'kind': assessmentKind,
          'at': at.toIso8601String(),
          'minutes': int.parse(duration.text),
        }, id: id);
      }
      container.invalidate(dataProvider);
      if (mounted) Navigator.pop(context);
    } on FormatException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Não foi possível guardar. Verifique os dados e tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> remove() async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar este registo?'),
        content: const Text('Esta acção não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (answer != true || !mounted) return;
    setState(() => busy = true);
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      await ref.read(repositoryProvider).delete(table, original['id'] as int);
      container.invalidate(dataProvider);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'Não foi possível eliminar.';
        });
      }
    }
  }
}
