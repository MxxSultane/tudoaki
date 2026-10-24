import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/screens.dart';
import 'providers.dart';
import 'brand.dart';

final _router = GoRouter(
  routes: [
    ShellRoute(
      builder: (_, state, child) =>
          TudoAkiShell(path: state.uri.path, child: child),
      routes: [
        for (final entry in {
          '/': 'Hoje',
          '/agenda': 'Agenda',
          '/goals': 'Metas',
          '/progress': 'Progresso',
          '/profile': 'Perfil',
          '/habits': 'Hábitos',
          '/finance': 'Finanças',
          '/academics': 'Estudos',
          '/reviews': 'Revisões',
        }.entries)
          GoRoute(
            path: entry.key,
            builder: (context, state) => TudoAkiScreen(section: entry.value),
          ),
      ],
    ),
  ],
);

class TudoAkiApp extends ConsumerWidget {
  const TudoAkiApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref
        .watch(dataProvider)
        .valueOrNull?['UserPreferences']
        ?.first;
    final mode = switch (prefs?['theme']) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
    ThemeData theme(Brightness brightness) => ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: TudoAkiBrand.seedColor,
        brightness: brightness,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: 6),
      ),
    );
    return MaterialApp.router(
      title: TudoAkiBrand.name,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: mode,
      locale: const Locale('pt', 'MZ'),
      supportedLocales: const [Locale('pt', 'MZ'), Locale('pt')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}

class TudoAkiShell extends StatelessWidget {
  const TudoAkiShell({required this.path, required this.child, super.key});
  final String path;
  final Widget child;
  static const paths = ['/', '/agenda', '/goals', '/progress', '/profile'];
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: child,
        ),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: paths.contains(path) ? paths.indexOf(path) : 4,
      onDestinationSelected: (i) => context.go(paths[i]),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.wb_sunny_outlined),
          label: 'Hoje',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          label: 'Agenda',
        ),
        NavigationDestination(icon: Icon(Icons.flag_outlined), label: 'Metas'),
        NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          label: 'Progresso',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Perfil',
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => showQuickCreate(context),
      icon: const Icon(Icons.add),
      label: const Text('Criar'),
    ),
  );
}
