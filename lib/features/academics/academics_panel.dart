import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/providers.dart';
import '../../core/database/database.dart';
import '../forms.dart';
import 'academic_editor.dart';
import 'academic_rules.dart';
import 'focus_timer.dart';

class AcademicsPanel extends ConsumerStatefulWidget {
  const AcademicsPanel({required this.taskBuilder, super.key});
  final Widget Function(DataRowMap task) taskBuilder;
  @override
  ConsumerState<AcademicsPanel> createState() => _AcademicsPanelState();
}

class _AcademicsPanelState extends ConsumerState<AcademicsPanel> {
  int? selectedStudy;
  Future<void> run(Future<void> Function() operation) async {
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      await operation();
      container.invalidate(dataProvider);
    } on FormatException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível actualizar. Tente novamente.'),
          ),
        );
      }
    }
  }

  Widget section(String title) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
  );
  String civilDate(String date) =>
      DateFormat('dd/MM/yyyy').format(DateTime.parse(date));
  String stamp(String date) =>
      DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(date).toLocal());

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(dataProvider).valueOrNull;
    if (data == null) return const SizedBox.shrink();
    final subjects = {for (final s in data['Subjects']!) s['id']: s['title']};
    final sessions = data['StudySessions']!;
    final active = sessions
        .where((s) => s['completed'] == 0 && s['focus_end'] != null)
        .firstOrNull;
    final selected =
        active ?? sessions.where((s) => s['id'] == selectedStudy).firstOrNull;
    final pending = sessions.where((s) => s['completed'] == 0).toList()
      ..sort((a, b) => (a['start'] as String).compareTo(b['start'] as String));
    final completed = sessions.where((s) => s['completed'] == 1).toList()
      ..sort(
        (a, b) => (b['completed_at'] as String? ?? b['start'] as String)
            .compareTo(a['completed_at'] as String? ?? a['start'] as String),
      );
    final assessments = data['Assessments']!.toList()
      ..sort((a, b) => (a['at'] as String).compareTo(b['at'] as String));
    final now = ref.watch(studyClockProvider)();
    final deadlines = data['Tasks']!.where(
      (t) =>
          t['subject_id'] != null &&
          t['completed'] == 0 &&
          t['due'] != null &&
          DateTime.parse(
            t['due'] as String,
          ).isBefore(now.add(const Duration(days: 7))),
    );
    Widget studyCard(DataRowMap s) {
      final done = s['completed'] == 1;
      final started = s['focus_started_at'] != null;
      return Card(
        child: ListTile(
          title: Text(s['title'] as String),
          subtitle: Text(
            '${subjects[s['subject_id']] ?? 'Sem disciplina'} · ${s['minutes']} min\n${done ? 'Concluída: ${stamp(s['completed_at'] as String? ?? s['start'] as String)}' : 'Planeada: ${stamp(s['start'] as String)}'}',
          ),
          isThreeLine: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!done && !started)
                IconButton(
                  tooltip: 'Editar sessão',
                  onPressed: () =>
                      showAcademicEditor(context, 'Estudo', existing: s),
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (!done)
                IconButton(
                  tooltip: started ? 'Retomar foco' : 'Abrir foco',
                  onPressed: active != null && active['id'] != s['id']
                      ? null
                      : () => setState(() => selectedStudy = s['id'] as int),
                  icon: const Icon(Icons.timer_outlined),
                ),
              IconButton(
                tooltip: 'Eliminar sessão',
                onPressed: () async {
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Eliminar sessão?'),
                      content: const Text(
                        'O registo será eliminado. Uma sessão em curso será interrompida, sem penalização de XP.',
                      ),
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
                  if (yes == true && mounted) {
                    await run(
                      () => ref
                          .read(repositoryProvider)
                          .delete('StudySessions', s['id'] as int),
                    );
                  }
                },
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      );
    }

    Widget assessmentCard(DataRowMap assessment) => Card(
      child: ListTile(
        leading: Checkbox(
          value: assessment['completed'] == 1,
          onChanged: (value) => run(() async {
            await ref.read(repositoryProvider).save('Assessments', {
              'completed': value! ? 1 : 0,
            }, id: assessment['id'] as int);
          }),
        ),
        title: Text(assessment['title'] as String),
        subtitle: Text(
          '${assessment['kind']} · ${subjects[assessment['subject_id']] ?? 'Sem disciplina'}\n${stamp(assessment['at'] as String)} · ${assessment['minutes']} min',
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'Editar avaliação',
          onPressed: () =>
              showAcademicEditor(context, 'Avaliação', existing: assessment),
          icon: const Icon(Icons.edit_outlined),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Planeie o estudo com flexibilidade. Uma pausa não apaga o seu progresso.',
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => showAcademicEditor(context, 'Estudo'),
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Planear estudo'),
            ),
            OutlinedButton.icon(
              onPressed: () => showAcademicEditor(context, 'Avaliação'),
              icon: const Icon(Icons.event_note_outlined),
              label: const Text('Nova avaliação'),
            ),
          ],
        ),
        if (selected != null)
          FocusTimerCard(
            key: ValueKey('focus-${selected['id']}'),
            session: selected,
            onClose: () => setState(() => selectedStudy = null),
          ),
        if (data['UserPreferences']!.first['gamification'] == 1)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              '$studyExperiencePoints XP por sessão de foco concluída, até $dailyRewardedStudySessions por dia. Todas as sessões ficam no histórico.',
            ),
          ),
        section('Sessões de estudo'),
        if (pending.isEmpty)
          const Text(
            'Sem sessões planeadas. Escolha uma duração que funcione para si.',
          ),
        ...pending.map(studyCard),
        if (completed.isNotEmpty)
          ExpansionTile(
            title: Text('Histórico de estudo (${completed.length})'),
            subtitle: Text(
              '${completed.fold<int>(0, (sum, s) => sum + (s['minutes'] as int))} minutos concluídos',
            ),
            children: completed.map(studyCard).toList(),
          ),
        section('Avaliações'),
        if (assessments.isEmpty)
          const Text(
            'Os próximos testes, exames e apresentações aparecem aqui.',
          ),
        ...assessments.where((a) => a['completed'] == 0).map(assessmentCard),
        if (assessments.any((a) => a['completed'] == 1))
          ExpansionTile(
            title: Text(
              'Avaliações realizadas (${assessments.where((a) => a['completed'] == 1).length})',
            ),
            children: assessments
                .where((a) => a['completed'] == 1)
                .toList()
                .reversed
                .map(assessmentCard)
                .toList(),
          ),
        if (deadlines.isNotEmpty) ...[
          section('Trabalhos e prazos próximos'),
          ...deadlines.map(widget.taskBuilder),
        ],
        Row(
          children: [
            Expanded(child: section('Disciplinas')),
            TextButton(
              onPressed: () => showEditor(context, 'Disciplina'),
              child: const Text('Adicionar disciplina'),
            ),
          ],
        ),
        if (data['Subjects']!.isEmpty)
          const Text(
            'Adicione uma disciplina para organizar aulas e trabalhos.',
          ),
        for (final subject in data['Subjects']!)
          Card(
            child: ExpansionTile(
              key: PageStorageKey('subject-${subject['id']}'),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(subject['title'] as String),
              trailing: IconButton(
                tooltip: 'Editar disciplina',
                onPressed: () =>
                    showEditor(context, 'Disciplina', existing: subject),
                icon: const Icon(Icons.edit_outlined),
              ),
              childrenPadding: const EdgeInsets.all(12),
              children: [
                for (final schedule in data['ClassSchedules']!.where(
                  (c) => c['subject_id'] == subject['id'],
                ))
                  ListTile(
                    leading: const Icon(Icons.school_outlined),
                    title: Text(
                      '${weekdayLabels[(schedule['weekday'] as int) - 1]} · ${clockLabel(schedule['start_minute'] as int)}–${clockLabel(schedule['end_minute'] as int)}',
                    ),
                    subtitle: Text(
                      '${schedule['location']}\n${civilDate(schedule['active_from'] as String)}${schedule['active_until'] == null ? ' em diante' : ' até ${civilDate(schedule['active_until'] as String)}'}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Editar aula',
                      onPressed: () => showAcademicEditor(
                        context,
                        'Aula',
                        existing: schedule,
                      ),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => showAcademicEditor(
                        context,
                        'Aula',
                        subjectId: subject['id'] as int,
                      ),
                      child: const Text('Adicionar aula'),
                    ),
                    TextButton(
                      onPressed: () => showAcademicEditor(
                        context,
                        'Avaliação',
                        subjectId: subject['id'] as int,
                      ),
                      child: const Text('Adicionar avaliação'),
                    ),
                    TextButton(
                      onPressed: () => showAcademicEditor(
                        context,
                        'Estudo',
                        subjectId: subject['id'] as int,
                      ),
                      child: const Text('Adicionar estudo'),
                    ),
                    TextButton(
                      onPressed: () => showEditor(
                        context,
                        'Tarefa',
                        subjectId: subject['id'] as int,
                      ),
                      child: const Text('Adicionar trabalho'),
                    ),
                  ],
                ),
                ...data['Tasks']!
                    .where((t) => t['subject_id'] == subject['id'])
                    .map(widget.taskBuilder),
              ],
            ),
          ),
      ],
    );
  }
}
