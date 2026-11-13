import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/theme/premium_tokens.dart';
import 'package:tudo_aki/core/widgets/premium_components.dart';
import 'package:tudo_aki/core/widgets/workspace_page.dart';
import 'package:tudo_aki/features/academics/academics_panel.dart';
import 'package:tudo_aki/features/academics/focus_timer.dart';
import 'package:tudo_aki/features/academics/study_repository.dart';
import 'package:tudo_aki/features/forms.dart';
import 'package:tudo_aki/features/tasks/presentation/quick_task_sheet.dart';
import 'support/today_fixture.dart';
import 'support/planning_fixture.dart' show PlanningReminders;

class StudiesRepo extends TudoAkiRepository {
  StudiesRepo(super.db);
  bool failRead = false;
  Completer<void>? gate;
  @override
  Future<List<DataRowMap>> all(String table) async {
    if (table == 'Tasks') {
      if (failRead) throw StateError('synthetic read failure');
      if (gate != null) await gate!.future;
    }
    return super.all(table);
  }
}

Future<void> boot(
  WidgetTester t,
  TudoAkiRepository repo,
  DateTime Function() clock, {
  bool settle = true,
}) async {
  await initializeDateFormatting('pt');
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        workspaceClockProvider.overrideWithValue(clock),
        studyClockProvider.overrideWithValue(clock),
        remindersProvider.overrideWithValue(PlanningReminders()),
      ],
      child: const TudoAkiApp(),
    ),
  );
  await t.runAsync(() => GoogleFonts.pendingFonts());
  if (settle) {
    await t.pumpAndSettle();
  } else {
    await t.pump(const Duration(milliseconds: 100));
  }
  GoRouter.of(t.element(find.byType(TudoAkiShell))).go('/academics');
  if (settle) {
    await t.pumpAndSettle();
  } else {
    await t.pump(const Duration(milliseconds: 350));
  }
}

Future<void> press(WidgetTester t, Finder f) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await t.pumpAndSettle();
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  expect(f.hitTestable(), findsOneWidget);
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<int> seed(TudoAkiRepository repo) async {
  final id = await repo.save('Subjects', {'title': 'Matemática'});
  await repo.save('Subjects', {
    'title': 'História da arte e cultura contemporânea',
  });
  await repo.save('Tasks', {
    'title': 'Preparar apresentação',
    'due': '2026-11-12',
    'subject_id': id,
    'created': '2026-01-01T12:34:56.123',
  });
  await repo.save('Tasks', {
    'title': 'Trabalho sem dia',
    'subject_id': id,
    'created': '2026-01-01',
  });
  await repo.save('Assessments', {
    'title': 'Teste de álgebra',
    'subject_id': id,
    'kind': 'Teste',
    'at': '2026-11-11T14:00:00',
    'minutes': 60,
  });
  await repo.saveStudy(
    title: 'Rever matéria',
    start: DateTime(2026, 11, 11, 16),
    subjectId: id,
    minutes: 25,
  );
  return id;
}

void main() {
  for (final dark in [false, true]) {
    for (final width in [320.0, 360.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'studies $dark ${width}dp ${scale}x hierarchy, semantics, targets, focus and reduced motion',
          (t) async {
            t.view.physicalSize = Size(width, 800);
            t.view.devicePixelRatio = 1;
            t.platformDispatcher.textScaleFactorTestValue = scale;
            t.platformDispatcher.accessibilityFeaturesTestValue =
                FakeAccessibilityFeatures(disableAnimations: scale == 2);
            addTearDown(t.view.resetPhysicalSize);
            addTearDown(t.view.resetDevicePixelRatio);
            addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
            addTearDown(
              t.platformDispatcher.clearAccessibilityFeaturesTestValue,
            );
            final db = TudoAkiDatabase.memory();
            addTearDown(db.close);
            final repo = TudoAkiRepository(db);
            final clock = DateTime(2026, 11, 11, 10, 30);
            await repo.save('UserPreferences', {
              'theme': dark ? 'dark' : 'light',
            }, id: 1);
            await seed(repo);
            final before = await todaySnapshot(repo);
            await boot(t, repo, () => clock);
            expect(find.text('Estudos'), findsOneWidget);
            expect(
              t.getTopLeft(find.text('Próximas actividades')).dy,
              lessThan(t.getTopLeft(find.text('Disciplinas')).dy),
            );
            expect(
              t.getTopLeft(find.text('Disciplinas')).dy,
              lessThan(t.getTopLeft(find.text('Sessão de estudo')).dy),
            );
            expect(find.text('Dia da tarefa: 12/11/2026'), findsOneWidget);
            expect(find.textContaining('Avaliação · Teste'), findsOneWidget);
            expect(find.textContaining('15 XP por sessão'), findsNothing);
            expect(
              find.descendant(
                of: find.byType(PremiumSurface),
                matching: find.byType(PremiumSurface),
              ),
              findsNothing,
            );
            expect(
              find.descendant(
                of: find.byType(AcademicsPanel),
                matching: find.byType(LinearProgressIndicator),
              ),
              findsNothing,
            );
            final add = find.widgetWithText(TextButton, 'Adicionar disciplina');
            final theme = Theme.of(t.element(add));
            expect(theme.extension<PremiumTokens>(), isNotNull);
            expect(
              theme.expansionTileTheme.iconColor,
              PremiumTokens(dark).action,
            );
            expect(
              theme.expansionTileTheme.collapsedIconColor,
              PremiumTokens(dark).action,
            );
            if (scale == 2) {
              expect(
                theme.expansionTileTheme.expansionAnimationStyle!.duration,
                Duration.zero,
              );
            }
            for (final f in [
              add,
              find.byType(Checkbox).first,
              find.byTooltip('Editar disciplina').first,
            ]) {
              final size = t.getSize(f);
              expect(size.width, greaterThanOrEqualTo(48));
              expect(size.height, greaterThanOrEqualTo(48));
            }
            await t.ensureVisible(add);
            await t.pumpAndSettle();
            Focus.of(
              t.element(
                find.descendant(of: add, matching: find.byType(Text)).first,
              ),
            ).requestFocus();
            await t.pumpAndSettle();
            expect(FocusManager.instance.primaryFocus!.hasFocus, isTrue);
            final side = theme.textButtonTheme.style!.side!.resolve({
              WidgetState.focused,
            })!;
            expect(side.width, 2);
            expect(side.color, PremiumTokens(dark).action);
            await t.sendKeyEvent(LogicalKeyboardKey.tab);
            await t.pumpAndSettle();
            final semantics = t.ensureSemantics();
            expect(t.getSemantics(add).label, contains('Adicionar disciplina'));
            semantics.dispose();
            await press(t, find.text('Matemática'));
            for (final label in [
              'Adicionar aula',
              'Adicionar avaliação',
              'Adicionar estudo',
              'Adicionar trabalho',
            ]) {
              final f = find.widgetWithText(TextButton, label);
              final size = t.getSize(f);
              expect(size.height, greaterThanOrEqualTo(48));
            }
            final heading = t.renderObject<RenderParagraph>(
              find.text('Próximas actividades'),
            );
            expect(heading.didExceedMaxLines, isFalse);
            expect(await todaySnapshot(repo), before);
            expect(t.takeException(), isNull);
            await t.pumpWidget(const SizedBox.shrink());
            await t.pumpAndSettle();
          },
        );
      }
    }
  }
  for (final gamification in [false, true]) {
    testWidgets(
      'studies resume, pause, navigate, complete, XP and idempotence gamification=$gamification',
      (t) async {
        final db = TudoAkiDatabase.memory();
        addTearDown(db.close);
        final repo = TudoAkiRepository(db);
        var now = DateTime(2026, 11, 11, 10, 30);
        final subject = await repo.save('Subjects', {'title': 'Matemática'});
        await repo.save('UserPreferences', {
          'gamification': gamification ? 1 : 0,
        }, id: 1);
        final id = await repo.saveStudy(
          title: 'Foco breve',
          subjectId: subject,
          start: now,
          minutes: 1,
        );
        await repo.startStudy(id, now: now);
        final end = (await repo.studyById(id))['focus_end'];
        await boot(t, repo, () => now);
        expect(find.byType(FocusTimerCard), findsNothing);
        await press(t, find.widgetWithText(FilledButton, 'Retomar foco'));
        expect((await repo.studyById(id))['focus_end'], end);
        expect(await repo.all('ExperienceEvents'), isEmpty);
        now = now.add(const Duration(seconds: 10));
        await t.pump(const Duration(seconds: 1));
        await press(t, find.widgetWithText(FilledButton, 'Pausar'));
        expect((await repo.studyById(id))['remaining_seconds'], 50);
        GoRouter.of(t.element(find.byType(AcademicsPanel))).go('/areas');
        await t.pumpAndSettle();
        now = now.add(const Duration(hours: 2));
        GoRouter.of(t.element(find.byType(TudoAkiShell))).go('/academics');
        await t.pumpAndSettle();
        await press(t, find.widgetWithText(FilledButton, 'Retomar foco'));
        expect(find.text('00:50'), findsOneWidget);
        await press(t, find.widgetWithText(FilledButton, 'Retomar'));
        now = now.add(const Duration(seconds: 50));
        await t.pump(const Duration(seconds: 1));
        expect(await repo.all('ExperienceEvents'), isEmpty);
        expect((await repo.studyById(id))['completed'], 0);
        await press(
          t,
          find.widgetWithText(FilledButton, 'Registar sessão concluída'),
        );
        await repo.completeStudy(id, now: now);
        expect((await repo.studyById(id))['completed'], 1);
        final xp = await repo.all('ExperienceEvents');
        expect(xp.length, gamification ? 1 : 0);
        if (gamification) expect(xp.single['points'], 15);
        expect(find.text('Histórico de estudo (1)'), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox.shrink());
        await t.pumpAndSettle();
      },
    );
  }
  testWidgets(
    'study work creates and edits same task with association and keyboard at 200%',
    (t) async {
      t.view.physicalSize = const Size(320, 640);
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetViewInsets);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = TudoAkiRepository(db);
      final subject = await repo.save('Subjects', {'title': 'Matemática'});
      await boot(t, repo, () => DateTime(2026, 11, 11, 10, 30));
      await press(t, find.text('Matemática'));
      await press(t, find.text('Adicionar trabalho'));
      expect(find.byType(QuickTaskSheet), findsOneWidget);
      await t.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Trabalho novo',
      );
      t.view.viewInsets = const FakeViewPadding(bottom: 280);
      await t.pumpAndSettle();
      final label = t.renderObject<RenderParagraph>(find.text('Nova tarefa'));
      expect(label.didExceedMaxLines, isFalse);
      await press(t, find.widgetWithText(FilledButton, 'Guardar'));
      final task = (await repo.all('Tasks')).single;
      expect(task['subject_id'], subject);
      expect(task['due'], isNull);
      t.view.viewInsets = FakeViewPadding.zero;
      await t.pumpAndSettle();
      await press(t, find.byTooltip('Editar tarefa'));
      expect(find.byType(Editor), findsOneWidget);
      await t.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Trabalho revisto',
      );
      t.view.viewInsets = const FakeViewPadding(bottom: 280);
      await t.pumpAndSettle();
      await press(t, find.widgetWithText(FilledButton, 'Guardar'));
      final expected = Map<String, Object?>.from(task)
        ..['title'] = 'Trabalho revisto';
      expect((await repo.all('Tasks')).single, expected);
      expect(await repo.all('ExperienceEvents'), isEmpty);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'read-only study, agenda and planning keep entities, dates and rows unchanged',
    (t) async {
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = TudoAkiRepository(db);
      await seed(repo);
      final before = await todaySnapshot(repo);
      await boot(t, repo, () => DateTime(2026, 11, 11, 10, 30));
      await press(t, find.text('Matemática'));
      await press(t, find.textContaining('Trabalhos e avaliações ('));
      expect(find.text('Dia da tarefa: Sem dia definido'), findsWidgets);
      final router = GoRouter.of(t.element(find.byType(AcademicsPanel)));
      for (final route in ['/calendar', '/plan', '/academics']) {
        router.go(route);
        await t.pumpAndSettle();
      }
      expect(await todaySnapshot(repo), before);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
    },
  );
  testWidgets('study read failure has retry and is distinct from empty', (
    t,
  ) async {
    final db = TudoAkiDatabase.memory();
    addTearDown(db.close);
    final repo = StudiesRepo(db)..failRead = true;
    await boot(t, repo, () => DateTime(2026, 11, 11));
    expect(find.text('Não foi possível abrir os dados.'), findsOneWidget);
    expect(
      find.text('Organiza aulas, avaliações e trabalhos por disciplina.'),
      findsNothing,
    );
    repo.failRead = false;
    await press(t, find.text('Tentar novamente'));
    expect(
      find.widgetWithText(FilledButton, 'Adicionar disciplina'),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox.shrink());
    await t.pumpAndSettle();
  });
  testWidgets('study loading does not announce a false empty state', (t) async {
    final db = TudoAkiDatabase.memory();
    addTearDown(db.close);
    final gate = Completer<void>();
    final repo = StudiesRepo(db)..gate = gate;
    await boot(t, repo, () => DateTime(2026, 11, 11), settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.text('Organiza aulas, avaliações e trabalhos por disciplina.'),
      findsNothing,
    );
    gate.complete();
    await t.pumpAndSettle();
    expect(
      find.widgetWithText(FilledButton, 'Adicionar disciplina'),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox.shrink());
    await t.pumpAndSettle();
  });
  testWidgets(
    'legacy completed session shows unknown completion date without fabricating history',
    (t) async {
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = TudoAkiRepository(db);
      await repo.save('StudySessions', {
        'title': 'Sessão antiga',
        'start': '2020-01-01T10:00:00',
        'minutes': 25,
        'completed': 1,
      });
      final before = await todaySnapshot(repo);
      await boot(t, repo, () => DateTime(2026, 11, 11));
      await press(t, find.text('Histórico de estudo (1)'));
      expect(
        find.textContaining('Data de conclusão não registada'),
        findsOneWidget,
      );
      expect(await todaySnapshot(repo), before);
      expect(await repo.all('ExperienceEvents'), isEmpty);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
    },
  );
}
