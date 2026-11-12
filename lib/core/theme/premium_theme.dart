import 'package:flutter/material.dart';
import 'premium_tokens.dart';

/// Reuses the existing local Inter/Newsreader text theme. Opt-in, never installed
/// in MaterialApp: routes and editors outside the pilot keep their own theme.
ThemeData buildPremiumTheme(ThemeData base, {bool reduceMotion = false}) {
  final t = PremiumTokens(base.brightness == Brightness.dark);
  const shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(PremiumTokens.actionRadius)),
  );
  WidgetStateProperty<Color?> foreground(Color normal) =>
      WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? t.muted : normal,
      );
  WidgetStateProperty<Color?> background(Color normal) =>
      WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? t.soft : normal,
      );
  WidgetStateProperty<BorderSide?> border(
    Color normal, {
    bool filled = false,
  }) => WidgetStateProperty.resolveWith(
    (s) => BorderSide(
      color: s.contains(WidgetState.disabled)
          ? t.outline
          : s.contains(WidgetState.focused) && filled
          ? t.onAccent
          : normal,
      width: s.contains(WidgetState.focused) || s.contains(WidgetState.pressed)
          ? 2
          : 1,
    ),
  );
  final button = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    textStyle: WidgetStatePropertyAll(
      base.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    shape: const WidgetStatePropertyAll(shape),
    animationDuration: reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 120),
    elevation: const WidgetStatePropertyAll(0),
    // Only opaque, pre-calculated role pairs. No translucent state ink.
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    tapTargetSize: MaterialTapTargetSize.padded,
  );
  OutlineInputBorder field(Color colour, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(PremiumTokens.fieldRadius),
        borderSide: BorderSide(color: colour, width: width),
      );
  final text = base.textTheme
      .apply(bodyColor: t.ink, displayColor: t.ink)
      .copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontSize: 34,
          height: 40 / 34,
          color: t.ink,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: 22,
          height: 29 / 22,
          color: t.ink,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontSize: 18,
          height: 25 / 18,
          fontWeight: FontWeight.w600,
          color: t.ink,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          fontSize: 13,
          height: 19 / 13,
          color: t.muted,
        ),
      );
  return base.copyWith(
    extensions: [
      ...base.extensions.values.where((e) => e is! PremiumTokens),
      t,
    ],
    scaffoldBackgroundColor: t.background,
    textTheme: text,
    colorScheme: base.colorScheme.copyWith(
      primary: t.accent,
      onPrimary: t.onAccent,
      secondary: t.action,
      onSecondary: t.dark ? t.onAccent : Colors.white,
      surface: t.surface,
      onSurface: t.ink,
      onSurfaceVariant: t.muted,
      surfaceContainerLow: t.soft,
      outline: t.outline,
      outlineVariant: t.soft,
      error: t.error,
      onError: t.errorSurface,
      errorContainer: t.errorSurface,
      onErrorContainer: t.error,
      surfaceTint: Colors.transparent,
    ),
    dividerColor: t.soft,
    splashFactory: NoSplash.splashFactory,
    hoverColor: Colors.transparent,
    focusColor: Colors.transparent,
    highlightColor: Colors.transparent,
    filledButtonTheme: FilledButtonThemeData(
      style: button.copyWith(
        foregroundColor: foreground(t.onAccent),
        backgroundColor: background(t.accent),
        side: border(t.primaryBorder, filled: true),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: button.copyWith(
        foregroundColor: foreground(t.action),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.pressed) ||
                  s.contains(WidgetState.hovered) ||
                  s.contains(WidgetState.selected)
              ? t.soft
              : Colors.transparent,
        ),
        side: WidgetStateProperty.resolveWith(
          (s) => BorderSide(
            color:
                s.contains(WidgetState.focused) ||
                    s.contains(WidgetState.pressed)
                ? t.action
                : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: button.copyWith(
        foregroundColor: foreground(t.action),
        backgroundColor: background(t.surface),
        side: border(t.outline),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: button.copyWith(
        padding: const WidgetStatePropertyAll(EdgeInsets.all(12)),
        foregroundColor: foreground(t.action),
        side: border(t.outline),
      ),
    ),
    floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
      backgroundColor: t.accent,
      foregroundColor: t.onAccent,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: shape.copyWith(side: BorderSide(color: t.primaryBorder)),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled)
            ? t.soft
            : s.contains(WidgetState.selected)
            ? t.action
            : Colors.transparent,
      ),
      checkColor: WidgetStatePropertyAll(t.dark ? t.onAccent : Colors.white),
      side: BorderSide(color: t.outline, width: 2),
      overlayColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)
            ? t.soft
            : Colors.transparent,
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
    ),
    expansionTileTheme: base.expansionTileTheme.copyWith(
      expansionAnimationStyle: reduceMotion
          ? AnimationStyle.noAnimation
          : const AnimationStyle(duration: Duration(milliseconds: 200)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: t.action,
      linearTrackColor: t.surface,
      linearMinHeight: 6,
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.disabled) ? t.soft : t.surface,
      ),
      constraints: const BoxConstraints(minHeight: 56),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: text.bodyLarge?.copyWith(color: t.muted),
      floatingLabelStyle: text.bodySmall?.copyWith(color: t.action),
      errorStyle: text.bodyLarge?.copyWith(color: t.error),
      errorMaxLines: 5,
      enabledBorder: field(t.outline),
      border: field(t.outline),
      disabledBorder: field(t.outline),
      focusedBorder: field(t.action, 2),
      errorBorder: field(t.error, 2),
      focusedErrorBorder: field(t.error, 2),
    ),
  );
}

/// Keeps the pre-pilot context for existing modal editors. Styling must not
/// accidentally extend the pilot to the goal form or other creation flows.
class PremiumScope extends StatelessWidget {
  const PremiumScope({required this.child, super.key});
  final Widget child;
  static BuildContext legacyContextOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LegacyContext>()?.context ??
      context;
  @override
  Widget build(BuildContext context) => _LegacyContext(
    context: context,
    child: Theme(
      data: buildPremiumTheme(
        Theme.of(context),
        reduceMotion: MediaQuery.disableAnimationsOf(context),
      ),
      child: child,
    ),
  );
}

class _LegacyContext extends InheritedWidget {
  const _LegacyContext({required this.context, required super.child});
  final BuildContext context;
  @override
  bool updateShouldNotify(_LegacyContext oldWidget) =>
      context != oldWidget.context;
}
