import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/navigation/app_destinations.dart';
import '../theme/premium_tokens.dart';
import 'premium_components.dart';

/// Keeps Material's destinations/semantics while honouring the requested text
/// scale. Material clamps its own labels to 130%; pre-scaling the label style
/// and disabling that second scale locally avoids either clipping or shrinking.
class WorkspaceNavigationBar extends StatelessWidget {
  const WorkspaceNavigationBar({
    required this.index,
    required this.onSelected,
    super.key,
  });
  final int index;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final tokens = PremiumTokens.of(context);
      final base = Theme.of(context).textTheme.labelMedium!;
      final style = base.copyWith(
        fontSize: MediaQuery.textScalerOf(context).scale(13),
        height: 1.35,
      );
      final labelWidth = math.max(1.0, constraints.maxWidth / 4 - 16);
      var labelHeight = 0.0;
      for (final d in AppNavigation.currentDestinations) {
        final painter = TextPainter(
          text: TextSpan(text: d.title, style: style),
          textDirection: Directionality.of(context),
        )..layout(maxWidth: labelWidth);
        labelHeight = math.max(labelHeight, painter.height);
        painter.dispose();
      }
      return MediaQuery.withNoTextScaling(
        child: NavigationBar(
          height: math.max(80, labelHeight + 64),
          animationDuration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 250),
          selectedIndex: index,
          onDestinationSelected: onSelected,
          backgroundColor: tokens.surface,
          indicatorColor: tokens.soft,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => style.copyWith(
              color: states.contains(WidgetState.selected)
                  ? tokens.ink
                  : tokens.muted,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final destination in AppNavigation.currentDestinations)
              PremiumFocusOutline(
                child: NavigationDestination(
                  icon: Icon(
                    destination.icon,
                    color:
                        AppNavigation.currentDestinations.indexOf(
                              destination,
                            ) ==
                            index
                        ? tokens.action
                        : tokens.muted,
                  ),
                  label: destination.title,
                ),
              ),
          ],
        ),
      );
    },
  );
}
