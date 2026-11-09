import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../app/brand.dart';
import '../database/database.dart';
import '../../features/forms.dart';

typedef LegacyAction = Future<void> Function(Future<void> Function() operation);
typedef LegacySectionBuilder =
    List<Widget> Function(
      BuildContext context,
      WidgetRef ref,
      WorkspaceSnapshot data,
      LegacyAction act,
    );

/// Original secondary-area composition, shared without changing its layout.
class LegacySectionPage extends ConsumerWidget {
  const LegacySectionPage({
    required this.title,
    required this.builder,
    this.embedded = false,
    super.key,
  });
  final String title;
  final bool embedded;
  final LegacySectionBuilder builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> act(Future<void> Function() operation) async {
      try {
        await operation();
        ref.invalidate(dataProvider);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível guardar. Tente novamente.'),
            ),
          );
        }
      }
    }

    return ref
        .watch(dataProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Não foi possível abrir os dados locais.'),
                TextButton(
                  onPressed: () => ref.invalidate(dataProvider),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
          data: (data) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
              children: [
                if (!embedded) ...[
                  TudoAkiBrandHeader(showSlogan: title == 'Hoje'),
                  const SizedBox(height: 8),
                  Text(
                    title == 'Hoje' ? 'Um passo de cada vez.' : title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
                ...builder(context, ref, data, act),
              ],
            );
          },
        );
  }
}

Widget legacyHeading(BuildContext context, String text, {Widget? action}) =>
    Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleLarge),
          ),
          ?action,
        ],
      ),
    );

Widget legacyEmpty(BuildContext context, String text, String kind) => Card(
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => showEditor(context, kind),
          icon: const Icon(Icons.add),
          label: Text('Criar ${kind.toLowerCase()}'),
        ),
      ],
    ),
  ),
);
