import '../../core/database/database.dart';

/// A parent cannot be the goal itself or any of its descendants.
/// The visited set also makes legacy/corrupt cycles safe to inspect in the UI.
List<DataRowMap> availableGoalParents(List<DataRowMap> goals, int? goalId) {
  if (goalId == null) return goals;
  final byId = {for (final goal in goals) goal['id'] as int: goal};
  return goals.where((candidate) {
    int? current = candidate['id'] as int;
    final visited = <int>{};
    while (current != null && visited.add(current)) {
      if (current == goalId) return false;
      current = byId[current]?['parent_id'] as int?;
    }
    return current == null;
  }).toList();
}

String nextGoalHorizon(String? parent) => switch (parent) {
  'Anual' || 'Trimestral' => 'Mensal',
  'Mensal' || 'Semanal' => 'Semanal',
  _ => 'Anual',
};
