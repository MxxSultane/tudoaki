import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/features/areas/presentation/areas_screen.dart';
import 'package:tudo_aki/features/forms.dart';
import 'package:tudo_aki/features/academics/academic_editor.dart';
import 'package:tudo_aki/features/planning/domain/planning_view.dart';
import 'package:tudo_aki/features/planning/presentation/planning_screen.dart';
import 'package:tudo_aki/features/planning/presentation/task_schedule_sheet.dart';
import 'package:tudo_aki/features/tasks/presentation/quick_task_sheet.dart';
import 'package:tudo_aki/features/weekly_planner/presentation/weekly_planner_screen.dart';
import 'support/planning_fixture.dart';
import 'support/today_fixture.dart';

void main() {
  late TudoAkiDatabase db;
  late PlanningRepository repo;
  late PlanningReminders reminders;
  late DateTime now;
  setUp(() {
    now = DateTime(2026, 11, 10, 10, 30);
    db = TudoAkiDatabase.memory();
    repo = PlanningRepository(db, () => now);
    reminders = PlanningReminders();
  });
  tearDown(() => db.close());

  testWidgets(
    'real Hoje entries open compatible week or contextual tomorrow and return',
    (tester) async {
      await bootPlanning(tester, repo, navigate: false);
      await tapPlanning(tester, find.text('Planear amanhã'));
      expect(
        GoRouterState.of(tester.element(find.byType(AreaScaffold))).uri.path,
        '/weekly-planner',
      );
      expect(find.byType(PlanningScreen), findsOneWidget);
      expect(find.byType(WeeklyPlannerScreen), findsNothing);
      expect(
        find.text(
          DateFormat('d MMM yyyy', 'pt').format(DateTime(2026, 11, 11)),
        ),
        findsOneWidget,
      );
      final router = GoRouter.of(tester.element(find.byType(AreaScaffold)));
      expect(await router.routerDelegate.popRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(tester.widget<TudoAkiShell>(find.byType(TudoAkiShell)).path, '/');
      await tapPlanning(tester, find.text('Planear semana'));
      expect(find.byType(WeeklyPlannerScreen), findsOneWidget);
      await tapPlanning(tester, find.byTooltip('Voltar'));
      expect(find.byType(NavigationDestination), findsNWidgets(3));
      expect(
        router.configuration.findMatch(Uri.parse('/plan')).isError,
        isTrue,
      );
    },
  );

  testWidgets('empty modes explain next actions without creating records', (
    tester,
  ) async {
    await bootPlanning(tester, repo);
    for (var index = 0; index < 7; index++) {
      final day = find.byKey(ValueKey('plan-day-$index'));
      await tapPlanning(tester, day);
      expect(
        find.descendant(of: day, matching: find.text('Dia livre')),
        findsOneWidget,
      );
    }
    for (final view in [
      PlanningView.today,
      PlanningView.tomorrow,
      PlanningView.undated,
    ]) {
      await planView(tester, view);
      expect(find.text('Adicionar tarefa'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    }
    expect(find.text('Não há tarefas pendentes sem data.'), findsOneWidget);
    expect(await repo.all('Tasks'), isEmpty);
    expect(await repo.all('CalendarEvents'), isEmpty);
    expect(await repo.all('ExperienceEvents'), isEmpty);
  });

  for (final view in [
    PlanningView.today,
    PlanningView.tomorrow,
    PlanningView.undated,
  ]) {
    testWidgets(
      'quick creation inherits $view and remains in the same context',
      (tester) async {
        await bootPlanning(tester, repo, view: view);
        await tapPlanning(tester, find.text('Adicionar tarefa'));
        expect(find.byType(QuickTaskSheet), findsOneWidget);
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText).first)
              .focusNode
              .hasFocus,
          isTrue,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Título'),
          'Nova tarefa',
        );
        await savePlan(tester);
        expect(
          (await repo.all('Tasks')).single['due'],
          view == PlanningView.undated
              ? null
              : view == PlanningView.today
              ? '2026-11-10'
              : '2026-11-11',
        );
        expect(find.text('Nova tarefa'), findsOneWidget);
        expect(find.text('Tarefa guardada.').hitTestable(), findsOneWidget);
        expect(
          GoRouterState.of(tester.element(find.byType(AreaScaffold))).uri.path,
          '/weekly-planner',
        );
        expect(await repo.all('ExperienceEvents'), isEmpty);
      },
    );
  }

  testWidgets(
    'removing contextual date offers an explicit view without redirecting',
    (tester) async {
      await bootPlanning(tester, repo, view: PlanningView.tomorrow);
      await tapPlanning(tester, find.text('Adicionar tarefa'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Flexível',
      );
      await tapPlanning(tester, find.text('Retirar dia'));
      await savePlan(tester);
      expect(find.text('Flexível'), findsNothing);
      expect(find.text('Tarefa guardada sem data.'), findsOneWidget);
      expect(
        find.text(
          DateFormat('d MMM yyyy', 'pt').format(DateTime(2026, 11, 11)),
        ),
        findsOneWidget,
      );
      await tapPlanning(tester, find.text('Ver tarefa'));
      expect(find.text('Flexível'), findsOneWidget);
      expect((await repo.all('Tasks')).single['due'], isNull);
    },
  );

  testWidgets('save another preserves selected day with distinct IDs', (
    tester,
  ) async {
    await bootPlanning(tester, repo, view: PlanningView.tomorrow);
    await tapPlanning(tester, find.text('Adicionar tarefa'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Primeira',
    );
    await tapPlanning(tester, find.text('Guardar e adicionar outra'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Segunda',
    );
    await savePlan(tester);
    final rows = await repo.all('Tasks');
    expect(rows, hasLength(2));
    expect(rows.map((r) => r['id']).toSet(), hasLength(2));
    expect(rows.every((r) => r['due'] == '2026-11-11'), isTrue);
    expect(find.text('Primeira'), findsOneWidget);
    expect(find.text('Segunda'), findsOneWidget);
  });

  testWidgets(
    'choose existing pending task writes only due and retains all associations',
    (tester) async {
      final goal = await repo.save('Goals', {
        'title': 'Aprender',
        'target': 10,
        'created': now.toIso8601String(),
      });
      final subject = await repo.save('Subjects', {'title': 'História'});
      final id = await todayTask(
        repo,
        'Ler fontes',
        null,
        priority: 2,
        important: 1,
      );
      await repo.save('Tasks', {
        'goal_id': goal,
        'subject_id': subject,
      }, id: id);
      final before = (await repo.all('Tasks')).single;
      await bootPlanning(tester, repo, view: PlanningView.tomorrow);
      await tapPlanning(tester, find.text('Escolher pendente'));
      await tapPlanning(tester, find.widgetWithText(ListTile, 'Ler fontes'));
      expect(find.byType(TaskScheduleSheet), findsOneWidget);
      expect((await repo.all('Tasks')).single, before);
      await savePlan(tester);
      expect((await repo.all('Tasks')).single, {
        ...before,
        'due': '2026-11-11',
      });
      expect(find.text('Ler fontes'), findsOneWidget);
      expect(await repo.all('ExperienceEvents'), isEmpty);
    },
  );

  testWidgets(
    'choose a dated pending task from another day without copying or removing its time',
    (tester) async {
      final id = await todayTask(repo, 'Já planeada', '2026-11-10T16:30:00');
      final before = (await repo.all('Tasks')).single;
      await bootPlanning(tester, repo, view: PlanningView.tomorrow);
      await tapPlanning(tester, find.text('Escolher pendente'));
      expect(
        find.text(
          DateFormat(
            'd MMM yyyy · HH:mm',
            'pt',
          ).format(DateTime(2026, 11, 10, 16, 30)),
        ),
        findsOneWidget,
      );
      await tapPlanning(tester, find.widgetWithText(ListTile, 'Já planeada'));
      expect(find.text('Dia: 11/11/2026'), findsOneWidget);
      expect(find.text('Hora: 16:30'), findsOneWidget);
      expect((await repo.all('Tasks')).single, before);
      await savePlan(tester);
      expect((await repo.all('Tasks')).single, {
        ...before,
        'due': '2026-11-11T16:30:00.000',
      });
      expect((await repo.all('Tasks')).single['id'], id);
      expect(find.text('Já planeada'), findsOneWidget);
    },
  );

  testWidgets('cancel a scheduling draft never writes', (tester) async {
    final id = await todayTask(repo, 'Sem compromisso', null);
    final before = (await repo.all('Tasks')).single;
    await bootPlanning(tester, repo, view: PlanningView.undated);
    await planMenu(tester, id, 'Escolher dia');
    await tapPlanning(tester, find.text('Dia: Escolher'));
    await pickPlanDate(tester, '12/11/2026');
    await tapPlanning(tester, find.text('Cancelar'));
    expect(find.byType(TaskScheduleSheet), findsNothing);
    expect((await repo.all('Tasks')).single, before);
  });

  testWidgets(
    'reschedule preserves exact UTC time, precision, reminder and identity',
    (tester) async {
      final id = await todayTask(
        repo,
        'Com hora',
        '2026-11-10T12:34:56.123456Z',
      );
      await repo.save('Tasks', {'reminder': 1}, id: id);
      final before = (await repo.all('Tasks')).single;
      await bootPlanning(
        tester,
        repo,
        reminders: reminders,
        view: PlanningView.today,
      );
      await planMenu(tester, id, 'Escolher dia');
      await tapPlanning(tester, find.text('Dia: 10/11/2026'));
      await pickPlanDate(tester, '11/11/2026');
      await savePlan(tester);
      expect((await repo.all('Tasks')).single, {
        ...before,
        'due': '2026-11-11T12:34:56.123456Z',
      });
      expect(reminders.cancelled, [id]);
      expect(
        reminders.scheduled.single.date.toUtc(),
        DateTime.parse('2026-11-11T12:34:56.123456Z'),
      );
      expect(find.text('Com hora'), findsNothing);
      await planView(tester, PlanningView.tomorrow);
      expect(find.text('Com hora'), findsOneWidget);
    },
  );

  testWidgets(
    'explicit removal of time cancels reminder without discarding the task',
    (tester) async {
      final id = await todayTask(
        repo,
        'Sem hora obrigatória',
        '2026-11-10T12:00:00',
      );
      await repo.save('Tasks', {'reminder': 1}, id: id);
      final before = (await repo.all('Tasks')).single;
      await bootPlanning(
        tester,
        repo,
        reminders: reminders,
        view: PlanningView.today,
      );
      await planMenu(tester, id, 'Escolher dia');
      await tapPlanning(tester, find.text('Retirar hora'));
      expect(find.text('Sem hora, o lembrete fica desligado.'), findsOneWidget);
      await savePlan(tester);
      expect((await repo.all('Tasks')).single, {
        ...before,
        'due': '2026-11-10',
        'reminder': 0,
      });
      expect(reminders.cancelled, [id]);
      expect(reminders.scheduled, isEmpty);
    },
  );

  testWidgets(
    'an explicit time change is saved and replaces the same reminder',
    (tester) async {
      final id = await todayTask(repo, 'Telefonar', '2026-11-10T12:00:00');
      await repo.save('Tasks', {'reminder': 1}, id: id);
      await bootPlanning(
        tester,
        repo,
        reminders: reminders,
        view: PlanningView.today,
      );
      await planMenu(tester, id, 'Escolher dia');
      await tapPlanning(tester, find.text('Hora: 12:00'));
      final locale = MaterialLocalizations.of(
        tester.element(find.byType(TimePickerDialog)),
      );
      await tapPlanning(
        tester,
        find.byTooltip(locale.inputTimeModeButtonLabel),
      );
      await tester.enterText(find.byType(TextFormField).first, '2');
      await tester.enterText(find.byType(TextFormField).last, '45');
      await tapPlanning(tester, find.text('OK'));
      await savePlan(tester);
      expect(
        (await repo.all('Tasks')).single['due'],
        '2026-11-10T14:45:00.000',
      );
      expect(reminders.scheduled.single.id, id);
    },
  );

  testWidgets(
    'remove date requires confirmation and moves the same record to Sem data',
    (tester) async {
      final id = await todayTask(repo, 'Retirar do dia', '2026-11-10T12:00:00');
      await repo.save('Tasks', {'reminder': 1}, id: id);
      final before = (await repo.all('Tasks')).single;
      await bootPlanning(
        tester,
        repo,
        reminders: reminders,
        view: PlanningView.today,
      );
      await planMenu(tester, id, 'Retirar data');
      await tapPlanning(tester, find.text('Cancelar'));
      expect((await repo.all('Tasks')).single, before);
      await planMenu(tester, id, 'Retirar data');
      await tapPlanning(
        tester,
        find.widgetWithText(FilledButton, 'Retirar data'),
      );
      expect((await repo.all('Tasks')).single, {
        ...before,
        'due': null,
        'reminder': 0,
      });
      expect(find.text('Tarefa sem data.'), findsOneWidget);
      await planView(tester, PlanningView.undated);
      expect(find.text('Retirar do dia'), findsOneWidget);
      expect(reminders.cancelled, [id]);
    },
  );

  testWidgets('complete, reopen and complete again keep the same XP event', (
    tester,
  ) async {
    final id = await todayTask(repo, 'Terminar capítulo', '2026-11-11');
    await bootPlanning(tester, repo, view: PlanningView.tomorrow);
    Finder checkbox() => find.descendant(
      of: find.byKey(ValueKey('plan-task-$id')),
      matching: find.byType(Checkbox),
    );
    await tapPlanning(tester, checkbox());
    await tapPlanning(tester, find.text('Concluídas · 1'));
    await tapPlanning(tester, checkbox());
    await tapPlanning(tester, checkbox());
    expect((await repo.all('Tasks')).single['completed'], 1);
    expect((await repo.all('ExperienceEvents')).single['points'], 10);
    expect((await repo.all('ExperienceEvents')).single['source'], 'task:$id');
  });

  for (final throws in [false, true]) {
    testWidgets(
      'reminder failure is separate from persisted scheduling, throws=$throws',
      (tester) async {
        final id = await todayTask(
          repo,
          'Guardar sem alarme',
          '2026-11-10T12:00:00',
        );
        await repo.save('Tasks', {'reminder': 1}, id: id);
        reminders.allowed = false;
        reminders.throws = throws;
        await bootPlanning(
          tester,
          repo,
          reminders: reminders,
          view: PlanningView.today,
        );
        await planMenu(tester, id, 'Escolher dia');
        await savePlan(tester);
        expect(find.byType(TaskScheduleSheet), findsNothing);
        expect(
          find.text('Planeamento guardado. Lembrete indisponível.'),
          findsOneWidget,
        );
        expect(await repo.all('Tasks'), hasLength(1));
        expect((await repo.all('Tasks')).single['reminder'], 1);
      },
    );
  }

  testWidgets(
    'scheduling write failure keeps draft and database; explicit retry succeeds',
    (tester) async {
      final id = await todayTask(repo, 'Não perder', '2026-11-10');
      await bootPlanning(tester, repo, view: PlanningView.today);
      await planMenu(tester, id, 'Escolher dia');
      await tapPlanning(tester, find.text('Dia: 10/11/2026'));
      await pickPlanDate(tester, '11/11/2026');
      repo.failSave = true;
      await savePlan(tester);
      expect(find.byType(TaskScheduleSheet), findsOneWidget);
      expect(
        find.text('Não foi possível guardar. Tenta novamente.'),
        findsOneWidget,
      );
      expect((await repo.all('Tasks')).single['due'], '2026-11-10');
      repo.failSave = false;
      await savePlan(tester);
      expect((await repo.all('Tasks')).single['due'], '2026-11-11');
      expect(await repo.all('Tasks'), hasLength(1));
    },
  );

  testWidgets('failed date removal never cancels reminder or claims success', (
    tester,
  ) async {
    final id = await todayTask(repo, 'Conservar no dia', '2026-11-10T12:00:00');
    await repo.save('Tasks', {'reminder': 1}, id: id);
    final before = (await repo.all('Tasks')).single;
    await bootPlanning(
      tester,
      repo,
      reminders: reminders,
      view: PlanningView.today,
    );
    repo.failSave = true;
    await planMenu(tester, id, 'Retirar data');
    await tapPlanning(
      tester,
      find.widgetWithText(FilledButton, 'Retirar data'),
    );
    expect(
      find.text('Não foi possível guardar. Tenta novamente.'),
      findsOneWidget,
    );
    expect(find.text('Tarefa sem data.'), findsNothing);
    expect((await repo.all('Tasks')).single, before);
    expect(reminders.cancelled, isEmpty);
    repo.failSave = false;
    await planMenu(tester, id, 'Retirar data');
    await tapPlanning(
      tester,
      find.widgetWithText(FilledButton, 'Retirar data'),
    );
    expect((await repo.all('Tasks')).single['due'], isNull);
    expect(reminders.cancelled, [id]);
  });

  testWidgets(
    'academic occurrences retain their editor and return to the selected day',
    (tester) async {
      final subject = await repo.save('Subjects', {'title': 'Matemática'});
      final schedule = await repo.save('ClassSchedules', {
        'subject_id': subject,
        'weekday': 3,
        'start_minute': 660,
        'end_minute': 720,
        'active_from': '2026-01-01',
      });
      await repo.save('StudySessions', {
        'title': 'Revisão contextual',
        'start': '2026-11-11T15:00:00',
        'minutes': 25,
      });
      await bootPlanning(tester, repo, view: PlanningView.tomorrow);
      await tapPlanning(tester, find.text('Aula · Matemática'));
      final editor = tester.widget<AcademicEditor>(find.byType(AcademicEditor));
      expect(editor.kind, 'Aula');
      expect(editor.existing!['id'], schedule);
      Navigator.of(tester.element(find.byType(AcademicEditor))).pop();
      await tester.pumpAndSettle();
      await tapPlanning(tester, find.text('Estudo · Revisão contextual'));
      expect(
        GoRouterState.of(tester.element(find.byType(AreaScaffold))).uri.path,
        '/academics',
      );
      await tapPlanning(tester, find.byTooltip('Voltar'));
      expect(find.byType(PlanningScreen), findsOneWidget);
      expect(
        find.text(
          DateFormat('d MMM yyyy', 'pt').format(DateTime(2026, 11, 11)),
        ),
        findsOneWidget,
      );
      expect(await repo.all('CalendarEvents'), isEmpty);
      expect(await repo.all('Tasks'), isEmpty);
      expect(await repo.all('ClassSchedules'), hasLength(1));
    },
  );

  testWidgets('read errors allow retry without false empty states', (
    tester,
  ) async {
    await todayTask(repo, 'Ainda existe', '2026-11-10');
    repo.failRead = true;
    await bootPlanning(tester, repo, view: PlanningView.today);
    expect(find.text('Não foi possível abrir os dados.'), findsOneWidget);
    expect(find.text('Ainda não há tarefas para este dia.'), findsNothing);
    repo.failRead = false;
    await tapPlanning(tester, find.text('Tentar novamente'));
    expect(find.text('Ainda existe'), findsOneWidget);
  });

  testWidgets('undated rows retain the full editor and deletion flow', (
    tester,
  ) async {
    final id = await todayTask(repo, 'Editar sem dia', null);
    await bootPlanning(tester, repo, view: PlanningView.undated);
    await tapPlanning(tester, find.text('Editar sem dia'));
    expect(find.byType(Editor), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Editada',
    );
    await savePlan(tester);
    expect((await repo.all('Tasks')).single['id'], id);
    expect((await repo.all('Tasks')).single['due'], isNull);
    await tapPlanning(tester, find.text('Editada'));
    await tapPlanning(tester, find.widgetWithText(TextButton, 'Eliminar'));
    await tapPlanning(tester, find.widgetWithText(FilledButton, 'Eliminar'));
    expect(await repo.all('Tasks'), isEmpty);
  });

  testWidgets(
    'week reuses original creation and supports new scheduling actions',
    (tester) async {
      final id = await todayTask(repo, 'Na semana', '2026-11-09');
      await bootPlanning(tester, repo);
      expect(find.byType(WeeklyPlannerScreen), findsOneWidget);
      await planMenu(tester, id, 'Escolher dia');
      await tapPlanning(tester, find.text('Dia: 09/11/2026'));
      await pickPlanDate(tester, '10/11/2026');
      await savePlan(tester);
      expect((await repo.all('Tasks')).single['due'], '2026-11-10');
      await tapPlanning(tester, find.byKey(const ValueKey('plan-day-1')));
      expect(find.text('Na semana'), findsOneWidget);
      await tapPlanning(tester, find.text('Adicionar tarefa'));
      expect(find.byType(Editor), findsOneWidget);
      expect(find.text('Quando: 10/11/2026'), findsOneWidget);
      Navigator.of(tester.element(find.byType(Editor))).pop();
      await tester.pumpAndSettle();
      expect(await repo.all('Tasks'), hasLength(1));
    },
  );

  testWidgets(
    'relative days follow midnight; explicit chosen day and weekly selection stay fixed',
    (tester) async {
      now = DateTime(2026, 11, 10, 23, 59, 59);
      await todayTask(repo, 'Dia onze', '2026-11-11');
      await bootPlanning(tester, repo, view: PlanningView.today);
      now = DateTime(2026, 11, 11, 0, 0, 1);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Dia onze'), findsOneWidget);
      await planView(tester, PlanningView.tomorrow);
      expect(
        find.text(
          DateFormat('d MMM yyyy', 'pt').format(DateTime(2026, 11, 12)),
        ),
        findsOneWidget,
      );
      final dateButton = find.byIcon(Icons.calendar_today_outlined);
      await tapPlanning(tester, dateButton);
      await pickPlanDate(tester, '15/11/2026');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = DateTime(2026, 11, 12, 8);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(
        find.text(
          DateFormat('d MMM yyyy', 'pt').format(DateTime(2026, 11, 15)),
        ),
        findsOneWidget,
      );
      await planView(tester, PlanningView.week);
      await tapPlanning(tester, find.byKey(const ValueKey('plan-day-3')));
      await planView(tester, PlanningView.today);
      await planView(tester, PlanningView.week);
      expect(
        find.text(
          DateFormat('EEEE, d MMM', 'pt').format(DateTime(2026, 11, 12)),
        ),
        findsOneWidget,
      );
      expect((await repo.all('Tasks')).single['due'], '2026-11-11');
    },
  );

  testWidgets(
    'fifty tasks remain reachable and quick confirmation stays visible',
    (tester) async {
      for (var i = 1; i <= 50; i++) {
        await todayTask(repo, 'Tarefa $i', '2026-11-10');
      }
      await bootPlanning(tester, repo, view: PlanningView.today);
      await tapPlanning(tester, find.text('Tarefa 50'));
      expect(find.byType(Editor), findsOneWidget);
      Navigator.of(tester.element(find.byType(Editor))).pop();
      await tester.pumpAndSettle();
      await tapPlanning(tester, find.text('Adicionar tarefa'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Mais uma',
      );
      await savePlan(tester);
      expect(find.text('Tarefa guardada.').hitTestable(), findsOneWidget);
      expect(await repo.all('Tasks'), hasLength(51));
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'all new views fit 360px, 200% text and keyboard in $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final id = await todayTask(
          repo,
          'Um título comprido que deve ocupar várias linhas',
          '2026-11-10',
        );
        await todayEvent(repo, 'Compromisso com nome longo', now, 11);
        await bootPlanning(tester, repo);
        for (final view in [
          PlanningView.today,
          PlanningView.tomorrow,
          PlanningView.undated,
        ]) {
          await planView(tester, view);
          expect(tester.takeException(), isNull);
        }
        await planView(tester, PlanningView.today);
        await planMenu(tester, id, 'Escolher dia');
        await tapPlanning(tester, find.text('Cancelar'));
        await tapPlanning(tester, find.text('Adicionar tarefa'));
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Título'),
          'Pequena acção',
        );
        await savePlan(tester);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
