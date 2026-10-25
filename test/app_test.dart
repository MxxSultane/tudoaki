import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/core/theme/app_colors.dart';
import 'package:tudo_aki/core/theme/app_theme.dart';

Future<void> start(WidgetTester tester) async {
  await tester.pumpWidget(const TudoAkiApp());
  await tester.runAsync(() => GoogleFonts.pendingFonts());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('three tabs, example agenda and a creation sheet without forms', (
    tester,
  ) async {
    await start(tester);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'tudoAki');
    expect(app.themeMode, ThemeMode.system);
    expect(app.locale, const Locale('pt', 'PT'));
    expect(find.byType(NavigationDestination), findsNWidgets(3));
    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('Reunião de equipa'), findsOneWidget);
    expect(find.text('Enviar proposta'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    for (final label in ['Evento', 'Tarefa', 'Meta']) {
      expect(find.widgetWithText(ListTile, label), findsOneWidget);
    }
    await tester.tap(find.widgetWithText(ListTile, 'Evento'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    for (final tab in ['Metas', 'Tarefas']) {
      await tester.tap(find.widgetWithText(NavigationDestination, tab));
      await tester.pumpAndSettle();
      expect(find.text('Ainda não tens ${tab.toLowerCase()}.'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    }
    await tester.tap(find.widgetWithText(NavigationDestination, 'Agenda'));
    await tester.pumpAndSettle();
    expect(find.text('Hoje'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'light and dark layouts fit 360px at normal and 200 percent text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final brightness in Brightness.values) {
        for (final scale in [1.0, 2.0]) {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          await start(tester);
          final context = tester.element(find.byType(TudoAkiShell));
          expect(Theme.of(context).brightness, brightness);
          expect(find.byType(FloatingActionButton), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byType(FloatingActionButton));
          await tester.pumpAndSettle();
          for (final label in ['Evento', 'Tarefa', 'Meta']) {
            expect(
              find.widgetWithText(ListTile, label).hitTestable(),
              findsOneWidget,
            );
          }
          expect(tester.takeException(), isNull);
          await tester.tap(find.widgetWithText(ListTile, 'Meta'));
          await tester.pumpAndSettle();
          for (final tab in ['Metas', 'Tarefas']) {
            await tester.tap(find.widgetWithText(NavigationDestination, tab));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
      }
    },
  );

  test('palette, typography and text contrast follow the guide', () async {
    double contrast(Color a, Color b) {
      final first = a.computeLuminance(), second = b.computeLuminance();
      return (math.max(first, second) + .05) / (math.min(first, second) + .05);
    }

    for (final brightness in Brightness.values) {
      final theme = buildTheme(brightness);
      final dark = brightness == Brightness.dark;
      expect(
        theme.scaffoldBackgroundColor,
        dark ? AppColors.bgDark : AppColors.bgLight,
      );
      expect(
        theme.colorScheme.primary,
        dark ? AppColors.accentDark : AppColors.accentLight,
      );
      expect(
        theme.textTheme.headlineLarge!.fontFamily,
        startsWith('Newsreader'),
      );
      expect(theme.textTheme.bodyLarge!.fontFamily, startsWith('Inter'));
      expect(theme.textTheme.headlineLarge!.fontSize, 34);
      expect(theme.textTheme.titleLarge!.fontSize, 22);
      expect(theme.textTheme.bodyLarge!.fontSize, 16);
      expect(theme.textTheme.bodySmall!.fontSize, 13);
      expect(theme.cardTheme.elevation, 0);
      expect(theme.floatingActionButtonTheme.elevation, 0);
      for (final background in [
        theme.scaffoldBackgroundColor,
        theme.colorScheme.surface,
      ]) {
        expect(
          contrast(theme.textTheme.bodyLarge!.color!, background),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(theme.textTheme.bodySmall!.color!, background),
          greaterThanOrEqualTo(4.5),
        );
      }
      expect(
        contrast(theme.colorScheme.onPrimary, theme.colorScheme.primary),
        greaterThanOrEqualTo(4.5),
      );
    }
    expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
    await GoogleFonts.pendingFonts();
  });
}
