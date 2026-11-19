import 'package:flutter/material.dart';

/// Shared read feedback: safe in short windows and with enlarged text.
class WorkspaceLoadState extends StatelessWidget {
  const WorkspaceLoadState({this.message, this.onRetry, super.key});
  final String? message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Semantics(
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message == null)
              const CircularProgressIndicator(
                semanticsLabel: 'A carregar dados',
              )
            else ...[
              Text(message!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
