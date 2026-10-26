import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/features/academics/focus_timer.dart';
import 'package:tudo_aki/features/academics/study_repository.dart';

void main() {
  testWidgets(
    'resume uses the saved deadline without awarding XP automatically',
    (tester) async {
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = TudoAkiRepository(db);
      var now = DateTime.utc(2026, 10, 26, 10);
      final id = await repo.saveStudy(title: 'Revisão', start: now, minutes: 1);
      await repo.startStudy(id, now: now);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(repo),
            studyClockProvider.overrideWithValue(() => now),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (_, ref, _) {
                  final data = ref.watch(dataProvider).valueOrNull;
                  if (data == null) return const SizedBox();
                  return FocusTimerCard(
                    session: data['StudySessions']!.single,
                    onClose: () {},
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('01:00'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = now.add(const Duration(hours: 1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('00:00'), findsOneWidget);
      expect((await repo.studyById(id))['completed'], 0);
      expect(await repo.all('ExperienceEvents'), isEmpty);
      await tester.tap(
        find.widgetWithText(FilledButton, 'Registar sessão concluída'),
      );
      await tester.pumpAndSettle();
      expect((await repo.studyById(id))['completed'], 1);
      expect((await repo.all('ExperienceEvents')).single['points'], 15);
      await tester.pumpWidget(const SizedBox());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
