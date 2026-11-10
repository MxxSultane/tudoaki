import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/features/areas/presentation/areas_screen.dart';
import 'package:tudo_aki/features/forms.dart';
import 'package:tudo_aki/features/tasks/presentation/quick_task_sheet.dart';
import 'quick_task_sheet_test.dart' as sheet;

void main() {
  for (final reminderAllowed in [true, false]) {
    testWidgets(
      'academic entry preserves origin and full editor; reminder allowed=$reminderAllowed',
      (tester) async {
        await initializeDateFormatting('pt');
        final db = TudoAkiDatabase.memory();
        addTearDown(db.close);
        final repo = TudoAkiRepository(db);
        final reminders = sheet.QuickReminders()..allowed = reminderAllowed;
        final subject = await repo.save('Subjects', {'title': 'História'});
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              repositoryProvider.overrideWithValue(repo),
              remindersProvider.overrideWithValue(reminders),
            ],
            child: const TudoAkiApp(),
          ),
        );
        await tester.runAsync(() => GoogleFonts.pendingFonts());
        await tester.pumpAndSettle();
        await sheet.tap(tester, find.text('Mais'));
        await sheet.tap(tester, find.widgetWithText(ListTile, 'Estudos'));
        await sheet.tap(tester, find.text('História'));
        await sheet.tap(tester, find.text('Adicionar trabalho'));
        expect(find.byType(QuickTaskSheet), findsOneWidget);
        expect(find.byType(Editor), findsNothing);
        expect(find.text('Disciplina: História'), findsOneWidget);
        if (!reminderAllowed) {
          // Select a future day in the real picker without relying on today's date.
          await sheet.tap(tester, find.text('Dia: Sem data'));
          await sheet.tap(
            tester,
            find.byTooltip(
              MaterialLocalizations.of(
                tester.element(find.byType(QuickTaskSheet)),
              ).inputDateModeButtonLabel,
            ),
          );
          await tester.enterText(find.byType(TextFormField).last, '02/01/2090');
          await sheet.tap(tester, find.text('OK'));
          await sheet.more(tester);
          await sheet.tap(tester, find.text('Definir hora'));
          await sheet.tap(tester, find.text('OK'));
          await sheet.tap(
            tester,
            find.widgetWithText(SwitchListTile, 'Lembrete local'),
          );
        }
        await sheet.title(tester, 'Trabalho novo');
        await sheet.save(tester);
        expect(
          GoRouterState.of(tester.element(find.byType(AreaScaffold))).uri.path,
          '/academics',
        );
        expect(find.byType(NavigationDestination), findsNothing);
        expect(find.text('Adicionar trabalho'), findsOneWidget);
        expect(find.text('Trabalho novo'), findsOneWidget);
        expect(
          find.text(
            reminderAllowed
                ? 'Tarefa guardada.'
                : 'Tarefa guardada; lembrete indisponível.',
          ),
          findsOneWidget,
        );
        final row = (await repo.all('Tasks')).single;
        expect(row['subject_id'], subject);
        expect(row['due'], reminderAllowed ? null : '2090-01-02T09:00:00.000');
        expect(await repo.all('ExperienceEvents'), isEmpty);
        // Editing still opens the old complete Editor, with the saved ID untouched.
        await sheet.tap(tester, find.byTooltip('Editar tarefa'));
        expect(find.byType(Editor), findsOneWidget);
        expect(find.byType(QuickTaskSheet), findsNothing);
        Navigator.of(tester.element(find.byType(Editor))).pop();
        await tester.pumpAndSettle();
        expect((await repo.all('Tasks')).single, row);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
