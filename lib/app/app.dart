import 'navigation/app_destinations.dart';
import 'navigation/app_routes.dart';
import 'navigation/modal_navigation_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import '../core/widgets/workspace_page.dart';
import '../features/forms.dart';
import '../features/progress/progress_screen.dart';
import '../features/screens.dart';
import '../features/habits/presentation/habits_screen.dart';
import '../features/reviews/presentation/reviews_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/agenda/domain/agenda_cubit.dart';
import '../features/goals/domain/goals_cubit.dart';
import '../features/tasks/domain/tasks_cubit.dart';
import '../features/goals/presentation/goal_detail.dart';
import '../features/areas/presentation/areas_screen.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/today_theme.dart';
import '../core/theme/premium_theme.dart';
import '../core/widgets/premium_components.dart';
import '../features/agenda/presentation/today_screen.dart';
import '../features/agenda/presentation/agenda_browser.dart';
import '../features/goals/presentation/goals_screen.dart';
import '../features/tasks/presentation/tasks_screen.dart';
import 'brand.dart';
import '../features/weekly_planner/domain/weekly_planner_cubit.dart';
import '../features/planning/presentation/planning_screen.dart';
import '../features/planning/domain/planning_view.dart';

class TudoAkiApp extends ConsumerStatefulWidget {
  const TudoAkiApp({super.key});
  @override
  ConsumerState<TudoAkiApp> createState() => _TudoAkiAppState();
}

class _TudoAkiAppState extends ConsumerState<TudoAkiApp> {
  final modalGuard = ModalNavigationGuard();
  late final popupObservers = List.generate(
    4,
    (_) => ShellPopupObserver(modalGuard),
  );
  late final router = GoRouter(
    observers: [ShellPopupObserver(modalGuard)],
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, state, shell) => TudoAkiShell(
          path: state.uri.path,
          navigationShell: shell,
          modalGuard: modalGuard,
          child: shell,
        ),
        branches: [
          StatefulShellBranch(
            observers: [popupObservers[0]],
            routes: [
              GoRoute(
                path: AppRoutes.agenda,
                builder: (context, _) => TodayScreen(
                  createAction: ValueListenableBuilder<bool>(
                    valueListenable: modalGuard.active,
                    builder: (context, blocked, _) => PremiumScope(
                      child: PremiumFocusOutline(
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: blocked
                              ? null
                              : FloatingActionButton(
                                  heroTag: null,
                                  tooltip: 'Criar',
                                  onPressed: () => showWorkspaceCreateSheet(
                                    context,
                                    date: context.read<AgendaCubit>().state.day,
                                  ),
                                  child: const Icon(Icons.add),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            observers: [popupObservers[1]],
            routes: [
              GoRoute(
                path: AppRoutes.plan,
                builder: (_, state) => BlocProvider(
                  create: (_) =>
                      WeeklyPlannerCubit(ref.read(workspaceClockProvider)()),
                  child: PlanningScreen(
                    initialView: PlanningView.today,
                    request: state.extra is PlanningRequest
                        ? state.extra as PlanningRequest
                        : null,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            observers: [popupObservers[2]],
            routes: [
              GoRoute(
                path: AppRoutes.goals,
                builder: (_, _) => const GoalsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            observers: [popupObservers[3]],
            routes: [
              GoRoute(
                path: AppRoutes.areas,
                builder: (_, _) => const AreasScreen(),
              ),
              GoRoute(
                path: AppRoutes.tasks,
                builder: (_, _) => const TasksScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.calendar,
        builder: (context, _) => AreaScaffold(
          title: 'Agenda',
          floatingActionButton: FloatingActionButton(
            tooltip: 'Criar',
            onPressed: () => showWorkspaceCreateSheet(
              context,
              date: context.read<AgendaCubit>().state.day,
            ),
            child: const Icon(Icons.add),
          ),
          child: const AgendaBrowser(),
        ),
      ),
      GoRoute(
        path: AppRoutes.goalPattern,
        builder: (_, state) => PremiumScope(
          child: AreaScaffold(
            title: 'Meta',
            child: GoalDetail(
              id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.weeklyPlanner,
        builder: (context, state) => Theme(
          data: buildTodayTheme(Theme.of(context)),
          child: BlocProvider(
            create: (_) =>
                WeeklyPlannerCubit(ref.read(workspaceClockProvider)()),
            child: AreaScaffold(
              title: 'Planear',
              child: PlanningScreen(
                initialView: state.extra is PlanningView
                    ? state.extra as PlanningView
                    : PlanningView.week,
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.progress,
        builder: (_, _) =>
            const AreaScaffold(title: 'Progresso', child: ProgressScreen()),
      ),
      for (final area in const {
        AppRoutes.habits: ('Hábitos', 'Hábitos'),
        AppRoutes.academics: ('Estudos', 'Estudos'),
        AppRoutes.finance: ('Finanças', 'Finanças'),
        AppRoutes.reviews: ('Revisões', 'Revisões'),
        AppRoutes.settings: ('Definições', 'Perfil'),
      }.entries)
        GoRoute(
          path: area.key,
          builder: (_, _) => AreaScaffold(
            title: area.value.$1,
            child: switch (area.key) {
              AppRoutes.habits => const HabitsScreen(embedded: true),
              AppRoutes.reviews => const ReviewsScreen(embedded: true),
              AppRoutes.settings => const SettingsScreen(embedded: true),
              _ => TudoAkiScreen(section: area.value.$2, embedded: true),
            },
          ),
        ),
    ],
  );

  @override
  void dispose() {
    router.dispose();
    modalGuard.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => AgendaCubit(ref.read(workspaceClockProvider)()),
      ),
      BlocProvider(create: (_) => GoalsCubit()),
      BlocProvider(create: (_) => TasksCubit()),
    ],
    child: MaterialApp.router(
      title: TudoAkiBrand.name,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: switch (ref
          .watch(dataProvider)
          .valueOrNull?['UserPreferences']
          ?.first['theme']) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      locale: const Locale('pt', 'PT'),
      supportedLocales: const [Locale('pt', 'PT')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    ),
  );
}

class TudoAkiShell extends StatelessWidget {
  const TudoAkiShell({
    required this.path,
    required this.child,
    this.navigationShell,
    this.modalGuard,
    super.key,
  });
  final String path;
  final Widget child;
  final StatefulNavigationShell? navigationShell;
  final ModalNavigationGuard? modalGuard;
  static final paths = AppNavigation.currentPaths;

  @override
  Widget build(BuildContext context) => Theme(
    data: buildTodayTheme(Theme.of(context)),
    child: Builder(
      builder: (context) => BackButtonListener(
        onBackButtonPressed: () async {
          if (modalGuard?.active.value == true ||
              GoRouter.of(context).canPop()) {
            return false;
          }
          if (navigationShell != null && navigationShell!.currentIndex != 0) {
            navigationShell!.goBranch(0);
            return true;
          }
          return false;
        },
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: child,
              ),
            ),
          ),
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: ValueListenableBuilder<bool>(
              valueListenable:
                  modalGuard?.active ?? const AlwaysStoppedAnimation(false),
              builder: (context, blocked, child) => AbsorbPointer(
                absorbing: blocked,
                child: NavigationBar(
                  animationDuration: const Duration(milliseconds: 250),
                  selectedIndex:
                      navigationShell?.currentIndex ??
                      (!paths.contains(path) ? 3 : paths.indexOf(path)),
                  onDestinationSelected: (index) {
                    if (modalGuard?.active.value == true) return;
                    if (navigationShell != null) {
                      navigationShell!.goBranch(
                        index,
                        initialLocation: index == 3,
                      );
                    } else {
                      context.go(paths[index]);
                    }
                  },
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    for (final destination in AppNavigation.currentDestinations)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        label: destination.title,
                      ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton:
              path == AppRoutes.agenda ||
                  path == AppRoutes.plan ||
                  path == AppRoutes.areas
              ? null
              : ValueListenableBuilder<bool>(
                  valueListenable:
                      modalGuard?.active ?? const AlwaysStoppedAnimation(false),
                  builder: (context, blocked, _) => Visibility(
                    visible: !blocked,
                    child: path == AppRoutes.goals
                        ? PremiumScope(
                            child: PremiumFocusOutline(
                              child: _createFab(context),
                            ),
                          )
                        : _createFab(context),
                  ),
                ),
        ),
      ),
    ),
  );

  Widget _createFab(BuildContext context) => FloatingActionButton(
    tooltip: 'Criar',
    onPressed: () async {
      if (path == AppRoutes.goals) {
        final saved = await showEditor(context, 'Meta', compact: true);
        if (saved != null && context.mounted) {
          context.read<GoalsCubit>().completed(false);
        }
        return;
      }
      await showWorkspaceCreateSheet(
        context,
        date: path == AppRoutes.agenda
            ? context.read<AgendaCubit>().state.day
            : null,
      );
    },
    child: const Icon(Icons.add),
  );
}

Future<void> showWorkspaceCreateSheet(
  BuildContext context, {
  DateTime? date,
}) async {
  context = PremiumScope.legacyContextOf(context);
  final kind = await showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 250),
      reverseDuration: Duration(milliseconds: 200),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Criar',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 16),
              for (final label in ['Evento', 'Tarefa', 'Meta'])
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  title: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  onTap: () => Navigator.pop(context, label),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  if (kind != null && context.mounted) {
    final now = DateTime.now();
    final at = date == null
        ? null
        : DateTime(date.year, date.month, date.day, now.hour, now.minute);
    final saved = await showEditor(
      context,
      kind,
      compact: true,
      initialDate: kind == 'Meta' ? null : at,
    );
    if (saved != null && context.mounted) {
      if (kind == 'Evento') {
        final event =
            (await ProviderScope.containerOf(
                  context,
                  listen: false,
                ).read(repositoryProvider).all('CalendarEvents'))
                .where((row) => row['id'] == saved)
                .firstOrNull;
        if (!context.mounted) return;
        if (event != null) {
          context.read<AgendaCubit>().select(
            DateTime.parse(event['start'] as String),
          );
          context.read<AgendaCubit>().mode('Dia');
        }
      }
      if (kind == 'Tarefa') context.read<TasksCubit>().completed(false);
      if (kind == 'Meta') context.read<GoalsCubit>().completed(false);
      context.go(switch (kind) {
        'Meta' => AppRoutes.goals,
        'Tarefa' => AppRoutes.tasks,
        _ => AppRoutes.agenda,
      });
    }
  }
}
