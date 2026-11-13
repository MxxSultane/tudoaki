import 'package:flutter/material.dart';
import '../agenda/domain/today_content.dart' show localTaskDate;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/providers.dart';
import '../../core/database/database.dart';
import '../forms.dart';
import '../tasks/presentation/quick_task_sheet.dart';
import '../tasks/domain/task_operations.dart';
import 'academic_editor.dart';
import 'academic_rules.dart';
import 'focus_timer.dart';
import '../../core/widgets/premium_components.dart';

class AcademicsPanel extends ConsumerStatefulWidget {
  const AcademicsPanel({required this.taskBuilder, super.key});
  final Widget Function(DataRowMap task) taskBuilder;
  @override
  ConsumerState<AcademicsPanel> createState() => _AcademicsPanelState();
}

class _AcademicsPanelState extends ConsumerState<AcademicsPanel> {
  int? selectedStudy;
  int? _taskSubject;
  TaskWriteResult? _createdTask;

  Future<void> _createTask(int subjectId) async {
    final result = await showQuickTaskSheet(context, subjectId: subjectId);
    if (result != null && mounted) {
      setState(() {
        _taskSubject = subjectId;
        _createdTask = result;
      });
    }
  }

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
    child: Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    ),
  );
  String civilDate(String date) =>
      DateFormat('dd/MM/yyyy').format(DateTime.parse(date));
  String stamp(String date) =>
      DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(date).toLocal());

  Future<void> deleteStudy(DataRowMap session) async {
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
            .delete('StudySessions', session['id'] as int),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(dataProvider).valueOrNull;
    if (data == null) return const SizedBox.shrink();
    final subjects = {for (final s in data['Subjects']!) s['id']: s['title']};
    final sessions = data['StudySessions']!;
    final pending = sessions.where((s) => s['completed'] == 0).toList()
      ..sort((a, b) => (a['start'] as String).compareTo(b['start'] as String));
    final active = pending.where((s) => s['focus_end'] != null).firstOrNull;
    final resumable =
        active ??
        pending.where((s) => s['focus_started_at'] != null).firstOrNull;
    final selected = sessions
        .where((s) => s['id'] == selectedStudy)
        .firstOrNull;
    final completed = sessions.where((s) => s['completed'] == 1).toList()
      ..sort(
        (a, b) => (b['completed_at'] as String? ?? b['start'] as String)
            .compareTo(a['completed_at'] as String? ?? a['start'] as String),
      );
    final assessments = data['Assessments']!.toList()
      ..sort((a, b) => (a['at'] as String).compareTo(b['at'] as String));
    final tasks = data['Tasks']!.where((t) => t['subject_id'] != null).toList();
    final now = ref.watch(studyClockProvider)();
    final today = dayKey(now);
    final until = dayKey(DateTime(now.year, now.month, now.day + 7));
    final upcoming =
        <({String kind, DataRowMap row, DateTime at})>[
              for (final a in assessments)
                if (a['completed'] == 0)
                  (
                    kind: 'assessment',
                    row: a,
                    at: DateTime.parse(a['at'] as String).toLocal(),
                  ),
              for (final t in tasks)
                if (t['completed'] == 0 && t['due'] != null)
                  (
                    kind: 'task',
                    row: t,
                    at: localTaskDate(t['due'] as String?)!,
                  ),
            ]
            .where(
              (v) =>
                  dayKey(v.at).compareTo(today) >= 0 &&
                  dayKey(v.at).compareTo(until) <= 0,
            )
            .toList()
          ..sort((a, b) => a.at.compareTo(b.at));

    Widget assessmentRow(DataRowMap a) => PremiumFocusOutline(
      child: Tooltip(
        message: 'Editar avaliação',
        child: ListTile(
          key: ValueKey('academic-assessment-${a['id']}'),
          contentPadding: EdgeInsets.zero,
          leading: Checkbox(
            semanticLabel:
                '${a['completed'] == 1 ? 'Reabrir' : 'Concluir'} avaliação ${a['title']}',
            value: a['completed'] == 1,
            onChanged: (value) => run(() async {
              await ref.read(repositoryProvider).save('Assessments', {
                'completed': value! ? 1 : 0,
              }, id: a['id'] as int);
            }),
          ),
          title: Text(
            a['title'] as String,
            style: TextStyle(
              decoration: a['completed'] == 1
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
          subtitle: Text(
            'Avaliação · ${a['kind']} · ${subjects[a['subject_id']] ?? 'Sem disciplina'}\n${stamp(a['at'] as String)} · ${a['minutes']} min',
          ),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () => showAcademicEditor(context, 'Avaliação', existing: a),
        ),
      ),
    );

    Widget studyRow(DataRowMap s) {
      final done = s['completed'] == 1;
      final started = s['focus_started_at'] != null;
      final timing = !done
          ? 'Planeada: ${stamp(s['start'] as String)}'
          : s['completed_at'] == null
          ? 'Concluída · Data de conclusão não registada\nPlaneada: ${stamp(s['start'] as String)}'
          : 'Concluída: ${stamp(s['completed_at'] as String)}';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumFocusOutline(
              child: Tooltip(
                message: 'Editar sessão',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s['title'] as String),
                  subtitle: Text(
                    '${subjects[s['subject_id']] ?? 'Sem disciplina'} · ${s['minutes']} min\n$timing',
                  ),
                  trailing: !done && !started
                      ? const Icon(Icons.chevron_right, size: 20)
                      : null,
                  onTap: !done && !started
                      ? () => showAcademicEditor(context, 'Estudo', existing: s)
                      : null,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!done)
                  Tooltip(
                    message: started ? 'Retomar foco' : 'Abrir foco',
                    child: TextButton(
                      onPressed: active != null && active['id'] != s['id']
                          ? null
                          : () =>
                                setState(() => selectedStudy = s['id'] as int),
                      child: Text(started ? 'Retomar foco' : 'Abrir foco'),
                    ),
                  ),
                IconButton(
                  tooltip: 'Eliminar sessão',
                  onPressed: () => deleteStudy(s),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget subjectRow(DataRowMap subject, bool clay) {
      final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
      final linkedTasks = tasks
          .where((t) => t['subject_id'] == subject['id'])
          .toList();
      final count = linkedTasks.where((t) => t['completed'] == 0).length;
      final exams = assessments
          .where((a) => a['subject_id'] == subject['id'] && a['completed'] == 0)
          .length;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PremiumFocusOutline(
          radius: clay ? 20 : 16,
          child: PremiumSurface(
            clay: clay,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExpansionTile(
                  key: PageStorageKey('subject-${subject['id']}'),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    subject['title'] as String,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    count == 0 && exams == 0
                        ? 'Sem trabalhos ou avaliações pendentes'
                        : '$count ${count == 1 ? 'trabalho pendente' : 'trabalhos pendentes'} · $exams ${exams == 1 ? 'avaliação' : 'avaliações'}',
                  ),
                  trailing: largeText
                      ? null
                      : IconButton(
                          tooltip: 'Editar disciplina',
                          onPressed: () => showEditor(
                            context,
                            'Disciplina',
                            existing: subject,
                          ),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                  childrenPadding: const EdgeInsets.all(12),
                  children: [
                    for (final schedule in data['ClassSchedules']!.where(
                      (c) => c['subject_id'] == subject['id'],
                    ))
                      PremiumFocusOutline(
                        child: Tooltip(
                          message: 'Editar aula',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${weekdayLabels[(schedule['weekday'] as int) - 1]} · ${clockLabel(schedule['start_minute'] as int)}–${clockLabel(schedule['end_minute'] as int)}',
                            ),
                            subtitle: Text(
                              '${schedule['location']}\n${civilDate(schedule['active_from'] as String)}${schedule['active_until'] == null ? ' em diante' : ' até ${civilDate(schedule['active_until'] as String)}'}',
                            ),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () => showAcademicEditor(
                              context,
                              'Aula',
                              existing: schedule,
                            ),
                          ),
                        ),
                      ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
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
                          onPressed: () => _createTask(subject['id'] as int),
                          child: const Text('Adicionar trabalho'),
                        ),
                      ],
                    ),
                    if (_taskSubject == subject['id'] && _createdTask != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _createdTask!.reminderFailure == null
                              ? 'Tarefa guardada.'
                              : 'Tarefa guardada; lembrete indisponível.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ...linkedTasks.map(widget.taskBuilder),
                  ],
                ),
                if (largeText)
                  Tooltip(
                    message: 'Editar disciplina',
                    child: TextButton(
                      onPressed: () =>
                          showEditor(context, 'Disciplina', existing: subject),
                      child: const Text('Editar disciplina'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final primaryStudy =
        subjects.isNotEmpty &&
        resumable == null &&
        (selected == null || selected['completed'] == 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selected != null)
          FocusTimerCard(
            key: ValueKey('focus-${selected['id']}'),
            session: selected,
            onClose: () => setState(() => selectedStudy = null),
          )
        else if (resumable != null)
          PremiumSurface(
            clay: true,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      resumable['focus_end'] == null
                          ? 'Foco em pausa'
                          : 'Sessão de foco iniciada',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(resumable['title'] as String),
                  const SizedBox(height: 12),
                  PremiumFocusOutline(
                    child: FilledButton(
                      onPressed: () => setState(
                        () => selectedStudy = resumable['id'] as int,
                      ),
                      child: const Text('Retomar foco'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        section('Próximas actividades'),
        if (upcoming.isEmpty)
          const Text('Sem actividades nos próximos 7 dias.'),
        for (final item in upcoming.take(2))
          item.kind == 'assessment'
              ? assessmentRow(item.row)
              : widget.taskBuilder(item.row),
        section('Disciplinas'),
        if (subjects.isEmpty) ...[
          const Text('Organiza aulas, avaliações e trabalhos por disciplina.'),
          const SizedBox(height: 12),
          if (resumable == null && selected == null)
            PremiumFocusOutline(
              child: FilledButton(
                onPressed: () => showEditor(context, 'Disciplina'),
                child: const Text('Adicionar disciplina'),
              ),
            )
          else
            TextButton(
              onPressed: () => showEditor(context, 'Disciplina'),
              child: const Text('Adicionar disciplina'),
            ),
        ] else ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => showEditor(context, 'Disciplina'),
              child: const Text('Adicionar disciplina'),
            ),
          ),
          for (var i = 0; i < data['Subjects']!.length; i++)
            subjectRow(
              data['Subjects']![i],
              i == 0 && resumable == null && selected == null,
            ),
        ],
        section('Sessão de estudo'),
        if (primaryStudy)
          PremiumFocusOutline(
            child: FilledButton(
              onPressed: () => showAcademicEditor(context, 'Estudo'),
              child: const Text('Planear estudo'),
            ),
          )
        else
          TextButton(
            onPressed: () => showAcademicEditor(context, 'Estudo'),
            child: const Text('Planear estudo'),
          ),
        if (pending.isEmpty && selected == null)
          const Text('Sem sessões planeadas.'),
        if (pending.isNotEmpty && resumable == null && selected == null)
          studyRow(pending.first),
        if (pending.isNotEmpty)
          PremiumFocusOutline(
            child: ExpansionTile(
              key: const PageStorageKey('academic-pending'),
              tilePadding: EdgeInsets.zero,
              title: Text('Sessões planeadas (${pending.length})'),
              children: pending.map(studyRow).toList(),
            ),
          ),
        if (completed.isNotEmpty)
          PremiumFocusOutline(
            child: ExpansionTile(
              key: const PageStorageKey('academic-history'),
              tilePadding: EdgeInsets.zero,
              title: Text('Histórico de estudo (${completed.length})'),
              subtitle: Text(
                '${completed.fold<int>(0, (sum, s) => sum + (s['minutes'] as int))} minutos concluídos',
              ),
              children: completed.map(studyRow).toList(),
            ),
          ),
        PremiumFocusOutline(
          child: ExpansionTile(
            key: const PageStorageKey('academic-activities'),
            tilePadding: EdgeInsets.zero,
            title: Text(
              'Trabalhos e avaliações (${tasks.length + assessments.length})',
            ),
            subtitle: const Text('Todas as datas, sem dia e concluídos'),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (tasks.isEmpty && assessments.isEmpty)
                const Text('Ainda sem trabalhos ou avaliações.'),
              ...assessments
                  .where((a) => a['completed'] == 0)
                  .map(assessmentRow),
              ...tasks.map(widget.taskBuilder),
              if (assessments.any((a) => a['completed'] == 1)) ...[
                section('Avaliações realizadas'),
                ...assessments
                    .where((a) => a['completed'] == 1)
                    .toList()
                    .reversed
                    .map(assessmentRow),
              ],
            ],
          ),
        ),
        // Direct creation remains available without expanding a secondary list.
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => showAcademicEditor(context, 'Avaliação'),
            child: const Text('Nova avaliação'),
          ),
        ),
        PremiumFocusOutline(
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              data['UserPreferences']!.first['gamification'] == 1
                  ? 'Sobre o foco e XP'
                  : 'Sobre o foco',
            ),
            children: [
              if (data['UserPreferences']!.first['gamification'] == 1)
                const Text(
                  '$studyExperiencePoints XP por sessão de foco concluída, até $dailyRewardedStudySessions por dia. Todas as sessões ficam no histórico.',
                ),
              const Text(
                'Planeia o estudo com flexibilidade. Uma pausa não apaga o teu progresso.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
