import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/features/agenda/presentation/agenda_browser.dart';
import 'package:tudo_aki/features/agenda/presentation/today_screen.dart';
import 'package:tudo_aki/features/forms.dart';
import 'package:tudo_aki/features/academics/academic_editor.dart';
import 'package:tudo_aki/features/tasks/presentation/quick_task_sheet.dart';
import 'package:tudo_aki/features/tasks/presentation/tasks_screen.dart';
import 'package:tudo_aki/features/weekly_planner/presentation/weekly_planner_screen.dart';
import 'support/today_fixture.dart';

void main() {
  late TudoAkiDatabase db;
  late TodayRepository repo;
  late DateTime now;
  setUp(() {
    now = DateTime(2026, 11, 10, 10, 30);
    db = TudoAkiDatabase.memory();
    repo = TodayRepository(db, () => now);
  });
  tearDown(() => db.close());

  testWidgets(
    'empty Hoje is useful and retains current creation and navigation',
    (tester) async {
      await bootToday(tester, repo);
      expect(find.text('Hoje'), findsOneWidget);
      expect(find.text('terça-feira, 10 de novembro'), findsOneWidget);
      expect(find.text('Sem compromissos para hoje.'), findsOneWidget);
      expect(find.text('Adicionar tarefa'), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(3));
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.textContaining('De dias anteriores'), findsNothing);
      expect(find.textContaining('Concluídas hoje'), findsNothing);
      await tapToday(tester, find.byType(FloatingActionButton));
      for (final kind in ['Evento', 'Tarefa', 'Meta']) {
        expect(find.widgetWithText(ListTile, kind), findsOneWidget);
      }
      Navigator.of(tester.element(find.text('Criar'))).pop();
      await tester.pumpAndSettle();
      expect(await repo.all('Tasks'), isEmpty);
    },
  );

  testWidgets(
    'upcoming blocks are ordered, timed tasks stay separate, past events remain accessible',
    (tester) async {
      await todayEvent(repo, 'Já aconteceu', now, 8);
      await todayEvent(repo, 'À tarde', now, 15);
      await todayEvent(repo, 'Em curso', now, 10);
      await todayEvent(repo, 'A seguir', now, 11);
      final flexible = await todayTask(repo, 'Tarefa flexível', dayKey(now));
      final timed = await todayTask(
        repo,
        'Tarefa com hora',
        '2026-11-10T08:00:00',
      );
      await bootToday(tester, repo);
      expect(find.text('Em curso'), findsOneWidget);
      expect(find.text('A seguir'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Em curso')).dy,
        lessThan(tester.getTopLeft(find.text('A seguir')).dy),
      );
      expect(find.text('Já aconteceu'), findsNothing);
      expect(find.text('À tarde'), findsNothing);
      await revealToday(tester, find.byKey(ValueKey('today-task-$flexible')));
      expect(find.byKey(ValueKey('today-task-$timed')), findsOneWidget);
      expect(find.textContaining('De dias anteriores'), findsNothing);
      await tapToday(tester, find.text('Ver dia completo'));
      expect(find.byType(AgendaBrowser), findsOneWidget);
      expect(find.text('Já aconteceu'), findsOneWidget);
      expect(find.text('À tarde'), findsOneWidget);
      await tapToday(tester, find.text('Já aconteceu'));
      expect(find.byType(Editor), findsOneWidget);
      Navigator.of(tester.element(find.byType(Editor))).pop();
      await tester.pumpAndSettle();
      await tapToday(tester, find.text('Voltar a Hoje'));
      expect(find.byType(AgendaBrowser), findsNothing);
      expect(await repo.all('Tasks'), hasLength(2));
      expect(await repo.all('CalendarEvents'), hasLength(4));
    },
  );

  testWidgets(
    'quick sheet focuses title, inherits today and refreshes without changing origin',
    (tester) async {
      await bootToday(tester, repo);
      await tapToday(tester, find.text('Adicionar tarefa'));
      expect(find.byType(QuickTaskSheet), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Preparar apresentação',
      );
      await tapToday(tester, find.widgetWithText(FilledButton, 'Guardar'));
      expect(find.byType(QuickTaskSheet), findsNothing);
      expect(tester.widget<TudoAkiShell>(find.byType(TudoAkiShell)).path, '/');
      expect(find.text('Preparar apresentação'), findsOneWidget);
      expect(find.text('Tarefa guardada.'), findsOneWidget);
      expect((await repo.all('Tasks')).single['due'], '2026-11-10');
      expect(await repo.all('ExperienceEvents'), isEmpty);
    },
  );

  testWidgets(
    'removing contextual date saves once and offers real access to undated tasks',
    (tester) async {
      await bootToday(tester, repo);
      await tapToday(tester, find.text('Adicionar tarefa'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Ler quando puder',
      );
      await tapToday(tester, find.text('Retirar dia'));
      await tapToday(tester, find.widgetWithText(FilledButton, 'Guardar'));
      expect(find.text('Ler quando puder'), findsNothing);
      expect(find.text('Tarefa guardada sem data.'), findsOneWidget);
      await tapToday(tester, find.text('Ver tarefas'));
      expect(find.byType(TasksScreen), findsOneWidget);
      expect(find.text('Ler quando puder'), findsOneWidget);
      expect((await repo.all('Tasks')).single['due'], isNull);
    },
  );

  testWidgets(
    'save another stays in Hoje and two explicit saves produce two IDs',
    (tester) async {
      await bootToday(tester, repo);
      await tapToday(tester, find.text('Adicionar tarefa'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Primeira',
      );
      await tapToday(tester, find.text('Guardar e adicionar outra'));
      expect(find.byType(QuickTaskSheet), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Segunda',
      );
      await tapToday(tester, find.widgetWithText(FilledButton, 'Guardar'));
      expect(find.text('Primeira'), findsOneWidget);
      expect(find.text('Segunda'), findsOneWidget);
      final tasks = await repo.all('Tasks');
      expect(tasks, hasLength(2));
      expect(tasks.map((t) => t['id']).toSet(), hasLength(2));
      expect(tasks.every((t) => t['due'] == dayKey(now)), isTrue);
      expect(tester.widget<TudoAkiShell>(find.byType(TudoAkiShell)).path, '/');
    },
  );

  testWidgets(
    'completion, reopen and edit keep the ID, associations and unique XP',
    (tester) async {
      final goal = await repo.save('Goals', {
        'title': 'Meta',
        'target': 10,
        'created': now.toIso8601String(),
      });
      final subject = await repo.save('Subjects', {'title': 'História'});
      final id = await todayTask(repo, 'Ler capítulo', dayKey(now));
      await repo.save('Tasks', {
        'goal_id': goal,
        'subject_id': subject,
      }, id: id);
      await bootToday(tester, repo);
      Finder checkbox() => find.descendant(
        of: find.byKey(ValueKey('today-task-$id')),
        matching: find.byType(Checkbox),
      );
      await tapToday(tester, checkbox());
      await revealToday(tester, find.text('1 tarefa concluída hoje'));
      expect(find.text('1 tarefa concluída hoje'), findsOneWidget);
      expect((await repo.all('Tasks')).single['completed'], 1);
      await tapToday(tester, find.text('Concluídas hoje · 1'));
      await tapToday(tester, checkbox());
      expect((await repo.all('Tasks')).single['completed'], 0);
      await tapToday(tester, checkbox());
      final xp = await repo.all('ExperienceEvents');
      expect(xp, hasLength(1));
      expect(xp.single['points'], 10);
      await tapToday(tester, find.text('Ler capítulo'));
      expect(find.byType(Editor), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Capítulo lido',
      );
      await tapToday(tester, find.widgetWithText(FilledButton, 'Guardar'));
      final saved = (await repo.all('Tasks')).single;
      expect(saved['id'], id);
      expect(saved['goal_id'], goal);
      expect(saved['subject_id'], subject);
      expect(saved['due'], dayKey(now));
      expect(saved['completed'], 1);
      expect(await repo.all('ExperienceEvents'), xp);
      expect(tester.widget<TudoAkiShell>(find.byType(TudoAkiShell)).path, '/');
    },
  );

  testWidgets(
    'previous days are collapsed, keep their date and can be edited or completed',
    (tester) async {
      final id = await todayTask(repo, 'De ontem', '2026-11-09');
      await todayTask(repo, 'Já passou a hora hoje', '2026-11-10T08:00:00');
      await bootToday(tester, repo);
      expect(find.text('De ontem'), findsNothing);
      await tapToday(tester, find.text('De dias anteriores · 1'));
      await tapToday(tester, find.text('De ontem'));
      expect(find.byType(Editor), findsOneWidget);
      Navigator.of(tester.element(find.byType(Editor))).pop();
      await tester.pumpAndSettle();
      await tapToday(
        tester,
        find.descendant(
          of: find.byKey(ValueKey('today-task-$id')),
          matching: find.byType(Checkbox),
        ),
      );
      final task = (await repo.all('Tasks')).singleWhere((t) => t['id'] == id);
      expect(task['due'], '2026-11-09');
      expect(task['completed'], 1);
      expect(find.textContaining('De dias anteriores'), findsNothing);
      expect(find.text('Concluídas hoje · 1'), findsOneWidget);
    },
  );

  testWidgets(
    'habit completion uses original daily record and reward, all habits remain accessible',
    (tester) async {
      for (var i = 0; i < 4; i++) {
        await repo.save('Habits', {'title': 'Rotina $i'});
      }
      await bootToday(tester, repo);
      await revealToday(tester, find.byType(CheckboxListTile).first);
      expect(find.byType(CheckboxListTile), findsNWidgets(3));
      final habit = find.byType(CheckboxListTile).first;
      await tapToday(tester, habit);
      expect((await repo.all('HabitCompletions')).single['day'], dayKey(now));
      await tapToday(tester, habit);
      expect(await repo.all('HabitCompletions'), isEmpty);
      await tapToday(tester, habit);
      expect(await repo.all('HabitCompletions'), hasLength(1));
      expect((await repo.all('ExperienceEvents')).single['points'], 5);
      await tapToday(tester, find.text('Ver hábitos'));
      expect(find.text('Rotina 0'), findsOneWidget);
      expect(find.text('Rotina 3'), findsOneWidget);
      await tapToday(tester, find.byTooltip('Voltar'));
      expect(find.byType(TodayScreen), findsOneWidget);
    },
  );

  testWidgets(
    'weekly planning and active study use existing routes without writes',
    (tester) async {
      await repo.save('StudySessions', {
        'title': 'Foco guardado',
        'start': now.toIso8601String(),
        'minutes': 25,
        'focus_started_at': now.toIso8601String(),
        'remaining_seconds': 600,
      });
      final before = await repo.all('StudySessions');
      await bootToday(tester, repo);
      await tapToday(tester, find.text('Planear semana'));
      expect(find.byType(WeeklyPlannerScreen), findsOneWidget);
      await tapToday(tester, find.byTooltip('Voltar'));
      await tapToday(tester, find.text('Retomar estudo'));
      expect(find.text('Foco guardado'), findsOneWidget);
      await tapToday(tester, find.byTooltip('Voltar'));
      final router = GoRouter.of(tester.element(find.byType(TudoAkiShell)));
      expect(
        router.configuration.findMatch(Uri.parse('/plan')).isError,
        isTrue,
      );
      expect(await repo.all('Tasks'), isEmpty);
      expect(await repo.all('StudySessions'), before);
    },
  );

  testWidgets('read retry and failed completion never show false success', (
    tester,
  ) async {
    final id = await todayTask(repo, 'Conservar tarefa', dayKey(now));
    repo.failRead = true;
    await bootToday(tester, repo);
    expect(find.text('Não foi possível abrir os dados.'), findsOneWidget);
    repo.failRead = false;
    await tapToday(tester, find.text('Tentar novamente'));
    repo.failCompletion = true;
    await tapToday(
      tester,
      find.descendant(
        of: find.byKey(ValueKey('today-task-$id')),
        matching: find.byType(Checkbox),
      ),
    );
    expect(
      find.text('Não foi possível guardar. Tenta novamente.'),
      findsOneWidget,
    );
    expect((await repo.all('Tasks')).single['completed'], 0);
    expect(await repo.all('ExperienceEvents'), isEmpty);
    expect(find.textContaining('Concluídas hoje'), findsNothing);
  });

  testWidgets(
    'resume after midnight changes Hoje but does not reschedule tasks',
    (tester) async {
      now = DateTime(2026, 11, 10, 23, 59);
      final previous = await todayTask(repo, 'Dia dez', '2026-11-10');
      await todayTask(repo, 'Dia onze', '2026-11-11');
      await bootToday(tester, repo);
      expect(find.text('Dia dez'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = DateTime(2026, 11, 11, 0, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('quarta-feira, 11 de novembro'), findsOneWidget);
      expect(find.text('Dia onze'), findsOneWidget);
      expect(find.text('Dia dez'), findsNothing);
      await tapToday(tester, find.text('De dias anteriores · 1'));
      expect(find.text('Dia dez'), findsOneWidget);
      expect(
        (await repo.all(
          'Tasks',
        )).singleWhere((t) => t['id'] == previous)['due'],
        '2026-11-10',
      );
    },
  );

  testWidgets('midnight timer refreshes an open Hoje without a new route', (
    tester,
  ) async {
    now = DateTime(2026, 11, 10, 23, 59, 59);
    await todayTask(repo, 'Para amanhã', '2026-11-11');
    await bootToday(tester, repo);
    expect(find.text('Para amanhã'), findsNothing);
    now = DateTime(2026, 11, 11, 0, 0, 1);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Para amanhã'), findsOneWidget);
    expect(find.text('quarta-feira, 11 de novembro'), findsOneWidget);
    expect(tester.widget<TudoAkiShell>(find.byType(TudoAkiShell)).path, '/');
    expect(await repo.all('ExperienceEvents'), isEmpty);
  });

  testWidgets(
    'academic blocks retain origin-specific editors without personal event copies',
    (tester) async {
      final subject = await repo.save('Subjects', {'title': 'Matemática'});
      final schedule = await repo.save('ClassSchedules', {
        'subject_id': subject,
        'weekday': now.weekday,
        'start_minute': 11 * 60,
        'end_minute': 12 * 60,
        'active_from': '2026-01-01',
      });
      final assessment = await repo.save('Assessments', {
        'subject_id': subject,
        'title': 'Álgebra',
        'at': '2026-11-10T12:00:00',
      });
      await bootToday(tester, repo);
      await tapToday(tester, find.text('Aula · Matemática'));
      var editor = tester.widget<AcademicEditor>(find.byType(AcademicEditor));
      expect(editor.kind, 'Aula');
      expect(editor.existing!['id'], schedule);
      Navigator.of(tester.element(find.byType(AcademicEditor))).pop();
      await tester.pumpAndSettle();
      await tapToday(tester, find.text('Teste · Álgebra'));
      editor = tester.widget<AcademicEditor>(find.byType(AcademicEditor));
      expect(editor.kind, 'Avaliação');
      expect(editor.existing!['id'], assessment);
      Navigator.of(tester.element(find.byType(AcademicEditor))).pop();
      await tester.pumpAndSettle();
      expect(await repo.all('CalendarEvents'), isEmpty);
      expect(await repo.all('Tasks'), isEmpty);
      expect(await repo.all('ClassSchedules'), hasLength(1));
      expect(await repo.all('Assessments'), hasLength(1));
    },
  );

  testWidgets(
    'all fifty tasks remain reachable without a fixed priorities limit',
    (tester) async {
      for (var i = 1; i <= 50; i++) {
        await todayTask(repo, 'Acção $i', dayKey(now));
      }
      await bootToday(tester, repo);
      await revealToday(tester, find.text('Acção 50'));
      expect(find.text('Acção 50'), findsOneWidget);
      expect(await repo.all('Tasks'), hasLength(50));
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'filled Hoje fits 360px, 200% text and quick keyboard in $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await todayTask(
          repo,
          'Preparar a apresentação de um projecto com um título comprido',
          dayKey(now),
        );
        await todayEvent(
          repo,
          'Consulta com um nome longo para testar a leitura',
          now,
          11,
        );
        await repo.save('Habits', {
          'title': 'Uma rotina com um nome que ocupa mais de uma linha',
        });
        await bootToday(tester, repo);
        await tapToday(tester, find.text('Adicionar tarefa'));
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Título'),
          'Pequena acção',
        );
        await tapToday(tester, find.widgetWithText(FilledButton, 'Guardar'));
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        await tapToday(tester, find.text('Ver hábitos'));
        await tapToday(tester, find.byTooltip('Voltar'));
        await tapToday(tester, find.text('Planear semana'));
        await tapToday(tester, find.byTooltip('Voltar'));
        expect(await repo.all('Tasks'), hasLength(2));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
