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
import '../features/agenda/domain/agenda_cubit.dart';
import '../features/goals/domain/goals_cubit.dart';
import '../features/tasks/domain/tasks_cubit.dart';
import '../features/goals/presentation/goal_detail.dart';
import '../features/areas/presentation/areas_screen.dart';
import '../core/theme/app_theme.dart';
import '../features/agenda/presentation/today_screen.dart';
import '../features/goals/presentation/goals_screen.dart';
import '../features/tasks/presentation/tasks_screen.dart';
import 'brand.dart';

class TudoAkiApp extends ConsumerStatefulWidget {
  const TudoAkiApp({super.key});
  @override
  ConsumerState<TudoAkiApp> createState() => _TudoAkiAppState();
}

class _TudoAkiAppState extends ConsumerState<TudoAkiApp> {
  late final router = GoRouter(
    routes: [
      ShellRoute(
        builder: (_, state, child) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => AgendaCubit(ref.read(workspaceClockProvider)()),
            ),
            BlocProvider(create: (_) => GoalsCubit()),
            BlocProvider(create: (_) => TasksCubit()),
          ],
          child: TudoAkiShell(path: state.uri.path, child: child),
        ),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const TodayScreen()),
          GoRoute(path: '/goals', builder: (_, _) => const GoalsScreen()),
          GoRoute(path: '/tasks', builder: (_, _) => const TasksScreen()),
        ],
      ),
      GoRoute(
        path: '/goal/:id',
        builder: (_, state) => AreaScaffold(
          title: 'Meta',
          child: GoalDetail(
            id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
          ),
        ),
      ),
      GoRoute(
        path: '/areas',
        builder: (_, _) =>
            const AreaScaffold(title: 'Mais', child: AreasScreen()),
      ),
      GoRoute(
        path: '/progress',
        builder: (_, _) =>
            const AreaScaffold(title: 'Progresso', child: ProgressScreen()),
      ),
      for (final area in const {
        '/habits': ('Hábitos', 'Hábitos'),
        '/academics': ('Estudos', 'Estudos'),
        '/finance': ('Finanças', 'Finanças'),
        '/reviews': ('Revisões', 'Revisões'),
        '/profile': ('Definições', 'Perfil'),
      }.entries)
        GoRoute(
          path: area.key,
          builder: (_, _) => AreaScaffold(
            title: area.value.$1,
            child: TudoAkiScreen(section: area.value.$2, embedded: true),
          ),
        ),
    ],
  );

  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
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
  );
}

class TudoAkiShell extends StatelessWidget {
  const TudoAkiShell({required this.path, required this.child, super.key});
  final String path;
  final Widget child;
  static const paths = ['/', '/goals', '/tasks'];

  @override
  Widget build(BuildContext context) => Scaffold(
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
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: NavigationBar(
        animationDuration: const Duration(milliseconds: 250),
        selectedIndex: paths.indexOf(path),
        onDestinationSelected: (index) => context.go(paths[index]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            label: 'Metas',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            label: 'Tarefas',
          ),
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton(
      tooltip: 'Criar',
      onPressed: () => showWorkspaceCreateSheet(
        context,
        date: path == '/' ? context.read<AgendaCubit>().state.day : null,
      ),
      child: const Icon(Icons.add),
    ),
  );
}

Future<void> showWorkspaceCreateSheet(
  BuildContext context, {
  DateTime? date,
}) async {
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
        'Meta' => '/goals',
        'Tarefa' => '/tasks',
        _ => '/',
      });
    }
  }
}
