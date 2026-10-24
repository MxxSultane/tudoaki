import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/features/academics/focus_timer.dart';
import 'package:tudo_aki/features/screens.dart';

void main() {
  testWidgets(
    'plan classes and assessments, then pause, resume and complete focus',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Future<void> tapVisible(Finder finder) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        expect(finder.hitTestable(), findsOneWidget);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await initializeDateFormatting('pt');
      final db = TudoAkiDatabase.memory();
      final repo = TudoAkiRepository(db);
      addTearDown(db.close);
      final subject = await tester.runAsync(
        () => repo.save('Subjects', {'title': 'Matemática'}),
      );
      var now = DateTime.utc(2026, 10, 24, 10);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(repo),
            studyClockProvider.overrideWithValue(() => now),
          ],
          child: const MaterialApp(
            home: Scaffold(body: TudoAkiScreen(section: 'Estudos')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(find.text('Matemática'));
      await tapVisible(find.text('Adicionar aula'));
      await tapVisible(find.widgetWithText(FilledButton, 'Guardar'));
      expect((await repo.all('ClassSchedules')).single['subject_id'], subject);

      await tapVisible(find.text('Adicionar avaliação'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Teste de álgebra',
      );
      await tapVisible(find.widgetWithText(FilledButton, 'Guardar'));
      final examTile = find.ancestor(
        of: find.text('Teste de álgebra'),
        matching: find.byType(ListTile),
      );
      await tapVisible(
        find.descendant(of: examTile, matching: find.byType(Checkbox)),
      );
      expect((await repo.all('Assessments')).single['completed'], 1);
      expect((await repo.all('Assessments')).single['subject_id'], subject);

      await tapVisible(find.text('Adicionar estudo'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Revisão de álgebra',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Duração em minutos'),
        '1',
      );
      await tapVisible(find.widgetWithText(FilledButton, 'Guardar'));
      expect((await repo.all('StudySessions')).single['minutes'], 1);
      await tapVisible(find.byTooltip('Abrir foco'));
      expect(find.text('01:00'), findsOneWidget);
      await tapVisible(find.widgetWithText(FilledButton, 'Iniciar foco'));
      expect((await repo.all('StudySessions')).single['focus_end'], isNotNull);
      now = now.add(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 1));
      await tapVisible(find.widgetWithText(FilledButton, 'Pausar'));
      expect((await repo.all('StudySessions')).single['remaining_seconds'], 50);
      now = now.add(const Duration(hours: 2));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:50'), findsOneWidget);
      await tapVisible(find.widgetWithText(FilledButton, 'Retomar'));
      now = now.add(const Duration(seconds: 50));
      await tester.pump(const Duration(seconds: 1));
      await tapVisible(
        find.widgetWithText(FilledButton, 'Registar sessão concluída'),
      );
      expect((await repo.all('StudySessions')).single['completed'], 1);
      expect((await repo.all('ExperienceEvents')).single['points'], 15);
      expect(find.text('Histórico de estudo (1)'), findsOneWidget);
      await tapVisible(find.text('Ocultar temporizador'));
      expect(find.text('Tempo de foco'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('agenda shows academic planning and overlapping class and exam', (
    tester,
  ) async {
    await initializeDateFormatting('pt');
    final db = TudoAkiDatabase.memory();
    final repo = TudoAkiRepository(db);
    addTearDown(db.close);
    final day = DateTime.now();
    await tester.runAsync(() async {
      final subject = await repo.save('Subjects', {'title': 'Matemática'});
      await repo.save('ClassSchedules', {
        'subject_id': subject,
        'weekday': day.weekday,
        'start_minute': 540,
        'end_minute': 600,
        'active_from': dayKey(day),
      });
      await repo.save('Assessments', {
        'subject_id': subject,
        'title': 'Álgebra',
        'kind': 'Exame',
        'at': DateTime(day.year, day.month, day.day, 9, 30).toIso8601String(),
        'minutes': 60,
      });
      await repo.save('StudySessions', {
        'title': 'Rever álgebra',
        'start': DateTime(day.year, day.month, day.day, 11).toIso8601String(),
        'minutes': 25,
        'remaining_seconds': 1500,
      });
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: Scaffold(body: TudoAkiScreen(section: 'Agenda')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aula · Matemática'), findsOneWidget);
    expect(find.text('Exame · Álgebra'), findsOneWidget);
    expect(find.text('Estudo · Rever álgebra'), findsOneWidget);
    expect(find.textContaining('Conflito de horário'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
