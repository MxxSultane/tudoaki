import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudo_aki/core/theme/app_theme.dart';
import 'package:tudo_aki/core/theme/premium_theme.dart';
import 'package:tudo_aki/core/theme/premium_tokens.dart';
import 'package:tudo_aki/core/widgets/premium_components.dart';

double contrast(Color a, Color b) =>
    (math.max(a.computeLuminance(), b.computeLuminance()) + .05) /
    (math.min(a.computeLuminance(), b.computeLuminance()) + .05);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final dark in [false, true]) {
    final t = PremiumTokens(dark);
    final base = buildTheme(dark ? Brightness.dark : Brightness.light);
    test(
      'DS2 ${dark ? 'dark' : 'light'} matches approved roles and contrast',
      () {
        final source =
            jsonDecode(
                  File('docs/ux/phase4c2/tokens.json').readAsStringSync(),
                )[dark ? 'dark' : 'light']
                as Map;
        final roles = {
          'background': t.background,
          'surface': t.surface,
          'surfaceSoft': t.soft,
          'text': t.ink,
          'textMuted': t.muted,
          'action': t.action,
          'focus': t.action,
          'outline': t.outline,
          'accent': t.accent,
          'onAccent': t.onAccent,
          'primaryBorder': t.primaryBorder,
          'error': t.error,
          'errorSurface': t.errorSurface,
        };
        for (final entry in roles.entries) {
          expect(
            entry.value.toARGB32(),
            int.parse(
              (source[entry.key] as String).replaceFirst('#', 'FF'),
              radix: 16,
            ),
          );
        }
        for (final bg in [t.background, t.surface, t.soft]) {
          for (final fg in [t.ink, t.muted, t.action, t.error]) {
            expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
          }
          expect(contrast(t.ink, bg), greaterThanOrEqualTo(7));
          for (final fg in [t.outline, t.action]) {
            expect(contrast(fg, bg), greaterThanOrEqualTo(3));
          }
        }
        expect(contrast(t.onAccent, t.accent), greaterThanOrEqualTo(4.5));
        expect(contrast(t.primaryBorder, t.accent), greaterThanOrEqualTo(3));
        expect(contrast(t.error, t.errorSurface), greaterThanOrEqualTo(4.5));
        final theme = buildPremiumTheme(base, reduceMotion: true);
        expect(theme.filledButtonTheme.style!.animationDuration, Duration.zero);
        expect(base.extension<PremiumTokens>(), isNull);
        for (final states in [
          <WidgetState>{},
          {WidgetState.focused},
          {WidgetState.pressed},
          {WidgetState.disabled},
        ]) {
          final style = theme.filledButtonTheme.style!;
          expect(
            contrast(
              style.foregroundColor!.resolve(states)!,
              style.backgroundColor!.resolve(states)!,
            ),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrast(
              style.side!.resolve(states)!.color,
              style.backgroundColor!.resolve(states)!,
            ),
            greaterThanOrEqualTo(3),
          );
        }
      },
    );

    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'DS2 $dark scale$scale: targets, focus, error, selection and keyboard',
        (tester) async {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final first = FocusNode();
          final field = FocusNode();
          final check = FocusNode();
          addTearDown(first.dispose);
          addTearDown(field.dispose);
          addTearDown(check.dispose);
          var calls = 0;
          await tester.pumpWidget(
            MaterialApp(
              theme: buildPremiumTheme(base, reduceMotion: true),
              home: MediaQuery(
                data: MediaQueryData(
                  size: const Size(320, 640),
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                ),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PremiumFocusOutline(
                            child: FilledButton(
                              focusNode: first,
                              onPressed: () => calls++,
                              child: const Text('Guardar alterações'),
                            ),
                          ),
                          const PremiumFilter(
                            label: 'Activas',
                            selected: true,
                            onPressed: _noop,
                          ),
                          const FilledButton(
                            onPressed: null,
                            child: Text('A guardar…'),
                          ),
                          PremiumFocusOutline(
                            child: TextFormField(
                              focusNode: field,
                              decoration: const InputDecoration(
                                labelText: 'Nome',
                                errorText: 'Indica um nome válido.',
                              ),
                            ),
                          ),
                          PremiumFocusOutline(
                            child: Checkbox(
                              focusNode: check,
                              value: true,
                              onChanged: (_) => calls++,
                            ),
                          ),
                          const PremiumSurface(
                            clay: true,
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Resultado real'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          for (final finder in [
            find.byType(FilledButton).first,
            find.byType(TextButton),
            find.byType(Checkbox),
            find.byType(TextFormField),
          ]) {
            final size = tester.getSize(finder);
            expect(size.width, greaterThanOrEqualTo(48));
            expect(size.height, greaterThanOrEqualTo(48));
          }
          first.requestFocus();
          await tester.pumpAndSettle();
          final ring =
              tester
                      .widget<DecoratedBox>(
                        find.byKey(const ValueKey('premium-focus-ring')).first,
                      )
                      .decoration
                  as BoxDecoration;
          expect(ring.border!.top.width, 2);
          expect(ring.border!.top.color, t.action);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(calls, 1);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
          expect(first.hasFocus, isFalse); // Disabled button does not activate.
          field.requestFocus();
          await tester.ensureVisible(find.byType(TextFormField));
          await tester.pumpAndSettle();
          expect(field.hasFocus, isTrue);
          expect(find.text('Indica um nome válido.'), findsOneWidget);
          final fieldRing =
              tester
                      .widget<DecoratedBox>(
                        find.byKey(const ValueKey('premium-focus-ring')).at(2),
                      )
                      .decoration
                  as BoxDecoration;
          expect(fieldRing.border!.top.color, t.action);
          final decoration = Theme.of(
            tester.element(find.byType(TextFormField)),
          ).inputDecorationTheme;
          expect(
            (decoration.focusedErrorBorder! as OutlineInputBorder)
                .borderSide
                .color,
            t.error,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}

void _noop() {}
