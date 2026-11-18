import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/premium_tokens.dart';
import '../../core/widgets/premium_components.dart';
import 'progress_activity.dart';

String progressStamp(ProgressEntry entry) => entry.at == null
    ? 'Data não registada'
    : '${DateFormat('dd/MM/yyyy').format(entry.at!)}${entry.dateOnly ? ' · Hora não registada' : ' · ${DateFormat('HH:mm').format(entry.at!)}'}';

class ProgressEntryTile extends StatelessWidget {
  const ProgressEntryTile({required this.entry, required this.open, super.key});
  final ProgressEntry entry;
  final void Function(String) open;
  @override
  Widget build(BuildContext context) => Padding(
    key: ValueKey('entry-${entry.key}'),
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(entry.title, style: Theme.of(context).textTheme.titleMedium),
        Text(entry.detail),
        Text(progressStamp(entry)),
        if (entry.route != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => open(entry.route!),
              child: Text(entry.origin!),
            ),
          ),
      ],
    ),
  );
}

class ProgressJourney extends StatefulWidget {
  const ProgressJourney({required this.view, required this.open, super.key});
  final ProgressView view;
  final void Function(String) open;
  @override
  State<ProgressJourney> createState() => _ProgressJourneyState();
}

class _ProgressJourneyState extends State<ProgressJourney> {
  bool timeline = true, all = false;
  int limit = 20;
  final _scroll = ScrollController(keepScrollOffset: false);
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = all ? widget.view.history : widget.view.recent;
    final shown = entries.take(limit).toList(growable: false);
    return CustomScrollView(
      key: const PageStorageKey('progress-journey-scroll'),
      controller: _scroll,
      primary: false,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Percurso',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar Percurso',
                      autofocus: true,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(
                  'Ligações: mesmo dia.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                PremiumFocusOutline(
                  child: DropdownButtonFormField<bool>(
                    key: const ValueKey('journey-view'),
                    initialValue: timeline,
                    selectedItemBuilder: (_) => const [
                      Text('Linha'),
                      Text('Lista'),
                    ],
                    isExpanded: true,
                    isDense: false,
                    itemHeight: null,
                    decoration: const InputDecoration(labelText: 'Vista'),
                    items: const [
                      DropdownMenuItem(
                        value: true,
                        child: Text('Linha do tempo'),
                      ),
                      DropdownMenuItem(value: false, child: Text('Lista')),
                    ],
                    onChanged: (v) => setState(() => timeline = v!),
                  ),
                ),
                const SizedBox(height: 8),
                PremiumFocusOutline(
                  child: DropdownButtonFormField<bool>(
                    key: const ValueKey('journey-period'),
                    initialValue: all,
                    selectedItemBuilder: (_) => const [
                      Text('7 dias'),
                      Text('Tudo'),
                    ],
                    isExpanded: true,
                    isDense: false,
                    itemHeight: null,
                    decoration: const InputDecoration(labelText: 'Período'),
                    items: const [
                      DropdownMenuItem(
                        value: false,
                        child: Text('Últimos 7 dias'),
                      ),
                      DropdownMenuItem(
                        value: true,
                        child: Text('Todo o histórico'),
                      ),
                    ],
                    onChanged: (v) => setState(() {
                      all = v!;
                      limit = 20;
                    }),
                  ),
                ),
                if (entries.isEmpty)
                  const Text('Sem registos datados neste período.'),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.builder(
            itemCount: shown.length,
            itemBuilder: (context, i) {
              final entry = shown[i];
              final tile = ProgressEntryTile(entry: entry, open: widget.open);
              if (!timeline) return tile;
              final first = i == 0 || shown[i - 1].day != entry.day;
              final last =
                  i == shown.length - 1 || shown[i + 1].day != entry.day;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (first)
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Semantics(
                        header: true,
                        child: Text(
                          DateFormat('dd MMM yyyy', 'pt').format(entry.at!),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  CustomPaint(
                    painter: _DayRail(
                      PremiumTokens.of(context).action,
                      first,
                      last,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: tile,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              children: [
                Text(
                  '${entries.length} registos disponíveis · ${shown.length} nesta página',
                ),
                if (entries.length > limit)
                  TextButton(
                    onPressed: () => setState(() => limit += 20),
                    child: const Text('Carregar mais registos'),
                  ),
                const Text(
                  'Nomes e associações actuais. Registos reabertos ou eliminados podem deixar de aparecer. XP não é uma fonte duplicada de actividade.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DayRail extends CustomPainter {
  const _DayRail(this.color, this.first, this.last);
  final Color color;
  final bool first, last;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2;
    if (!first) canvas.drawLine(const Offset(10, 0), const Offset(10, 16), p);
    if (!last) {
      canvas.drawLine(const Offset(10, 16), Offset(10, size.height), p);
    }
    canvas.drawCircle(const Offset(10, 16), 4, p);
  }

  @override
  bool shouldRepaint(covariant _DayRail old) =>
      old.color != color || old.first != first || old.last != last;
}
