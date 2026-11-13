import 'package:flutter/material.dart';
import '../../core/theme/premium_theme.dart';
import '../../core/theme/premium_tokens.dart';
import '../../core/widgets/workspace_page.dart';
import 'finance_panel.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({this.embedded = false, super.key});
  final bool embedded;
  @override
  Widget build(BuildContext context) => PremiumScope(
    child: Builder(
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          scrollbarTheme: Theme.of(context).scrollbarTheme.copyWith(
            thumbColor: WidgetStatePropertyAll(
              PremiumTokens.of(context).outline,
            ),
          ),
          expansionTileTheme: Theme.of(context).expansionTileTheme.copyWith(
            iconColor: PremiumTokens.of(context).action,
            collapsedIconColor: PremiumTokens.of(context).action,
          ),
        ),
        child: WorkspaceData(
          builder: (_) => ListView(
            key: const PageStorageKey('finance-overview'),
            padding: EdgeInsets.fromLTRB(
              MediaQuery.sizeOf(context).width < 360 ? 16 : 20,
              16,
              MediaQuery.sizeOf(context).width < 360 ? 16 : 20,
              32,
            ),
            children: [
              if (!embedded) ...[
                Semantics(
                  header: true,
                  child: Text(
                    'Finanças',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const FinancePanel(),
            ],
          ),
        ),
      ),
    ),
  );
}
