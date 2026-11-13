import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/premium_tokens.dart';
import '../../core/widgets/premium_components.dart';
import 'finance_rules.dart';

/// Exact existing formatter; horizontal access only when the full value cannot
/// fit. No ellipsis, scale reduction, floating-point money or hidden currency.
class FinanceAmount extends StatefulWidget {
  const FinanceAmount({
    required this.cents,
    required this.currency,
    this.label,
    this.sign = '',
    super.key,
  });
  final BigInt cents;
  final String currency, sign;
  final String? label;
  @override
  State<FinanceAmount> createState() => _FinanceAmountState();
}

class _FinanceAmountState extends State<FinanceAmount> {
  final _scroll = ScrollController(keepScrollOffset: false);
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${widget.sign}${formatMoney(widget.cents, currency: widget.currency)}';
    final style = Theme.of(
      context,
    ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600);
    return Semantics(
      container: true,
      label:
          '${widget.label == null ? '' : '${widget.label}: '}$formatted · ${currencyLabels[widget.currency] ?? widget.currency}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final measure = TextPainter(
            text: TextSpan(text: formatted, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          final wide = measure.width > constraints.maxWidth;
          measure.dispose();
          Widget value = Text(formatted, style: style, softWrap: false);
          if (wide) {
            value = Focus(
              onKeyEvent: (_, event) {
                if (event is! KeyDownEvent || !_scroll.hasClients) {
                  return KeyEventResult.ignored;
                }
                final direction =
                    event.logicalKey == LogicalKeyboardKey.arrowRight
                    ? 1
                    : event.logicalKey == LogicalKeyboardKey.arrowLeft
                    ? -1
                    : 0;
                if (direction == 0) return KeyEventResult.ignored;
                _scroll.jumpTo(
                  (_scroll.offset + direction * 64).clamp(
                    0,
                    _scroll.position.maxScrollExtent,
                  ),
                );
                return KeyEventResult.handled;
              },
              child: Scrollbar(
                controller: _scroll,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 12),
                  child: value,
                ),
              ),
            );
            if (PremiumTokens.active(context)) {
              value = PremiumFocusOutline(child: value);
            }
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.label != null)
                ExcludeSemantics(child: Text(widget.label!)),
              ExcludeSemantics(child: value),
              if (wide)
                Text(
                  'Valor completo: desliza na horizontal · ${widget.currency}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          );
        },
      ),
    );
  }
}
