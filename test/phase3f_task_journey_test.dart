import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/features/forms.dart';
import 'package:tudo_aki/features/planning/domain/planning_view.dart';
import 'package:tudo_aki/features/tasks/presentation/quick_task_sheet.dart';
import 'support/navigation_access.dart';
import 'support/planning_fixture.dart';

void main() {
  for (final association in const [
    (goal: true, subject: false, label: 'goal'),
    (goal: false, subject: true, label: 'subject'),
    (goal: true, subject: true, label: 'both'),
  ]) {
    testWidgets(
      'one task crosses Hoje, Planear and Tarefas with ${association.label} links and coherent reminders',
      (tester) async {
        final db = TudoAkiDatabase.memory();
        addTearDown(db.close);
        final now = DateTime(2090, 1, 2, 8);
        final repo = PlanningRepository(db, () => now);
        final reminders = PlanningReminders();
        final goal = await repo.save('Goals', {
          'title': 'Ler fontes',
          'target': 12,
          'created': now.toIso8601String(),
        });
        final subject = await repo.save('Subjects', {'title': 'História'});
        final originalTitle = 'Percurso ${association.label}';
        final editedTitle = '$originalTitle revisto';
        await bootPlanning(tester, repo, reminders: reminders, navigate: false);

        // All writes below are performed through the actual application UI.
        await tapPlanning(tester, find.text('Adicionar tarefa'));
        expect(find.byType(QuickTaskSheet), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Título'),
          originalTitle,
        );
        await tapPlanning(tester, find.text('Mais opções'));
        if (association.goal) {
          await tapPlanning(
            tester,
            find.widgetWithText(DropdownButtonFormField<int>, 'Meta associada'),
          );
          await tapPlanning(tester, find.text('Ler fontes').last);
        }
        if (association.subject) {
          await tapPlanning(
            tester,
            find.widgetWithText(DropdownButtonFormField<int>, 'Disciplina'),
          );
          await tapPlanning(tester, find.text('História').last);
        }
        await tapPlanning(tester, find.text('Definir hora'));
        await tapPlanning(tester, find.text('OK'));
        await tapPlanning(
          tester,
          find.widgetWithText(SwitchListTile, 'Lembrete local'),
        );
        await savePlan(tester);
        final created = (await repo.all('Tasks')).single;
        final id = created['id'] as int;

        Future<void> check({
          required String title,
          required String due,
          required bool completed,
          required int rewards,
          required int cancellations,
          required int schedules,
        }) async {
          final rows = await repo.all('Tasks');
          expect(rows, hasLength(1));
          final row = rows.single;
          expect(row['id'], id);
          expect(row['title'], title);
          expect(row['created'], created['created']);
          expect(row['due'], due);
          expect(row['goal_id'], association.goal ? goal : null);
          expect(row['subject_id'], association.subject ? subject : null);
          expect(row['priority'], created['priority']);
          expect(row['important'], created['important']);
          expect(row['reminder'], 1);
          expect(row['completed'], completed ? 1 : 0);
          expect(row['completed_at'], completed ? now.toIso8601String() : null);
          final container = ProviderScope.containerOf(
            tester.element(find.byType(TudoAkiShell)),
            listen: false,
          );
          final snapshot = container.read(dataProvider).valueOrNull;
          expect(snapshot, isNotNull);
          expect(snapshot!['Tasks'], [row]);
          final experience = await repo.all('ExperienceEvents');
          expect(experience, hasLength(rewards));
          if (rewards != 0) {
            expect(experience.single['source'], 'task:$id');
            expect(experience.single['points'], 10);
          }
          expect((await repo.all('Goals')).single['current'], 0);
          expect(await repo.all('GoalProgress'), isEmpty);
          expect(reminders.cancelled, hasLength(cancellations));
          expect(reminders.cancelled.every((value) => value == id), isTrue);
          expect(reminders.scheduled, hasLength(schedules));
          expect(reminders.scheduled.every((value) => value.id == id), isTrue);
          if (schedules != 0) {
            expect(reminders.scheduled.last.date, DateTime.parse(due));
          }
          expect(tester.takeException(), isNull);
        }

        const initialDue = '2090-01-02T09:00:00.000';
        const movedDue = '2090-01-03T09:00:00.000';
        expect(find.text(originalTitle), findsOneWidget);
        await check(
          title: originalTitle,
          due: initialDue,
          completed: false,
          rewards: 0,
          cancellations: 1,
          schedules: 1,
        );

        await tapPlanning(
          tester,
          find.widgetWithText(NavigationDestination, 'Planear'),
        );
        expect(find.text(originalTitle), findsOneWidget);
        await check(
          title: originalTitle,
          due: initialDue,
          completed: false,
          rewards: 0,
          cancellations: 1,
          schedules: 1,
        );
        await planMenu(tester, id, 'Escolher dia');
        await tapPlanning(tester, find.text('Dia: 02/01/2090'));
        await pickPlanDate(tester, '03/01/2090');
        await savePlan(tester);
        expect(find.text(originalTitle), findsNothing);
        await check(
          title: originalTitle,
          due: movedDue,
          completed: false,
          rewards: 0,
          cancellations: 2,
          schedules: 2,
        );
        await planView(tester, PlanningView.tomorrow);
        expect(find.text(originalTitle), findsOneWidget);

        await openGlobalTasks(tester);
        expect(find.text(originalTitle), findsOneWidget);
        await check(
          title: originalTitle,
          due: movedDue,
          completed: false,
          rewards: 0,
          cancellations: 2,
          schedules: 2,
        );
        await tapPlanning(tester, find.text(originalTitle));
        expect(find.byType(Editor), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Título'),
          editedTitle,
        );
        await savePlan(tester);
        expect(find.text(editedTitle), findsOneWidget);
        await check(
          title: editedTitle,
          due: movedDue,
          completed: false,
          rewards: 0,
          cancellations: 3,
          schedules: 3,
        );

        Finder checkbox() => find.descendant(
          of: find.byKey(ValueKey('task-$id')),
          matching: find.byType(Checkbox),
        );
        await tapPlanning(tester, checkbox());
        expect(find.text(editedTitle), findsNothing);
        await check(
          title: editedTitle,
          due: movedDue,
          completed: true,
          rewards: 1,
          cancellations: 4,
          schedules: 3,
        );
        await tapPlanning(tester, find.text('Concluídas'));
        expect(find.text(editedTitle), findsOneWidget);
        await tapPlanning(tester, checkbox());
        expect(find.text(editedTitle), findsNothing);
        await check(
          title: editedTitle,
          due: movedDue,
          completed: false,
          rewards: 1,
          cancellations: 4,
          schedules: 4,
        );
        await tapPlanning(tester, find.text('Pendentes'));
        expect(find.text(editedTitle), findsOneWidget);
        await tapPlanning(tester, checkbox());
        await check(
          title: editedTitle,
          due: movedDue,
          completed: true,
          rewards: 1,
          cancellations: 5,
          schedules: 4,
        );
        await tapPlanning(
          tester,
          find.widgetWithText(NavigationDestination, 'Planear'),
        );
        await tapPlanning(tester, find.text('Concluídas · 1'));
        expect(find.text(editedTitle), findsOneWidget);
        await check(
          title: editedTitle,
          due: movedDue,
          completed: true,
          rewards: 1,
          cancellations: 5,
          schedules: 4,
        );
      },
    );
  }
}
