import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/providers.dart';
import '../../core/database/database.dart';
import 'finance_rules.dart';
import 'finance_repository.dart';

Future<void> showFinancePlan(
  BuildContext context,
  String kind, {
  DataRowMap? existing,
  DateTime? month,
  DateTime? today,
  String? currency,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => FinancePlanEditor(
    kind: kind,
    existing: existing,
    month: month,
    today: today,
    currency: currency,
  ),
);

class FinancePlanEditor extends ConsumerStatefulWidget {
  const FinancePlanEditor({
    required this.kind,
    this.existing,
    this.month,
    this.today,
    this.currency,
    super.key,
  });
  final String kind;
  final String? currency;
  final DataRowMap? existing;
  final DateTime? month, today;
  @override
  ConsumerState<FinancePlanEditor> createState() => _FinancePlanEditorState();
}

class _FinancePlanEditorState extends ConsumerState<FinancePlanEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title, category, amount;
  late DateTime month, start;
  DateTime? end;
  late String frequency, kind, currency;
  late bool active;
  bool busy = false;
  String? error;
  DataRowMap get old => widget.existing ?? {};
  bool get recurring => widget.kind == 'Recorrência';
  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: old['title'] as String? ?? '');
    category = TextEditingController(
      text: old['category'] as String? ?? 'Geral',
    );
    final cents = old[recurring ? 'amount_cents' : 'limit_cents'] as int?;
    amount = TextEditingController(
      text: cents == null ? '' : moneyInput(cents),
    );
    month =
        DateTime.tryParse('${old['month'] ?? ''}-01') ??
        widget.month ??
        widget.today ??
        DateTime.now();
    start =
        DateTime.tryParse(old['start_day'] as String? ?? '') ??
        widget.today ??
        DateTime.now();
    end = DateTime.tryParse(old['end_day'] as String? ?? '');
    frequency = old['frequency'] as String? ?? 'monthly';
    kind = old['kind'] as String? ?? 'expense';
    active = old['active'] != 0;
    currency =
        old['currency'] as String? ??
        widget.currency ??
        ref
                .read(dataProvider)
                .valueOrNull?['UserPreferences']
                ?.single['currency']
            as String? ??
        'MZN';
  }

  @override
  void dispose() {
    title.dispose();
    category.dispose();
    amount.dispose();
    super.dispose();
  }

  Widget field(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Preencha este campo' : null,
    ),
  );
  Future<DateTime?> pick(DateTime date) => showDatePicker(
    context: context,
    initialDate: date,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(dataProvider).valueOrNull;
    final locked =
        recurring &&
        (data?['RecurringOccurrences']?.any(
              (row) => row['rule_id'] == old['id'],
            ) ??
            false);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.existing == null ? 'Criar' : 'Editar'} ${widget.kind.toLowerCase()}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              if (recurring) field(title, 'Título'),
              field(category, 'Categoria'),
              Text('Moeda do registo: $currency'),
              field(
                amount,
                recurring
                    ? 'Valor em ${currencyUnit(currency)}'
                    : 'Limite em ${currencyUnit(currency)}',
              ),
              if (!recurring)
                OutlinedButton(
                  onPressed: () async {
                    final day = await pick(month);
                    if (day != null && mounted) {
                      setState(() => month = DateTime(day.year, day.month, 1));
                    }
                  },
                  child: Text(
                    'Mês: ${DateFormat('MMMM yyyy', 'pt').format(month)}',
                  ),
                ),
              if (recurring) ...[
                DropdownButtonFormField<String>(
                  initialValue: kind,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'expense', child: Text('Despesa')),
                    DropdownMenuItem(value: 'income', child: Text('Receita')),
                  ],
                  onChanged: (v) => setState(() => kind = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: frequency,
                  decoration: const InputDecoration(labelText: 'Frequência'),
                  items: [
                    for (final e in frequencyLabels.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: locked
                      ? null
                      : (v) => setState(() => frequency = v!),
                ),
                TextButton(
                  onPressed: locked
                      ? null
                      : () async {
                          final day = await pick(start);
                          if (day != null && mounted) {
                            setState(() => start = day);
                          }
                        },
                  child: Text(
                    'Primeiro vencimento: ${DateFormat('dd/MM/yyyy').format(start)}',
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final day = await pick(end ?? start);
                          if (day != null && mounted) setState(() => end = day);
                        },
                        child: Text(
                          'Último vencimento: ${end == null ? 'Sem data final' : DateFormat('dd/MM/yyyy').format(end!)}',
                        ),
                      ),
                    ),
                    if (end != null)
                      IconButton(
                        tooltip: 'Remover data final',
                        onPressed: () => setState(() => end = null),
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Regra activa'),
                  value: active,
                  onChanged: (v) => setState(() => active = v),
                ),
                const Text(
                  'Nenhum movimento é criado automaticamente. Reveja os vencimentos e confirme o registo. Alterações não modificam movimentos já registados.',
                ),
                if (locked)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'O calendário com registos está preservado. Para mudar datas ou frequência, encerre esta regra e crie outra.',
                    ),
                  ),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'O orçamento acompanha despesas desta categoria no mês. Receitas e contribuições para poupança não contam como despesas.',
                  ),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: busy ? null : save,
                child: Text(busy ? 'A guardar…' : 'Guardar'),
              ),
              if (widget.existing != null)
                TextButton(
                  onPressed: busy ? null : remove,
                  child: const Text('Eliminar'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      final repo = container.read(repositoryProvider);
      final cents = moneyCents(amount.text);
      if (recurring) {
        await repo.saveRecurring(
          id: old['id'] as int?,
          title: title.text,
          amountCents: cents,
          kind: kind,
          category: category.text,
          frequency: frequency,
          start: start,
          end: end,
          active: active,
          currency: currency,
        );
      } else {
        await repo.saveBudget(
          id: old['id'] as int?,
          month: monthKey(month),
          category: category.text,
          limitCents: cents,
          currency: currency,
        );
      }
      container.invalidate(dataProvider);
      if (mounted) Navigator.pop(context);
    } on FormatException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Não foi possível guardar. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> remove() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Eliminar ${widget.kind.toLowerCase()}?'),
        content: Text(
          recurring
              ? 'A regra e a lista dos seus vencimentos serão eliminadas. Os movimentos financeiros já registados serão preservados.'
              : 'O limite será eliminado. Os movimentos financeiros serão preservados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() => busy = true);
    try {
      await container
          .read(repositoryProvider)
          .delete(
            recurring ? 'RecurringTransactions' : 'Budgets',
            old['id'] as int,
          );
      container.invalidate(dataProvider);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'Não foi possível eliminar.';
        });
      }
    }
  }
}
