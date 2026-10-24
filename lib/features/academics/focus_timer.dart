import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/database/database.dart';
import 'academic_rules.dart';
import 'study_repository.dart';

final studyClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

class FocusTimerCard extends ConsumerStatefulWidget {
  const FocusTimerCard({
    required this.session,
    required this.onClose,
    super.key,
  });
  final DataRowMap session;
  final VoidCallback onClose;
  @override
  ConsumerState<FocusTimerCard> createState() => _FocusTimerCardState();
}

class _FocusTimerCardState extends ConsumerState<FocusTimerCard>
    with WidgetsBindingObserver {
  late final Timer tick;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  @override
  void dispose() {
    tick.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> action(String kind) async {
    setState(() {
      busy = true;
      error = null;
    });
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      final repo = ref.read(repositoryProvider);
      final now = ref.read(studyClockProvider)();
      final id = widget.session['id'] as int;
      switch (kind) {
        case 'start':
          await repo.startStudy(id, now: now);
        case 'pause':
          await repo.pauseStudy(id, now: now);
        case 'complete':
          await repo.completeStudy(id, now: now);
      }
      container.invalidate(dataProvider);
    } on FormatException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Não foi possível actualizar o foco. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.session;
    final seconds = focusSecondsRemaining(row, ref.watch(studyClockProvider)());
    final completed = row['completed'] == 1;
    final running = row['focus_end'] != null;
    final ready = !completed && running && seconds == 0;
    final paused = !running && row['focus_started_at'] != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tempo de foco',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(row['title'] as String),
            const SizedBox(height: 12),
            Text(
              '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.displayMedium,
              semanticsLabel:
                  '${seconds ~/ 60} minutos e ${seconds % 60} segundos restantes',
            ),
            Text(
              completed
                  ? 'Sessão registada. Bom trabalho!'
                  : ready
                  ? 'Tempo concluído. Registe a sessão quando estiver pronto.'
                  : running
                  ? 'Uma coisa de cada vez.'
                  : paused
                  ? 'Em pausa. Retome quando quiser.'
                  : 'Escolha um momento tranquilo para começar.',
            ),
            const SizedBox(height: 12),
            if (!completed)
              FilledButton(
                onPressed: busy
                    ? null
                    : () => action(
                        ready
                            ? 'complete'
                            : running
                            ? 'pause'
                            : 'start',
                      ),
                child: Text(
                  ready
                      ? 'Registar sessão concluída'
                      : running
                      ? 'Pausar'
                      : paused
                      ? 'Retomar'
                      : 'Iniciar foco',
                ),
              ),
            if (!running || completed)
              TextButton(
                onPressed: widget.onClose,
                child: const Text('Ocultar temporizador'),
              ),
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 8),
            const Text(
              'O tempo é recuperado ao regressar à aplicação. Não é emitido um alarme de fim em segundo plano.',
            ),
          ],
        ),
      ),
    );
  }
}
