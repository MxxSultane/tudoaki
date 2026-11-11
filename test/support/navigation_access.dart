import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudo_aki/features/areas/presentation/areas_screen.dart';

/// The approved replacement for the former Tasks tab; all data assertions stay.
Future<void> openGlobalTasks(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(NavigationDestination, 'Mais'));
  await tester.pumpAndSettle();
  final scrollable = find
      .descendant(
        of: find.byType(AreasScreen),
        matching: find.byType(Scrollable),
      )
      .first;
  tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  await tester.pumpAndSettle();
  final entry = find.widgetWithText(ListTile, 'Tarefas');
  await tester.ensureVisible(entry);
  await tester.tap(entry);
  await tester.pumpAndSettle();
}
