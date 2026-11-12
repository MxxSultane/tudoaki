import 'package:flutter/material.dart';
import '../../../app/providers.dart';
import '../../../core/database/database.dart';
import '../../../core/widgets/legacy_section_page.dart';
import '../../forms.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({this.embedded = false, super.key});
  final bool embedded;
  @override
  Widget build(BuildContext context) => LegacySectionPage(
    title: 'Hábitos',
    embedded: embedded,
    builder: (context, ref, data, act) => [
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Consistência com flexibilidade. Pode pausar e retomar quando precisar.',
        ),
      ),
      if (data['Habits']!.isEmpty)
        legacyEmpty(context, 'Comece com uma rotina pequena.', 'Hábito'),
      if (data['Habits']!.isNotEmpty)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => showEditor(context, 'Hábito'),
            icon: const Icon(Icons.add),
            label: const Text('Criar hábito'),
          ),
        ),
      ...buildHabitCards(context, data, ref.read(repositoryProvider), act),
    ],
  );
}

List<Widget> buildHabitCards(
  BuildContext context,
  WorkspaceSnapshot data,
  TudoAkiRepository repo,
  LegacyAction act, {
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
