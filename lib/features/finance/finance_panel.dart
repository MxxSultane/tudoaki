import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/providers.dart';
import '../../core/database/database.dart';
import '../forms.dart';
import 'finance_editor.dart';
import 'finance_providers.dart';
import 'finance_repository.dart';
import 'finance_rules.dart';
import 'finance_amount.dart';
import '../../core/theme/premium_tokens.dart';
import '../../core/widgets/premium_components.dart';

class FinancePanel extends ConsumerStatefulWidget {
  const FinancePanel({super.key});
  @override
  ConsumerState<FinancePanel> createState() => _FinancePanelState();
}

class _FinancePanelState extends ConsumerState<FinancePanel> {
  late DateTime month;
  int? posting;
  bool allMovements = false;
  String? selectedCurrency;
  @override
  void initState() {
    super.initState();
    final now = ref.read(financeClockProvider)();
    month = DateTime(now.year, now.month, 1);
  }

  Widget heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    ),
  );
  Future<void> review(DataRowMap rule) async {
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() => posting = rule['id'] as int);
    try {
      final repo = container.read(repositoryProvider);
      final preview = await repo.previewRecurring(
        rule['id'] as int,
        now: container.read(financeClockProvider)(),
      );
      if (!mounted) return;
      if (preview.days.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sem vencimentos por registar até hoje.'),
          ),
        );
        return;
      }
      final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Registar movimentos?'),
          content: SizedBox(
            width: MediaQuery.sizeOf(context).width,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(preview.title),
                  Text(
                    '${preview.kind == 'income' ? 'Receita' : 'Despesa'} · ${preview.category}',
                  ),
                  FinanceAmount(
                    label: 'Total',
                    cents:
                        BigInt.from(preview.amountCents) *
                        BigInt.from(preview.days.length),
                    currency: preview.currency,
                  ),
                  for (final day in preview.days)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        DateFormat('dd/MM/yyyy').format(DateTime.parse(day)),
                      ),
                      subtitle: FinanceAmount(
                        cents: BigInt.from(preview.amountCents),
                        currency: preview.currency,
                      ),
                    ),
                  if (preview.days.length == recurringBatchLimit)
                    const Text(
                      'Este lote inclui até 24 vencimentos. Pode rever os restantes depois.',
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Confirmar registo'),
            ),
          ],
        ),
      );
      if (yes != true) return;
      final count = await repo.recordRecurring(
        preview,
        now: container.read(financeClockProvider)(),
      );
      container.invalidate(dataProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count movimentos registados.')),
        );
      }
    } on FormatException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível registar. Reveja e tente novamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => posting = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(dataProvider).valueOrNull;
    if (data == null) return const SizedBox.shrink();
    final currency =
        selectedCurrency ??
        data['UserPreferences']!.single['currency'] as String;
    final rows = data['FinancialTransactions']!
        .where((row) => rowCurrency(row) == currency)
        .toList();
    final savings = data['SavingsGoals']!
        .where((row) => rowCurrency(row) == currency)
        .toList();
    final key = monthKey(month);
    final today = ref.watch(financeClockProvider)();
    final date = monthKey(today) == key ? today : month;
    BigInt total(String kind) => transactionTotal(
      rows,
      (row) => row['kind'] == kind && (row['day'] as String).startsWith(key),
    );
    final movements =
        rows.where((row) => (row['day'] as String).startsWith(key)).toList()
          ..sort((a, b) => (b['day'] as String).compareTo(a['day'] as String));
    final budgets =
        data['Budgets']!
            .where((row) => row['month'] == key && rowCurrency(row) == currency)
            .toList()
          ..sort(
            (a, b) => (a['category_key'] as String).compareTo(
              b['category_key'] as String,
            ),
          );
    final rules = data['RecurringTransactions']!
        .where((row) => rowCurrency(row) == currency)
        .toList();
    Widget focus(Widget child) => PremiumTokens.active(context)
        ? PremiumFocusOutline(child: child)
        : child;
    Widget amount(BigInt value, {String? label, Key? key}) =>
        FinanceAmount(key: key, cents: value, currency: currency, label: label);
    Widget disclosure(
      String id,
      String title,
      String subtitle,
      List<Widget> children,
    ) => focus(
      ExpansionTile(
        key: ValueKey(id),
        tilePadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text(subtitle),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
    final summary = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Resumo mensal · $currency',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          amount(
            total('income') - total('expense') - total('saving'),
            label: 'Saldo dos movimentos',
            key: const ValueKey('finance-result'),
          ),
          disclosure(
            'finance-composition',
            'Ver composição',
            'Receitas, despesas e contribuições para poupança',
            [
              amount(
                total('income'),
                label: 'Receitas',
                key: const ValueKey('finance-income'),
              ),
              const SizedBox(height: 8),
              amount(
                total('expense'),
                label: 'Despesas',
                key: const ValueKey('finance-expense'),
              ),
              const SizedBox(height: 8),
              amount(
                total('saving'),
                label: 'Contribuições para poupança',
                key: const ValueKey('finance-saving-total'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Saldo dos movimentos = receitas − despesas − contribuições para poupança deste mês e moeda.',
              ),
            ],
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Mês anterior',
              onPressed: month.year == 2000 && month.month == 1
                  ? null
                  : () => setState(
                      () => month = DateTime(month.year, month.month - 1, 1),
                    ),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: TextButton(
                onPressed: () async {
                  final value = await showDatePicker(
                    context: context,
                    initialDate: month,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100, 12, 31),
                  );
                  if (value != null && mounted) {
                    setState(
                      () => month = DateTime(value.year, value.month, 1),
                    );
                  }
                },
                child: Text(DateFormat('MMMM yyyy', 'pt').format(month)),
              ),
            ),
            IconButton(
              tooltip: 'Mês seguinte',
              onPressed: month.year == 2100 && month.month == 12
                  ? null
                  : () => setState(
                      () => month = DateTime(month.year, month.month + 1, 1),
                    ),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        focus(
          DropdownButtonFormField<String>(
            key: ValueKey('view-currency-$currency'),
            initialValue: currency,
            selectedItemBuilder: (_) => [
              for (final code in currencyLabels.keys) Text(code),
            ],
            isExpanded: true,
            itemHeight: null,
            decoration: const InputDecoration(labelText: 'Moeda apresentada'),
            items: [
              for (final entry in currencyLabels.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (value) => setState(() => selectedCurrency = value),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sem conversão cambial.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        if (PremiumTokens.active(context))
          PremiumSurface(child: summary)
        else
          Card(child: summary),
        const SizedBox(height: 16),
        focus(
          FilledButton(
            onPressed: () => showEditor(
              context,
              'Transacção',
              initialDate: date,
              currency: currency,
            ),
            child: const Text('Registar movimento'),
          ),
        ),
        heading('Movimentos do mês'),
        if (movements.isEmpty) Text('Sem movimentos neste mês em $currency.'),
        for (final row in allMovements ? movements : movements.take(3))
          focus(
            Tooltip(
              message: 'Editar movimento',
              child: ListTile(
                key: ValueKey('finance-movement-${row['id']}'),
                contentPadding: EdgeInsets.zero,
                title: Text(row['title'] as String),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${DateFormat('dd/MM/yyyy').format(DateTime.parse(row['day'] as String))} · ${row['category']}\n${switch (row['kind']) {
                        'income' => 'Receita',
                        'saving' => 'Contribuição para poupança',
                        _ => 'Despesa',
                      }}${row['recurring_day'] == null ? '' : ' · Recorrente'}',
                    ),
                    FinanceAmount(
                      cents: BigInt.from(row['amount_cents'] as int),
                      currency: currency,
                      sign: row['kind'] == 'income' ? '+' : '−',
                    ),
                  ],
                ),
                onTap: () => showEditor(context, 'Transacção', existing: row),
              ),
            ),
          ),
        if (movements.length > 3)
          TextButton(
            onPressed: () => setState(() => allMovements = !allMovements),
            child: Text(
              allMovements
                  ? 'Mostrar só recentes'
                  : 'Ver todos os movimentos (${movements.length})',
            ),
          ),
        const SizedBox(height: 16),
        disclosure(
          'finance-budgets',
          'Orçamentos (${budgets.length})',
          'Limites por categoria neste mês e moeda',
          [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => showFinancePlan(
                  context,
                  'Orçamento',
                  month: month,
                  today: today,
                  currency: currency,
                ),
                child: const Text('Adicionar orçamento'),
              ),
            ),
            if (budgets.isEmpty)
              const Text('Ainda sem orçamentos neste mês e moeda.'),
            for (final budget in budgets)
              Builder(
                builder: (_) {
                  final spent = budgetSpent(budget, rows);
                  final limit = budget['limit_cents'] as int;
                  final remaining = BigInt.from(limit) - spent;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          budget['category'] as String,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        amount(spent, label: 'Despesas'),
                        amount(BigInt.from(limit), label: 'Limite'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: moneyProgress(spent, limit),
                          semanticsLabel: 'Despesas face ao orçamento',
                          semanticsValue:
                              '${spent * BigInt.from(100) ~/ BigInt.from(limit)} por cento',
                        ),
                        const SizedBox(height: 8),
                        amount(
                          remaining.isNegative ? -remaining : remaining,
                          label: remaining.isNegative
                              ? 'Limite ultrapassado em'
                              : 'Restante',
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Tooltip(
                            message: 'Editar orçamento',
                            child: TextButton(
                              onPressed: () => showFinancePlan(
                                context,
                                'Orçamento',
                                existing: budget,
                                month: month,
                                today: today,
                                currency: currency,
                              ),
                              child: const Text('Editar orçamento'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
        disclosure(
          'finance-savings',
          'Poupanças (${savings.length})',
          'Contribuições acumuladas em todos os meses',
          [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () =>
                    showEditor(context, 'Poupança', currency: currency),
                child: const Text('Criar poupança'),
              ),
            ),
            if (savings.isEmpty)
              const Text('Ainda sem metas de poupança nesta moeda.'),
            for (final goal in savings)
              Builder(
                builder: (_) {
                  final cents = transactionTotal(
                    rows,
                    (row) =>
                        row['kind'] == 'saving' &&
                        row['savings_id'] == goal['id'],
                  );
                  final target = goal['target_cents'] as int;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          goal['title'] as String,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        amount(cents, label: 'Contribuições acumuladas'),
                        amount(BigInt.from(target), label: 'Valor pretendido'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: moneyProgress(cents, target),
                          semanticsLabel: 'Progresso da poupança',
                          semanticsValue:
                              '${cents * BigInt.from(100) ~/ BigInt.from(target)} por cento',
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: () => showEditor(
                                context,
                                'Transacção',
                                savingsGoalId: goal['id'] as int,
                                initialDate: date,
                              ),
                              child: const Text('Registar contribuição'),
                            ),
                            Tooltip(
                              message: 'Editar poupança',
                              child: TextButton(
                                onPressed: () => showEditor(
                                  context,
                                  'Poupança',
                                  existing: goal,
                                ),
                                child: const Text('Editar poupança'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
        disclosure(
          'finance-recurring',
          'Recorrências (${rules.length})',
          'Revisão e confirmação antes de registar',
          [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => showFinancePlan(
                  context,
                  'Recorrência',
                  today: today,
                  currency: currency,
                ),
                child: const Text('Nova recorrência'),
              ),
            ),
            const Text(
              'Nenhum movimento é criado ao abrir. Reveja os vencimentos e confirme o registo.',
            ),
            if (rules.isEmpty)
              const Text('Ainda sem recorrências nesta moeda.'),
            for (final rule in rules)
              focus(
                ExpansionTile(
                  key: PageStorageKey('recurring-${rule['id']}'),
                  tilePadding: EdgeInsets.zero,
                  title: Text(rule['title'] as String),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${frequencyLabels[rule['frequency']]}${rule['active'] == 0 ? ' · Em pausa' : ''}',
                      ),
                      amount(BigInt.from(rule['amount_cents'] as int)),
                    ],
                  ),
                  expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${rule['kind'] == 'income' ? 'Receita' : 'Despesa'} · ${rule['category']}',
                    ),
                    Text(
                      'Desde ${DateFormat('dd/MM/yyyy').format(DateTime.parse(rule['start_day'] as String))}${rule['end_day'] == null ? '' : ' até ${DateFormat('dd/MM/yyyy').format(DateTime.parse(rule['end_day'] as String))}'}',
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: rule['active'] == 0 || posting != null
                              ? null
                              : () => review(rule),
                          child: Text(
                            posting == rule['id']
                                ? 'A preparar…'
                                : 'Rever vencimentos',
                          ),
                        ),
                        TextButton(
                          onPressed: () => showFinancePlan(
                            context,
                            'Recorrência',
                            existing: rule,
                            today: today,
                            currency: currency,
                          ),
                          child: const Text('Editar regra'),
                        ),
                      ],
                    ),
                    for (final occurrence
                        in data['RecurringOccurrences']!
                            .where((o) => o['rule_id'] == rule['id'])
                            .toList()
                            .reversed
                            .take(12))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          DateFormat(
                            'dd/MM/yyyy',
                          ).format(DateTime.parse(occurrence['day'] as String)),
                        ),
                        subtitle: Text(
                          occurrence['transaction_id'] == null
                              ? 'Movimento eliminado; o vencimento permanece registado.'
                              : 'Movimento registado.',
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
