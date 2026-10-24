import 'package:flutter/material.dart';

/// Public identity, shared by the application title, onboarding and interface.
abstract final class TudoAkiBrand {
  static const name = 'Tudo Aki';
  static const slogan = 'A tua vida, organizada num só lugar.';
  static const seedColor = Color(0xff26756b);
}

class TudoAkiBrandHeader extends StatelessWidget {
  const TudoAkiBrandHeader({this.showSlogan = false, super.key});
  final bool showSlogan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.check_rounded,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TudoAkiBrand.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (showSlogan)
                Text(
                  TudoAkiBrand.slogan,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
