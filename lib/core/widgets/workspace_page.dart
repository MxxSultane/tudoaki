import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../database/database.dart';

final workspaceClockProvider = Provider<DateTime Function()>(
  (_) => DateTime.now,
);

class WorkspaceData extends ConsumerWidget {
  const WorkspaceData({required this.builder, super.key});
  final Widget Function(WorkspaceSnapshot data) builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(dataProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Não foi possível abrir os dados.'),
              TextButton(
                onPressed: () => ref.invalidate(dataProvider),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: builder,
      );
}

class WorkspacePage extends StatelessWidget {
  const WorkspacePage({
    required this.title,
    required this.description,
    required this.children,
    this.more = true,
    super.key,
  });
  final String title, description;
  final List<Widget> children;
  final bool more;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 112),
    children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          if (more)
            TextButton(
              onPressed: () => context.push('/areas'),
              child: const Text('Mais'),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Text(description, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 24),
      ...children,
    ],
  );
}

Future<void> applyWorkspace(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() action,
) async {
  final container = ProviderScope.containerOf(context, listen: false);
  try {
    await action();
    container.invalidate(dataProvider);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível guardar. Tenta novamente.'),
        ),
      );
    }
  }
}
