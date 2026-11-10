/// Public paths already supported by the single GoRouter in TudoAkiApp.
abstract final class AppRoutes {
  static const agenda = '/';
  static const goals = '/goals';
  static const tasks = '/tasks';
  static const goalPattern = '/goal/:id';
  static const areas = '/areas';
  static const weeklyPlanner = '/weekly-planner';
  static const progress = '/progress';
  static const habits = '/habits';
  static const academics = '/academics';
  static const finance = '/finance';
  static const reviews = '/reviews';
  static const settings = '/profile';

  static String goalDetail(Object? id) => '/goal/$id';

  // Historical caller in the inactive Today implementation. This was not a
  // registered route; keeping its value avoids silently fixing that defect.
  static const legacyAgenda = '/agenda';
}
