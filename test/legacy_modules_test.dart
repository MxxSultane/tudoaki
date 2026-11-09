import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/features/habits/presentation/habits_screen.dart';
import 'package:tudo_aki/features/reviews/presentation/reviews_screen.dart';
import 'package:tudo_aki/features/settings/presentation/settings_screen.dart';

Future<void> tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> openArea(
  WidgetTester tester,
  TudoAkiRepository repo,
  String title,
) async {
  await initializeDateFormatting('pt');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [repositoryProvider.overrideWithValue(repo)],
      child: const TudoAkiApp(),
    ),
  );
  await tester.runAsync(() => GoogleFonts.pendingFonts());
  await tester.pumpAndSettle();
  await tap(tester, find.text('Mais'));
  await tap(tester, find.widgetWithText(ListTile, title));
  expect(find.byType(NavigationDestination), findsNothing);
  expect(find.byType(FloatingActionButton), findsNothing);
}

void main() {
  late TudoAkiDatabase db;
  late TudoAkiRepository repo;
  setUp(() {
    db = TudoAkiDatabase.memory();
    repo = TudoAkiRepository(db);
  });
  tearDown(() => db.close());

  testWidgets('More opens habits, preserves records and daily XP idempotency', (
    tester,
  ) async {
    final id = await repo.save('Habits', {
      'title': 'Ler',
      'cue': 'Depois do almoço',
    });
    await repo.save('Habits', {'title': 'Correr', 'paused': 1});
    final before = await repo.all('Habits');
    await openArea(tester, repo, 'Hábitos');
    expect(find.byType(HabitsScreen), findsOneWidget);
    expect(find.text('Ler'), findsOneWidget);
    final paused = find.descendant(
      of: find.widgetWithText(ListTile, 'Correr'),
      matching: find.byType(Checkbox),
    );
    expect(tester.widget<Checkbox>(paused).onChanged, isNull);
    final checkbox = find.descendant(
      of: find.widgetWithText(ListTile, 'Ler'),
      matching: find.byType(Checkbox),
    );
    await tap(tester, checkbox);
    expect((await repo.all('HabitCompletions')).single['habit_id'], id);
    expect((await repo.all('ExperienceEvents')).single['points'], 5);
    await tap(tester, checkbox);
    expect(await repo.all('HabitCompletions'), isEmpty);
    await tap(tester, checkbox);
    expect(await repo.all('HabitCompletions'), hasLength(1));
    expect(await repo.all('ExperienceEvents'), hasLength(1));
    expect(await repo.all('Habits'), before);
    await tap(tester, find.byTooltip('Voltar'));
    await tap(tester, find.widgetWithText(ListTile, 'Hábitos'));
    expect(tester.widget<Checkbox>(checkbox).value, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('More creates a review and reads it after leaving the area', (
    tester,
  ) async {
    await openArea(tester, repo, 'Revisões');
    expect(find.byType(ReviewsScreen), findsOneWidget);
    await tap(tester, find.text('Nova'));
    for (final field in {
      'O que consegui realizar?': 'Li um capítulo',
      'O que ficou pendente?': 'Revisão final',
      'Quais foram os obstáculos?': 'Pouco tempo',
      'O que quero priorizar a seguir?': 'Preparar o próximo capítulo',
    }.entries) {
      final finder = find.widgetWithText(TextFormField, field.key);
      await tester.ensureVisible(finder);
      await tester.enterText(finder, field.value);
    }
    await tap(tester, find.widgetWithText(FilledButton, 'Guardar'));
    final review = (await repo.all('PeriodicReviews')).single;
    expect(review['period'], 'Semanal');
    expect(review['achieved'], 'Li um capítulo');
    expect(review['next'], 'Preparar o próximo capítulo');
    await tap(tester, find.byTooltip('Voltar'));
    await tap(tester, find.widgetWithText(ListTile, 'Revisões'));
    await tap(tester, find.text('Semanal · ${review['day']}'));
    expect(find.text('Realizações\nLi um capítulo'), findsOneWidget);
    expect(find.text('Pendentes\nRevisão final'), findsOneWidget);
    expect(find.text('Obstáculos\nPouco tempo'), findsOneWidget);
    expect(
      find.text('Próximas prioridades\nPreparar o próximo capítulo'),
      findsOneWidget,
    );
    expect((await repo.all('PeriodicReviews')).single, review);
    expect(await repo.all('ExperienceEvents'), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'More opens settings and preferences survive leaving and reopening',
    (tester) async {
      final task = await repo.save('Tasks', {
        'title': 'Preservar',
        'created': '2026-11-09T10:00:00',
      });
      await repo.taskDone(task, true);
      final experience = await repo.all('ExperienceEvents');
      await openArea(tester, repo, 'Definições');
      expect(find.byType(SettingsScreen), findsOneWidget);
      await tap(
        tester,
        find.widgetWithText(DropdownButtonFormField<String>, 'Aparência'),
      );
      await tap(tester, find.text('Escuro').last);
      await tap(
        tester,
        find.widgetWithText(
          DropdownButtonFormField<String>,
          'Moeda para novos registos',
        ),
      );
      await tap(tester, find.text('Dólar americano (USD)').last);
      await tap(tester, find.widgetWithText(SwitchListTile, 'Gamificação'));
      final prefs = (await repo.all('UserPreferences')).single;
      expect(prefs['theme'], 'dark');
      expect(prefs['currency'], 'USD');
      expect(prefs['gamification'], 0);
      await tap(tester, find.byTooltip('Voltar'));
      await tap(tester, find.widgetWithText(ListTile, 'Definições'));
      expect((await repo.all('UserPreferences')).single, prefs);
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.widgetWithText(DropdownButtonFormField<String>, 'Aparência'),
            )
            .initialValue,
        'dark',
      );
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
      expect(await repo.all('ExperienceEvents'), experience);
      expect((await repo.all('Tasks')).single['id'], task);
      expect(tester.takeException(), isNull);
    },
  );
}
