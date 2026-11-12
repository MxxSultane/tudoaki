import 'package:flutter/material.dart';

/// Semantic DS 2.0 roles, from phase4c2/tokens.json. No generated seed colours.
@immutable
class PremiumTokens extends ThemeExtension<PremiumTokens> {
  const PremiumTokens(this.dark);
  final bool dark;
  static PremiumTokens of(BuildContext context) =>
      Theme.of(context).extension<PremiumTokens>()!;
  static bool active(BuildContext context) =>
      Theme.of(context).extension<PremiumTokens>() != null;

  Color get background =>
      dark ? const Color(0xFF18201D) : const Color(0xFFF7F8F5);
  Color get surface => dark ? const Color(0xFF202B29) : Colors.white;
  Color get soft => dark ? const Color(0xFF28352E) : const Color(0xFFE8EDE6);
  Color get ink => dark ? const Color(0xFFF2F5EF) : const Color(0xFF202B29);
  Color get muted => dark ? const Color(0xFFBCC6BE) : const Color(0xFF5D6965);
  Color get action => dark ? accent : const Color(0xFF456C50);
  Color get outline => dark ? const Color(0xFF8E9D92) : const Color(0xFF66736D);
  Color get accent => const Color(0xFF9ECB8F);
  Color get onAccent => const Color(0xFF202B29);
  Color get primaryBorder => dark ? onAccent : action;
  Color get error => dark ? const Color(0xFFFFB4AB) : const Color(0xFF9E2A2B);
  Color get errorSurface =>
      dark ? const Color(0xFF442629) : const Color(0xFFFCEAEA);
  Color get mineral => const Color(0xFFABAFB0); // Decorative only.

  static const space = [4.0, 8.0, 12.0, 16.0, 24.0, 32.0];
  static const fieldRadius = 12.0;
  static const actionRadius = 14.0;
  static const groupRadius = 16.0;
  static const clayRadius = 20.0;
  static const sheetRadius = 24.0;
  static const target = 48.0;
  static const fieldHeight = 56.0;
  static const focusWidth = 2.0;
  static const focusGap = 2.0;
  static const elevation = 0.0;

  @override
  PremiumTokens copyWith({bool? dark}) => PremiumTokens(dark ?? this.dark);
  @override
  PremiumTokens lerp(covariant PremiumTokens? other, double t) =>
      other == null || t < .5 ? this : other;
}
