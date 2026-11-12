import 'package:flutter/material.dart';
import '../theme/premium_tokens.dart';

/// A separate focus ring stays visible alongside selected/error/pressed states.
/// It observes descendant focus; it does not add a stop to traversal.
class PremiumFocusOutline extends StatefulWidget {
  const PremiumFocusOutline({required this.child, this.radius = 14, super.key});
  final Widget child;
  final double radius;
  @override
  State<PremiumFocusOutline> createState() => _PremiumFocusOutlineState();
}

class _PremiumFocusOutlineState extends State<PremiumFocusOutline> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onFocusChange: (value) => setState(() => _focused = value),
    child: DecoratedBox(
      key: const ValueKey('premium-focus-ring'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius + 4),
        border: Border.all(
          color: _focused
              ? PremiumTokens.of(context).action
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(padding: const EdgeInsets.all(4), child: widget.child),
    ),
  );
}

class PremiumFilter extends StatelessWidget {
  const PremiumFilter({
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      selected: selected,
      child: PremiumFocusOutline(
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: selected ? PremiumTokens.of(context).soft : null,
          ),
          onPressed: onPressed,
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              if (selected) const Icon(Icons.check, size: 20),
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Opaque clay is reserved for one existing goal highlight. All other list
/// surfaces stay flat; neither shadows nor translucency convey information.
class PremiumSurface extends StatelessWidget {
  const PremiumSurface({
    required this.child,
    this.clay = false,
    this.pressed = false,
    super.key,
  });
  final Widget child;
  final bool clay;
  final bool pressed;
  @override
  Widget build(BuildContext context) {
    final t = PremiumTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: clay ? t.soft : t.surface,
        borderRadius: BorderRadius.circular(clay ? 20 : 16),
        border: Border.all(
          color: pressed ? t.action : t.outline,
          width: pressed ? 2 : 1,
        ),
        boxShadow: clay
            ? [
                BoxShadow(
                  color: t.dark
                      ? const Color(0x29000000)
                      : const Color(0x14202B29),
                  offset: const Offset(0, 3),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
