import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

ThemeData buildTheme(Brightness brightness) {
  // Fonts are bundled and licensed in assets/fonts. No network at runtime.
  GoogleFonts.config.allowRuntimeFetching = false;
  final dark = brightness == Brightness.dark;
  final background = dark ? AppColors.bgDark : AppColors.bgLight;
  final card = dark ? AppColors.cardDark : AppColors.cardLight;
  final ink = dark ? AppColors.inkDark : AppColors.inkLight;
  final muted = dark ? AppColors.mutedDark : AppColors.mutedLight;
  final accent = dark ? AppColors.accentDark : AppColors.accentLight;
  final line = dark ? AppColors.lineDark : AppColors.lineLight;
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  final text = GoogleFonts.interTextTheme(base.textTheme)
      .apply(bodyColor: ink, displayColor: ink)
      .copyWith(
        headlineLarge: GoogleFonts.newsreader(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: ink,
          height: 1.15,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: ink,
          height: 1.3,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: ink,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: ink,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: muted,
          height: 1.4,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: ink,
          height: 1.4,
        ),
      );
  final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: brightness)
      .copyWith(
        primary: accent,
        onPrimary: AppColors.inkLight,
        surface: card,
        onSurface: ink,
        onSurfaceVariant: muted,
        outline: line,
        outlineVariant: line,
        surfaceTint: Colors.transparent,
      );
  return base.copyWith(
    scaffoldBackgroundColor: background,
    colorScheme: scheme,
    textTheme: text,
    dividerColor: line,
    splashFactory: NoSplash.splashFactory,
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: line),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: AppColors.inkLight,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? card : AppColors.cardLight,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? accent : muted,
          size: 24,
        ),
      ),
      // The exact light accent is below 4.5:1 on white for small text.
      // Keep labels in ink; only the selected icon uses the accent.
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelMedium!.copyWith(
          color: states.contains(WidgetState.selected) ? ink : muted,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: card,
      modalBackgroundColor: card,
      elevation: 0,
      modalElevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: AppColors.inkLight,
        minimumSize: const Size(44, 44),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: BorderSide(color: line),
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: text.bodyLarge?.copyWith(color: muted),
      floatingLabelStyle: text.bodySmall?.copyWith(color: ink),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ink),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: line),
      ),
    ),
  );
}
