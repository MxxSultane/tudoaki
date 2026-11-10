// Reproduce actual Flutter renders: flutter test --no-pub tool/capture_planning.dart
// Synthetic SQLite only; these captures are not golden or physical-device tests.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/widgets/workspace_page.dart';
import 'package:tudo_aki/features/planning/domain/planning_view.dart';
import 'package:tudo_aki/features/planning/presentation/planning_screen.dart';
import '../test/support/planning_fixture.dart';
import '../test/support/today_fixture.dart';

void main() {
  for (final dark in [false, true]) {
    for (final view in [
      PlanningView.today,
      PlanningView.week,
      PlanningView.undated,
    ]) {
      final name = '${view.name}-${dark ? 'dark' : 'light'}';
      testWidgets('capture actual Flutter Planear: $name', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = TudoAkiDatabase.memory();
        addTearDown(db.close);
        final now = DateTime(2026, 11, 10, 10, 30);
        final repo = PlanningRepository(db, () => now);
        await repo.save('UserPreferences', {
          'theme': dark ? 'dark' : 'light',
        }, id: 1);
        await todayTask(repo, 'Preparar a apresentação', '2026-11-10');
        await todayTask(repo, 'Passar na farmácia', '2026-11-10');
        await todayTask(repo, 'Rever as notas', '2026-11-09');
        await todayTask(repo, 'Ler um capítulo', '2026-11-11');
        await todayTask(repo, 'Planear o fim-de-semana', '2026-11-13');
        await todayTask(repo, 'Escolher próximas leituras', null);
        await todayTask(repo, 'Organizar fotografias', null);
        final completed = await todayTask(repo, 'Guardar uma ideia', null);
        await repo.taskDone(completed, true);
        await todayEvent(repo, 'Consulta de rotina', now, 11);
        await todayEvent(repo, 'Reunião da equipa', DateTime(2026, 11, 9), 9);
        await todayEvent(repo, 'Café com a Ana', DateTime(2026, 11, 12), 15);
        await initializeDateFormatting('pt');
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await tester.runAsync(icons.load);
        const boundaryKey = ValueKey('planning-capture');
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              repositoryProvider.overrideWithValue(repo),
              remindersProvider.overrideWithValue(PlanningReminders()),
              workspaceClockProvider.overrideWithValue(() => now),
            ],
            child: const RepaintBoundary(key: boundaryKey, child: TudoAkiApp()),
          ),
        );
        await tester.runAsync(() => GoogleFonts.pendingFonts());
        await tester.pumpAndSettle();
        GoRouter.of(
          tester.element(find.byType(TudoAkiShell)),
        ).push('/weekly-planner', extra: view);
        await tester.pumpAndSettle();
        expect(find.byType(PlanningScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(boundaryKey),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          final directory = Directory('docs/ux/previews/phase3d')
            ..createSync(recursive: true);
          await File(
            '${directory.path}/planning-$name.png',
          ).writeAsBytes(bytes.buffer.asUint8List());
          image.dispose();
        });
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    }
  }
}
