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

class FinancePanel extends ConsumerStatefulWidget {
  const FinancePanel({super.key});
  @override
  ConsumerState<FinancePanel> createState() => _FinancePanelState();
}

class _FinancePanelState extends ConsumerState<FinancePanel> {
  late DateTime month;
  int? posting;
  String? selectedCurrency;
  @override
  void initState() {
    super.initState();
    final now = ref.read(financeClockProvider)();
    month = DateTime(now.year, now.month, 1);
  }

  Widget heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(preview.title),
                Text(
                  '${preview.kind == 'income' ? 'Receita' : 'Despesa'} · ${preview.category}',
                ),
                Text(
                  'Total: ${formatMoney(BigInt.from(preview.amountCents) * BigInt.from(preview.days.length), currency: preview.currency)}',
                ),
                for (final day in preview.days)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      DateFormat('dd/MM/yyyy').format(DateTime.parse(day)),
                    ),
                    trailing: Text(
                      money(preview.amountCents, currency: preview.currency),
                    ),
                  ),
                if (preview.days.length == recurringBatchLimit)
                  const Text(
                    'Este lote inclui até 24 vencimentos. Pode rever os restantes depois.',
                  ),
              ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('view-currency-$currency'),
          initialValue: currency,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Moeda apresentada'),
          items: [
            for (final entry in currencyLabels.entries)
              DropdownMenuItem(
                value: entry.key,
                child: Text(
                  entry.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) => setState(() => selectedCurrency = value),
        ),
        const Text(
          'Resumo e novos registos nesta moeda. Consulte outras moedas no selector; não há conversão cambial.',
        ),
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumo mensal · $currency',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Receitas: ${formatMoney(total('income'), currency: currency)}',
                ),
                Text(
                  'Despesas: ${formatMoney(total('expense'), currency: currency)}',
                ),
                Text(
                  'Contribuições para poupança: ${formatMoney(total('saving'), currency: currency)}',
                ),
                Text(
                  'Saldo dos movimentos: ${formatMoney(total('income') - total('expense') - total('saving'), currency: currency)}',
                ),
              ],
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            FilledButton(
              onPressed: () => showEditor(
                context,
                'Transacção',
                initialDate: date,
                currency: currency,
              ),
              child: const Text('Registar movimento'),
            ),
            OutlinedButton(
              onPressed: () =>
                  showEditor(context, 'Poupança', currency: currency),
              child: const Text('Criar poupança'),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(child: heading('Orçamentos por categoria')),
            TextButton(
              onPressed: () => showFinancePlan(
                context,
                'Orçamento',
                month: month,
                today: today,
                currency: currency,
              ),
              child: const Text('Adicionar orçamento'),
            ),
          ],
        ),
        if (budgets.isEmpty)
          const Text(
            'Defina limites para as despesas deste mês. Os movimentos existentes não são alterados.',
          ),
        for (final budget in budgets)
          Builder(
            builder: (_) {
              final spent = budgetSpent(budget, rows);
              final limit = budget['limit_cents'] as int;
              final remaining = BigInt.from(limit) - spent;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              budget['category'] as String,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Editar orçamento',
                            onPressed: () => showFinancePlan(
                              context,
                              'Orçamento',
                              existing: budget,
                              month: month,
                              today: today,
                              currency: currency,
                            ),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                      Text(
                        '${formatMoney(spent, currency: currency)} de ${money(limit, currency: currency)}',
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: moneyProgress(spent, limit),
                        semanticsLabel: 'Despesas face ao orçamento',
                        semanticsValue:
                            '${spent * BigInt.from(100) ~/ BigInt.from(limit)} por cento',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        remaining.isNegative
                            ? 'Limite ultrapassado em ${formatMoney(-remaining, currency: currency)}'
                            : 'Restante: ${formatMoney(remaining, currency: currency)}',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        Row(
          children: [
            Expanded(child: heading('Movimentos recorrentes')),
            TextButton(
              onPressed: () => showFinancePlan(
                context,
                'Recorrência',
                today: today,
                currency: currency,
              ),
              child: const Text('Nova recorrência'),
            ),
          ],
        ),
        const Text(
          'Reveja os vencimentos antes de confirmar. Nenhum movimento é criado ao abrir esta página.',
        ),
        for (final rule in data['RecurringTransactions']!.where(
          (row) => rowCurrency(row) == currency,
        ))
          Card(
            child: ExpansionTile(
              key: PageStorageKey('recurring-${rule['id']}'),
              title: Text(rule['title'] as String),
              subtitle: Text(
                '${money(rule['amount_cents'] as int, currency: currency)} · ${frequencyLabels[rule['frequency']]}${rule['active'] == 0 ? ' · Em pausa' : ''}',
              ),
              childrenPadding: const EdgeInsets.all(12),
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
                    dense: true,
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
        heading('Metas de poupança'),
        if (savings.isEmpty)
          const Text('Crie uma meta para acompanhar as suas contribuições.'),
        for (final goal in savings)
          Builder(
            builder: (_) {
              final cents = transactionTotal(
                rows,
                (row) =>
                    row['kind'] == 'saving' && row['savings_id'] == goal['id'],
              );
              final target = goal['target_cents'] as int;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal['title'] as String,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Editar poupança',
                            onPressed: () =>
                                showEditor(context, 'Poupança', existing: goal),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                      Text(
                        '${formatMoney(cents, currency: currency)} / ${money(target, currency: currency)}',
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: moneyProgress(cents, target),
                        semanticsLabel: 'Progresso da poupança',
                        semanticsValue:
                            '${cents * BigInt.from(100) ~/ BigInt.from(target)} por cento',
                      ),
                      TextButton(
                        onPressed: () => showEditor(
                          context,
                          'Transacção',
                          savingsGoalId: goal['id'] as int,
                          initialDate: date,
                        ),
                        child: const Text('Registar contribuição'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        heading('Movimentos do mês'),
        if (movements.isEmpty) const Text('Ainda não há movimentos neste mês.'),
        for (final row in movements)
          Card(
            child: ListTile(
              title: Text(row['title'] as String),
              subtitle: Text(
                '${DateFormat('dd/MM/yyyy').format(DateTime.parse(row['day'] as String))} · ${row['category']}\n${switch (row['kind']) {
                  'income' => 'Receita',
                  'saving' => 'Poupança',
                  _ => 'Despesa',
                }}${row['recurring_day'] == null ? '' : ' · Recorrente'}',
              ),
              isThreeLine: true,
              trailing: Text(
                money(row['amount_cents'] as int, currency: currency),
              ),
              onTap: () => showEditor(context, 'Transacção', existing: row),
            ),
          ),
      ],
    );
  }
}
