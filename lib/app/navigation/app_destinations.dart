import 'package:flutter/material.dart';
import 'app_routes.dart';

/// Metadata only: no router, route registration, widget builder or navigation.
enum AppDestination {
  agenda(AppRoutes.agenda, 'Agenda', Icons.calendar_today_outlined),
  goals(AppRoutes.goals, 'Metas', Icons.flag_outlined),
  tasks(AppRoutes.tasks, 'Tarefas', Icons.checklist_outlined),
  today(AppRoutes.agenda, 'Hoje', Icons.today_outlined),
  plan(AppRoutes.plan, 'Planear', Icons.calendar_month_outlined),
  more(AppRoutes.areas, 'Mais', Icons.more_horiz);

  const AppDestination(this.path, this.title, this.icon);
  // Enum names form stable identities; changing one changes the contract.
  String get id => name;
  final String path;
  final String title;
  final IconData icon;
}

abstract final class AppNavigation {
  /// The approved four destinations activated in phase 3E.
  static const currentDestinations = [
    AppDestination.today,
    AppDestination.plan,
    AppDestination.goals,
    AppDestination.more,
  ];
  static final List<String> currentPaths = List.unmodifiable(
    currentDestinations.map((destination) => destination.path),
  );

  /// Historical metadata API retained for callers of phase 2C.
  static const futureDestinations = currentDestinations;
}
