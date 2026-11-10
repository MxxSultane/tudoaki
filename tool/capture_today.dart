// Manual capture utility: flutter test --no-pub tool/capture_today.dart
// These renders use synthetic data and are not golden acceptance tests.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/widgets/workspace_page.dart';
import '../test/support/today_fixture.dart';

void main() {
  for (final dark in [false, true]) {
    for (final filled in [false, true]) {
      final name = '${filled ? 'filled' : 'empty'}-${dark ? 'dark' : 'light'}';
      testWidgets('capture actual Flutter Hoje: $name', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = TudoAkiDatabase.memory();
        addTearDown(db.close);
        final now = DateTime(2026, 11, 10, 10, 30);
        final repo = TodayRepository(db, () => now);
        await repo.save('UserPreferences', {
          'theme': dark ? 'dark' : 'light',
        }, id: 1);
        if (filled) {
          await todayEvent(repo, 'Consulta de rotina', now, 11);
          await todayEvent(repo, 'Café com a Ana', now, 15, minutes: 30);
          await todayTask(repo, 'Preparar a apresentação', dayKey(now));
          await todayTask(repo, 'Passar na farmácia', dayKey(now));
          await todayTask(repo, 'Rever as notas', '2026-11-09');
          final done = await todayTask(repo, 'Ler um capítulo', dayKey(now));
          await repo.taskDone(done, true);
          await repo.save('Habits', {'title': 'Ler por prazer'});
          await repo.save('Habits', {'title': 'Dar uma caminhada'});
        }
        await initializeDateFormatting('pt');
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await tester.runAsync(icons.load);
        const capture = ValueKey('today-capture');
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              repositoryProvider.overrideWithValue(repo),
              workspaceClockProvider.overrideWithValue(() => now),
            ],
            child: const RepaintBoundary(key: capture, child: TudoAkiApp()),
          ),
        );
        await tester.runAsync(() => GoogleFonts.pendingFonts());
        await tester.pumpAndSettle();
        expect(find.text('Hoje'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(capture),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          final folder = Directory('docs/ux/previews/phase3c')
            ..createSync(recursive: true);
          await File(
            '${folder.path}/today-$name.png',
          ).writeAsBytes(bytes.buffer.asUint8List());
          image.dispose();
        });
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    }
  }
}
