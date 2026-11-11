import 'support/navigation_access.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/app/navigation/app_destinations.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/widgets/workspace_page.dart';
import 'package:tudo_aki/features/agenda/domain/agenda_cubit.dart';
import 'package:tudo_aki/features/agenda/presentation/today_screen.dart';
import 'package:tudo_aki/features/areas/presentation/areas_screen.dart';
import 'package:tudo_aki/features/goals/presentation/goals_screen.dart';
import 'package:tudo_aki/features/goals/presentation/goal_detail.dart';
import 'package:tudo_aki/features/tasks/presentation/tasks_screen.dart';

Future<void> tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<GoRouter> boot(WidgetTester tester, TudoAkiRepository repo) async {
  await initializeDateFormatting('pt');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        workspaceClockProvider.overrideWithValue(
          () => DateTime(2026, 11, 9, 10),
        ),
      ],
      child: const TudoAkiApp(),
    ),
  );
  await tester.runAsync(() => GoogleFonts.pendingFonts());
  await tester.pumpAndSettle();
  return GoRouter.of(tester.element(find.byType(TudoAkiShell)));
}

String areaPath(WidgetTester tester) => GoRouterState.of(
  tester.element(
    find.byType(AreaScaffold).evaluate().isNotEmpty
        ? find.byType(AreaScaffold)
        : find.byType(AreasScreen),
  ),
).uri.path;

void main() {
  late TudoAkiDatabase db;
  late TudoAkiRepository repo;
  setUp(() {
    db = TudoAkiDatabase.memory();
    repo = TudoAkiRepository(db);
  });
  tearDown(() => db.close());

  testWidgets(
    'current tab routes, labels, icons and agenda selection survive navigation',
    (tester) async {
      await boot(tester, repo);
      expect(tester.widget<TudoAkiShell>(find.byType(TudoAkiShell)).path, '/');
      final destinations = tester
          .widgetList<NavigationDestination>(find.byType(NavigationDestination))
          .toList();
      expect(destinations.map((d) => d.label), [
        'Hoje',
        'Planear',
        'Metas',
        'Mais',
      ]);
      expect(destinations.map((d) => (d.icon as Icon).icon), [
        Icons.today_outlined,
        Icons.calendar_month_outlined,
        Icons.flag_outlined,
        Icons.more_horiz,
      ]);
      final agenda = tester
          .element(find.byType(TodayScreen))
          .read<AgendaCubit>();
      agenda.select(DateTime(2026, 11, 11));
      agenda.mode('Semana');
      await tester.pumpAndSettle();
      for (final tab in [
        ('Metas', '/goals', 2),
        ('Planear', '/plan', 1),
        ('Hoje', '/', 0),
      ]) {
        await tap(tester, find.widgetWithText(NavigationDestination, tab.$1));
        expect(
          tester.widget<TudoAkiShell>(find.byType(TudoAkiShell)).path,
          tab.$2,
        );
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          tab.$3,
        );
        expect(find.byType(NavigationDestination), findsNWidgets(4));
      }
      final returned = tester
          .element(find.byType(TodayScreen))
          .read<AgendaCubit>();
      expect(identical(returned, agenda), isTrue);
      expect(returned.state.day, DateTime(2026, 11, 11));
      expect(returned.state.mode, 'Semana');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'all More paths push existing areas and toolbar back restores the stack',
    (tester) async {
      final router = await boot(tester, repo);
      await openGlobalTasks(tester);
      await tap(tester, find.text('Mais'));
      expect(areaPath(tester), '/areas');
      for (final area in [
        ('Planear semana', '/weekly-planner'),
        ('Hábitos', '/habits'),
        ('Estudos', '/academics'),
        ('Finanças', '/finance'),
        ('Progresso', '/progress'),
        ('Revisões', '/reviews'),
        ('Definições', '/profile'),
      ]) {
        await tap(tester, find.widgetWithText(ListTile, area.$1));
        expect(areaPath(tester), area.$2);
        expect(router.canPop(), isTrue);
        expect(find.byType(NavigationDestination), findsNothing);
        await tap(tester, find.byTooltip('Voltar'));
        expect(areaPath(tester), '/areas');
      }
      await openGlobalTasks(tester);
      expect(find.byType(TasksScreen), findsOneWidget);
      expect(
        tester.widget<TudoAkiShell>(find.byType(TudoAkiShell)).path,
        '/tasks',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'direct secondary paths retain root fallback and goal parameter behaviour',
    (tester) async {
      final goal = await repo.save('Goals', {
        'title': 'Meta ligada',
        'target': 12,
        'created': '2026-11-09T10:00:00',
      });
      final router = await boot(tester, repo);
      for (final path in [
        '/areas',
        '/weekly-planner',
        '/progress',
        '/habits',
        '/academics',
        '/finance',
        '/reviews',
        '/profile',
        '/goal/$goal',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(areaPath(tester), path);
        expect(router.canPop(), isFalse);
        if (path == '/goal/$goal') {
          expect(find.byType(GoalDetail), findsOneWidget);
          expect(find.text('Meta ligada'), findsOneWidget);
        }
        if (path == '/areas') {
          await tap(tester, find.widgetWithText(NavigationDestination, 'Hoje'));
        } else {
          await tap(tester, find.byTooltip('Voltar'));
        }
        expect(find.byType(TodayScreen), findsOneWidget);
      }
      router.go('/tasks?source=legacy');
      await tester.pumpAndSettle();
      expect(find.byType(TasksScreen), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
      router.go('/goal/not-a-number');
      await tester.pumpAndSettle();
      expect(find.text('Esta meta já não existe.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('system back follows the same pushed More stack', (tester) async {
    final router = await boot(tester, repo);
    await tap(tester, find.text('Mais'));
    await tap(tester, find.widgetWithText(ListTile, 'Hábitos'));
    // The same RouterDelegate used for platform/system back; no route shortcut.
    expect(await router.routerDelegate.popRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(areaPath(tester), '/areas');
    await tap(tester, find.widgetWithText(NavigationDestination, 'Hoje'));
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('approved metadata maps all four registered destinations', (
    tester,
  ) async {
    await repo.save('Goals', {
      'title': 'Objectivo existente',
      'target': 12,
      'created': '2026-11-09T10:00:00',
    });
    final router = await boot(tester, repo);
    final future = AppNavigation.futureDestinations;
    expect(future.map((d) => d.id), ['today', 'plan', 'goals', 'more']);
    expect(future.map((d) => d.title), ['Hoje', 'Planear', 'Metas', 'Mais']);
    expect(future.map((d) => d.path), ['/', '/plan', '/goals', '/areas']);
    expect(future.map((d) => d.icon), [
      Icons.today_outlined,
      Icons.calendar_month_outlined,
      Icons.flag_outlined,
      Icons.more_horiz,
    ]);
    for (final destination in future.where((d) => d != AppDestination.plan)) {
      router.go(destination.path);
      await tester.pumpAndSettle();
      switch (destination) {
        case AppDestination.today:
          expect(find.byType(TodayScreen), findsOneWidget);
        case AppDestination.goals:
          expect(find.byType(GoalsScreen), findsOneWidget);
          expect(find.text('Objectivo existente'), findsOneWidget);
        case AppDestination.more:
          expect(find.byType(AreasScreen), findsOneWidget);
          expect(
            find.widgetWithText(ListTile, 'Planear semana'),
            findsOneWidget,
          );
        default:
          fail('Unexpected future destination');
      }
    }
    expect(
      router.configuration
          .findMatch(Uri.parse(AppDestination.plan.path))
          .isError,
      isFalse,
    );
    router.go('/');
    await tester.pumpAndSettle();
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(await repo.all('Tasks'), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('create and edit still return to Tasks with the same record', (
    tester,
  ) async {
    await boot(tester, repo);
    await openGlobalTasks(tester);
    await tap(tester, find.byType(FloatingActionButton));
    for (final label in ['Evento', 'Tarefa', 'Meta']) {
      expect(find.widgetWithText(ListTile, label), findsOneWidget);
    }
    await tap(tester, find.widgetWithText(ListTile, 'Tarefa'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Acção navegável',
    );
    await tap(tester, find.widgetWithText(FilledButton, 'Guardar'));
    final task = (await repo.all('Tasks')).single;
    expect(task['due'], isNull);
    expect(find.byType(TasksScreen), findsOneWidget);
    expect(
      tester.widget<TudoAkiShell>(find.byType(TudoAkiShell)).path,
      '/tasks',
    );
    await tap(tester, find.text('Acção navegável'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Acção editada',
    );
    await tap(tester, find.widgetWithText(FilledButton, 'Guardar'));
    expect((await repo.all('Tasks')).single, {
      ...task,
      'title': 'Acção editada',
    });
    expect(find.text('Acção editada'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(await repo.all('ExperienceEvents'), isEmpty);
    expect(tester.takeException(), isNull);
  });
}
