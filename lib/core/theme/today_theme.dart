import 'package:flutter/material.dart';

/// The approved 2.0 identity, scoped to Hoje, its calendar and Planear.
/// Other areas keep their current theme during the incremental transition.
abstract final class TodayColors {
  static const sage = Color(0xFF9ECB8F);
  static const mineral = Color(0xFFABAFB0);
  static const forest = Color(0xFF456C50);
  static const graphite = Color(0xFF202B29);
  static const background = Color(0xFFF7F8F5);
  static const soft = Color(0xFFE8EDE6);
  static const darkBackground = Color(0xFF18201D);
  static const darkInk = Color(0xFFF2F5EF);
  static const muted = Color(0xFF5D6965);
  static const darkMuted = Color(0xFFBCC6BE);
}

ThemeData buildTodayTheme(ThemeData base) {
  final dark = base.brightness == Brightness.dark;
  final background = dark ? TodayColors.darkBackground : TodayColors.background;
  final surface = dark ? TodayColors.graphite : Colors.white;
  final ink = dark ? TodayColors.darkInk : TodayColors.graphite;
  final muted = dark ? TodayColors.darkMuted : TodayColors.muted;
  final action = dark ? TodayColors.sage : TodayColors.forest;
  final outline = dark ? const Color(0xFF8E9D92) : const Color(0xFF66736D);
  final text = base.textTheme
      .apply(bodyColor: ink, displayColor: ink)
      .copyWith(bodySmall: base.textTheme.bodySmall?.copyWith(color: muted));
  return base.copyWith(
    scaffoldBackgroundColor: background,
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: background,
      foregroundColor: ink,
    ),
    textTheme: text,
    cardTheme: base.cardTheme.copyWith(color: surface),
    dividerColor: dark ? const Color(0xFF3E4A43) : TodayColors.soft,
    colorScheme: base.colorScheme.copyWith(
      primary: TodayColors.sage,
      onPrimary: TodayColors.graphite,
      secondary: action,
      onSecondary: dark ? TodayColors.graphite : Colors.white,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      surfaceContainerLow: dark ? const Color(0xFF28352E) : TodayColors.soft,
      outline: outline,
      outlineVariant: TodayColors.mineral,
    ),
    floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
      backgroundColor: TodayColors.sage,
      foregroundColor: TodayColors.graphite,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: base.filledButtonTheme.style?.copyWith(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? (dark ? const Color(0xFF28352E) : TodayColors.soft)
              : TodayColors.sage,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? muted
              : TodayColors.graphite,
        ),
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: base.textButtonTheme.style?.copyWith(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled) ? muted : action,
        ),
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: base.outlinedButtonTheme.style?.copyWith(
        foregroundColor: WidgetStatePropertyAll(ink),
        side: WidgetStatePropertyAll(BorderSide(color: outline)),
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? action : Colors.transparent,
      ),
      checkColor: WidgetStatePropertyAll(
        dark ? TodayColors.graphite : Colors.white,
      ),
      side: BorderSide(color: outline, width: 2),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      labelStyle: text.bodyLarge?.copyWith(color: muted),
      floatingLabelStyle: text.bodySmall?.copyWith(color: ink),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: action, width: 2),
      ),
    ),
    bottomSheetTheme: base.bottomSheetTheme.copyWith(
      backgroundColor: surface,
      modalBackgroundColor: surface,
    ),
    navigationBarTheme: base.navigationBarTheme.copyWith(
      backgroundColor: surface,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? action : muted,
          size: 24,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelMedium!.copyWith(
          color: states.contains(WidgetState.selected) ? ink : muted,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
        ),
      ),
    ),
  );
}
