import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../features/agenda/presentation/today_screen.dart';
import '../features/goals/presentation/goals_screen.dart';
import '../features/tasks/presentation/tasks_screen.dart';
import 'brand.dart';

class TudoAkiApp extends StatefulWidget {
  const TudoAkiApp({super.key});
  @override
  State<TudoAkiApp> createState() => _TudoAkiAppState();
}

class _TudoAkiAppState extends State<TudoAkiApp> {
  late final router = GoRouter(
    routes: [
      ShellRoute(
        builder: (_, state, child) =>
            TudoAkiShell(path: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const TodayScreen()),
          GoRoute(path: '/goals', builder: (_, _) => const GoalsScreen()),
          GoRoute(path: '/tasks', builder: (_, _) => const TasksScreen()),
        ],
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
    themeMode: ThemeMode.system,
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
      onPressed: () => showSkeletonCreateSheet(context),
      child: const Icon(Icons.add),
    ),
  );
}

Future<void> showSkeletonCreateSheet(BuildContext context) =>
    showModalBottomSheet<void>(
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
                    onTap: () => Navigator.pop(context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
