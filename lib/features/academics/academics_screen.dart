import 'package:flutter/material.dart';
import '../agenda/domain/today_content.dart' show localTaskDate;
import '../../core/theme/premium_theme.dart';
import '../../core/theme/premium_tokens.dart';
import '../../core/widgets/workspace_page.dart';
import '../../core/database/database.dart';
import '../tasks/presentation/task_row.dart';
import 'academics_panel.dart';
import 'package:intl/intl.dart';

/// Presentation only: the same academic tables and operations, in three levels.
class AcademicsScreen extends StatelessWidget {
  const AcademicsScreen({this.embedded = false, super.key});
  final bool embedded;
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
        child: WorkspaceData(
          builder: (_) => ListView(
            key: const PageStorageKey('academics-overview'),
            padding: EdgeInsets.fromLTRB(
              MediaQuery.sizeOf(context).width < 360 ? 16 : 20,
              16,
              MediaQuery.sizeOf(context).width < 360 ? 16 : 20,
              32,
            ),
            children: [
              if (!embedded) ...[
                Semantics(
                  header: true,
                  child: Text(
                    'Estudos',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              AcademicsPanel(
                taskBuilder: (task) {
                  final raw = task['due'] as String?;
                  final date = localTaskDate(raw);
                  final label = date == null
                      ? 'Sem dia definido'
                      : DateFormat(
                          isDateOnly(raw) ? 'dd/MM/yyyy' : 'dd/MM/yyyy HH:mm',
                          'pt',
                        ).format(date);
                  return Tooltip(
                    message: 'Editar tarefa',
                    child: TaskRow(
                      key: ValueKey('academic-task-${task['id']}'),
                      task: task,
                      subtitle: 'Dia da tarefa: $label',
                      useCurrentEditorTheme: true,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
