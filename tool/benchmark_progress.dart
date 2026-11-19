// Diagnostic Linux/Flutter debug measurements; not an Android performance claim.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/database/schema.dart';
import 'package:tudo_aki/core/theme/app_theme.dart';
import 'package:tudo_aki/features/progress/progress_activity.dart';
import 'package:tudo_aki/features/progress/progress_panel.dart';
import 'package:tudo_aki/features/progress/progress_read_provider.dart';
import 'package:tudo_aki/features/progress/progress_screen.dart';
import 'package:tudo_aki/features/progress/progress_journey.dart';

void main() {
  testWidgets(
    'measure progress projection and bounded debug widget construction',
    (t) async {
      await initializeDateFormatting('pt');
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final results = <Map<String, Object?>>[];
      for (final count in [100, 1000, 10000]) {
        final data = {
          for (final table in exportTables) table: <DataRowMap>[],
          'UserPreferences': [
            <String, dynamic>{'gamification': 0},
          ],
          'Goals': [
            <String, dynamic>{
              'id': 1,
              'title': 'Leitura',
              'initial': 0,
              'current': 3,
              'target': 12,
              'unit': 'livros',
              'status': 'active',
            },
          ],
        };
        data['GoalProgress'] = [
          for (var i = 0; i < count; i++)
            {
              'id': i,
              'goal_id': 1,
              'value': i / 10,
              'recorded_at': DateTime(
                2026,
                11,
                17,
                0,
                i % 1440,
              ).toIso8601String(),
            },
        ];
        final samples = <double>[];
        for (var repeat = 0; repeat < 11; repeat++) {
          final clock = Stopwatch()..start();
          final view = ProgressView(data, DateTime(2026, 11, 18, 10, 30));
          clock.stop();
          expect(view.history.length, count);
          if (repeat > 0) samples.add(clock.elapsedMicroseconds / 1000);
        }
        samples.sort();
        await t.pumpWidget(const SizedBox.shrink());
        await t.pumpAndSettle();
        final timer = Stopwatch()..start();
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              progressReadProvider.overrideWith((_) async => data),
              progressClockProvider.overrideWithValue(
                () => DateTime(2026, 11, 18, 10, 30),
              ),
            ],
            child: MaterialApp(
              theme: buildTheme(Brightness.light),
              home: const Scaffold(body: ProgressScreen()),
            ),
          ),
        );
        await t.runAsync(() => GoogleFonts.pendingFonts());
        await t.pumpAndSettle();
        timer.stop();
        final entryWidgets = t
            .widgetList<ProgressEntryTile>(find.byType(ProgressEntryTile))
            .length;
        expect(entryWidgets, lessThanOrEqualTo(3));
        expect(t.takeException(), isNull);
        results.add({
          'persisted_rows': count,
          'projection_median_ms': samples[samples.length ~/ 2],
          'projection_max_ms': samples.last,
          'debug_first_build_ms_including_fonts':
              timer.elapsedMicroseconds / 1000,
          'mounted_activity_rows': entryWidgets,
        });
      }
      await t.runAsync(
        () =>
            File(
              const String.fromEnvironment(
                'PROGRESS_BENCHMARK_OUTPUT',
                defaultValue: 'docs/ux/phase4c3e/performance-results.json',
              ),
            ).writeAsString(
              '${const JsonEncoder.withIndent('  ').convert({'method': 'Flutter debug test on Linux; 1 warmup + 10 projection samples; first widget pump includes font readiness; synthetic rows in memory', 'android_device_measured': false, 'continuous_animation': false, 'provider_table_reads_per_load': 9, 'journey_page_limit': 20, 'results': results})}\n',
            ),
      );
    },
  );
}
