import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tudo_aki/app/providers.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/notifications/reminders.dart';
import 'package:tudo_aki/core/theme/app_theme.dart';
import 'package:tudo_aki/features/tasks/domain/task_operations.dart';
import 'package:tudo_aki/features/tasks/presentation/quick_task_sheet.dart';

class QuickReminders extends Reminders {
  bool allowed = true;
  final cancelled = <int>[];
  final scheduled = <({int id, String title, DateTime date})>[];
  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
  }

  @override
  Future<bool> schedule(int id, String title, DateTime date) async {
    scheduled.add((id: id, title: title, date: date));
    return allowed;
  }
}

class FailingQuickRepository extends TudoAkiRepository {
  FailingQuickRepository(super.db);
  bool fail = true;
  @override
  Future<int> save(String table, DataRowMap data, {int? id}) {
    if (table == 'Tasks' && fail)
      return Future.error(StateError('disk failure'));
    return super.save(table, data, id: id);
  }
}

class GatedQuickOperations extends TaskOperations {
  GatedQuickOperations(TudoAkiRepository repo, Reminders reminders)
    : super(repo, reminders, refresh: () {});
  final gate = Completer<void>();
  int calls = 0;
  @override
  Future<TaskWriteResult> create(
    DataRowMap fields, {
    bool? reconcileReminders,
  }) async {
    calls++;
    await gate.future;
    return super.create(fields, reconcileReminders: reconcileReminders);
  }
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> open(
  WidgetTester tester,
  TudoAkiRepository repo,
  QuickReminders reminders, {
  DateTime? day,
  int? goal,
  int? subject,
  TaskOperations? operations,
  void Function(TaskWriteResult?)? onResult,
}) async {
  await initializeDateFormatting('pt');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        remindersProvider.overrideWithValue(reminders),
        if (operations != null)
          taskOperationsProvider.overrideWithValue(operations),
      ],
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        locale: const Locale('pt', 'PT'),
        supportedLocales: const [Locale('pt', 'PT')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await showQuickTaskSheet(
                  context,
                  initialDate: day,
                  goalId: goal,
                  subjectId: subject,
                );
                onResult?.call(result);
              },
              child: const Text('Abrir tarefa'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.runAsync(() => GoogleFonts.pendingFonts());
  await tester.pumpAndSettle();
  await tap(tester, find.text('Abrir tarefa'));
}

Future<void> title(WidgetTester tester, String value) =>
    tester.enterText(find.widgetWithText(TextFormField, 'Título'), value);
Future<void> save(WidgetTester tester) =>
    tap(tester, find.widgetWithText(FilledButton, 'Guardar'));
Future<void> more(WidgetTester tester) => tap(tester, find.text('Mais opções'));

void main() {
  late TudoAkiDatabase db;
  late TudoAkiRepository repo;
  late QuickReminders reminders;
  setUp(() {
    db = TudoAkiDatabase.memory();
    repo = TudoAkiRepository(db);
    reminders = QuickReminders();
  });
  tearDown(() => db.close());

  testWidgets(
    'opens focused with keyboard, title-only save returns without a date',
    (tester) async {
      TaskWriteResult? result;
      await open(tester, repo, reminders, onResult: (value) => result = value);
      expect(find.byType(QuickTaskSheet), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(tester.testTextInput.isVisible, isTrue);
      expect(await repo.all('Tasks'), isEmpty);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Guardar'))
            .onPressed,
        isNull,
      );
      await title(tester, 'Comprar pão');
      await save(tester);
      final row = (await repo.all('Tasks')).single;
      expect(result!.id, row['id']);
      expect(row['title'], 'Comprar pão');
      expect(row['due'], isNull);
      expect(row['priority'], 1);
      expect(row['important'], 0);
      expect(row['reminder'], 0);
      expect(row['goal_id'], isNull);
      expect(row['subject_id'], isNull);
      expect(find.byType(QuickTaskSheet), findsNothing);
      expect(find.text('Abrir tarefa'), findsOneWidget);
      expect(await repo.all('ExperienceEvents'), isEmpty);
    },
  );

  testWidgets('context supplies a day without inheriting an implicit time', (
    tester,
  ) async {
    await open(tester, repo, reminders, day: DateTime(2090, 1, 2, 18, 30));
    expect(find.textContaining('Dia: 2 '), findsOneWidget);
    await title(tester, 'Preparar');
    await save(tester);
    expect((await repo.all('Tasks')).single['due'], '2090-01-02');
    expect(reminders.scheduled, isEmpty);
  });

  testWidgets('day can be changed in the picker and saved with no time', (
    tester,
  ) async {
    await open(tester, repo, reminders, day: DateTime(2090, 1, 2));
    await tap(tester, find.textContaining('Dia: 2 '));
    await tap(tester, find.text('3').last);
    await tap(tester, find.text('OK'));
    await title(tester, 'Dia escolhido');
    await save(tester);
    expect((await repo.all('Tasks')).single['due'], '2090-01-03');
  });

  testWidgets(
    'optional associations and fields persist with existing values only',
    (tester) async {
      final goal = await repo.save('Goals', {
        'title': 'Ler',
        'target': 12,
        'created': '2026-11-10',
      });
      final subject = await repo.save('Subjects', {'title': 'História'});
      await open(tester, repo, reminders);
      await title(tester, 'Fontes');
      await more(tester);
      await tap(
        tester,
        find.widgetWithText(DropdownButtonFormField<int>, 'Meta associada'),
      );
      await tap(tester, find.text('Ler').last);
      await tap(
        tester,
        find.widgetWithText(DropdownButtonFormField<int>, 'Disciplina'),
      );
      await tap(tester, find.text('História').last);
      await tap(
        tester,
        find.widgetWithText(DropdownButtonFormField<int>, 'Prioridade'),
      );
      await tap(tester, find.text('Alta').last);
      await tap(tester, find.widgetWithText(SwitchListTile, 'Importante'));
      await save(tester);
      final row = (await repo.all('Tasks')).single;
      expect(row['goal_id'], goal);
      expect(row['subject_id'], subject);
      expect(row['priority'], 2);
      expect(row['important'], 1);
      expect(row['due'], isNull);
      expect(row['completed'], 0);
    },
  );

  testWidgets('removing day clears the explicit time and reminder', (
    tester,
  ) async {
    await open(tester, repo, reminders, day: DateTime(2090, 1, 2));
    await title(tester, 'Sem data');
    await more(tester);
    await tap(tester, find.text('Definir hora'));
    await tap(tester, find.text('OK'));
    await tap(tester, find.widgetWithText(SwitchListTile, 'Lembrete local'));
    await tap(tester, find.text('Retirar dia'));
    await save(tester);
    final row = (await repo.all('Tasks')).single;
    expect(row['due'], isNull);
    expect(row['reminder'], 0);
    expect(reminders.scheduled, isEmpty);
    expect(reminders.cancelled, isEmpty);
  });

  testWidgets(
    'explicit time uses TaskOperations and returns a scheduling failure honestly',
    (tester) async {
      reminders.allowed = false;
      TaskWriteResult? result;
      await open(
        tester,
        repo,
        reminders,
        day: DateTime(2090, 1, 2),
        onResult: (value) => result = value,
      );
      await title(tester, 'Consulta');
      await more(tester);
      await tap(tester, find.text('Definir hora'));
      await tap(tester, find.text('OK'));
      await tap(tester, find.widgetWithText(SwitchListTile, 'Lembrete local'));
      await save(tester);
      final row = (await repo.all('Tasks')).single;
      expect(row['due'], '2090-01-02T09:00:00.000');
      expect(
        row['reminder'],
        1,
      ); // Existing reminder intent, not a delivery guarantee.
      expect(result!.reminderFailure, TaskReminderFailure.unavailable);
      expect(reminders.cancelled, [row['id']]);
      expect(reminders.scheduled.single.id, row['id']);
      expect(reminders.scheduled.single.date, DateTime(2090, 1, 2, 9));
      expect(await repo.all('Tasks'), hasLength(1));
    },
  );

  testWidgets(
    'save another keeps only day and associations and never repeats a save on close',
    (tester) async {
      final goal = await repo.save('Goals', {
        'title': 'Ler',
        'target': 12,
        'created': '2026-11-10',
      });
      final subject = await repo.save('Subjects', {'title': 'História'});
      TaskWriteResult? result;
      await open(
        tester,
        repo,
        reminders,
        day: DateTime(2090, 1, 2),
        goal: goal,
        subject: subject,
        onResult: (value) => result = value,
      );
      await title(tester, 'Primeira');
      await more(tester);
      await tap(tester, find.text('Definir hora'));
      await tap(tester, find.text('OK'));
      await tap(tester, find.widgetWithText(SwitchListTile, 'Lembrete local'));
      await tap(
        tester,
        find.widgetWithText(DropdownButtonFormField<int>, 'Prioridade'),
      );
      await tap(tester, find.text('Alta').last);
      await tap(tester, find.widgetWithText(SwitchListTile, 'Importante'));
      await tap(tester, find.text('Guardar e adicionar outra'));
      expect(await repo.all('Tasks'), hasLength(1));
      expect(find.text('Tarefa guardada.'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.widgetWithText(TextFormField, 'Título'))
            .controller!
            .text,
        isEmpty,
      );
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(find.text('Meta: Ler'), findsOneWidget);
      expect(find.text('Disciplina: História'), findsOneWidget);
      await title(tester, 'Segunda');
      await save(tester);
      final rows = await repo.all('Tasks');
      expect(rows, hasLength(2));
      expect(rows.map((r) => r['id']).toSet(), hasLength(2));
      final second = rows.singleWhere((r) => r['title'] == 'Segunda');
      expect(second['due'], '2090-01-02');
      expect(second['goal_id'], goal);
      expect(second['subject_id'], subject);
      expect(second['priority'], 1);
      expect(second['important'], 0);
      expect(second['reminder'], 0);
      expect(result!.id, second['id']);
      expect(reminders.scheduled, hasLength(1));
    },
  );

  testWidgets('clean cancel and clean system back discard without a dialog', (
    tester,
  ) async {
    await open(tester, repo, reminders, day: DateTime(2090, 1, 2));
    await tap(tester, find.text('Cancelar'));
    expect(find.byType(AlertDialog), findsNothing);
    await tap(tester, find.text('Abrir tarefa'));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(QuickTaskSheet), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(await repo.all('Tasks'), isEmpty);
  });

  testWidgets('dirty cancel and system back offer discard without writing', (
    tester,
  ) async {
    await open(tester, repo, reminders);
    await title(tester, 'Rascunho');
    await tap(tester, find.text('Cancelar'));
    expect(find.text('Descartar alterações?'), findsOneWidget);
    await tap(tester, find.text('Continuar a editar'));
    expect(find.text('Rascunho'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tap(tester, find.widgetWithText(FilledButton, 'Descartar'));
    expect(await repo.all('Tasks'), isEmpty);
    expect(find.byType(QuickTaskSheet), findsNothing);
  });

  testWidgets(
    'failure keeps draft and associations and retry creates exactly one row',
    (tester) async {
      final failing = FailingQuickRepository(db);
      final subject = await failing.save('Subjects', {'title': 'História'});
      await open(
        tester,
        failing,
        reminders,
        subject: subject,
        day: DateTime(2090, 1, 2),
      );
      await title(tester, 'Guardar depois');
      await save(tester);
      expect(
        find.text('Não foi possível guardar. Tenta novamente.'),
        findsOneWidget,
      );
      expect(find.text('Guardar depois'), findsOneWidget);
      expect(find.byType(QuickTaskSheet), findsOneWidget);
      expect(await failing.all('Tasks'), isEmpty);
      failing.fail = false;
      await save(tester);
      final row = (await failing.all('Tasks')).single;
      expect(row['title'], 'Guardar depois');
      expect(row['subject_id'], subject);
      expect(row['due'], '2090-01-02');
    },
  );

  testWidgets(
    'busy guard blocks repeated taps, keyboard submission and closing',
    (tester) async {
      final operations = GatedQuickOperations(repo, reminders);
      await open(tester, repo, reminders, operations: operations);
      await title(tester, 'Uma vez');
      final button = find.widgetWithText(FilledButton, 'Guardar');
      await tester.ensureVisible(button);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.tap(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(operations.calls, 1);
      expect(await repo.all('Tasks'), isEmpty);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(QuickTaskSheet), findsOneWidget);
      operations.gate.complete();
      await tester.pumpAndSettle();
      expect(await repo.all('Tasks'), hasLength(1));
      expect(find.byType(QuickTaskSheet), findsNothing);
    },
  );

  testWidgets(
    'discarding the next draft preserves already saved tasks and returns their result',
    (tester) async {
      TaskWriteResult? result;
      await open(tester, repo, reminders, onResult: (value) => result = value);
      await title(tester, 'Guardada');
      await tap(tester, find.text('Guardar e adicionar outra'));
      final id = (await repo.all('Tasks')).single['id'];
      await title(tester, 'Descartada');
      await tap(tester, find.text('Cancelar'));
      await tap(tester, find.widgetWithText(FilledButton, 'Descartar'));
      expect((await repo.all('Tasks')).single['title'], 'Guardada');
      expect(result!.id, id);
    },
  );

  testWidgets(
    'closing a clean next draft returns the saved result without confirmation',
    (tester) async {
      TaskWriteResult? result;
      await open(tester, repo, reminders, onResult: (value) => result = value);
      await title(tester, 'Guardada uma vez');
      await tap(tester, find.text('Guardar e adicionar outra'));
      final id = (await repo.all('Tasks')).single['id'];
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(QuickTaskSheet), findsNothing);
      expect(result!.id, id);
      expect(await repo.all('Tasks'), hasLength(1));
    },
  );

  testWidgets(
    'all fields and save remain reachable at 360px with keyboard and 200 percent text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      for (final brightness in Brightness.values) {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        await open(tester, repo, reminders, day: DateTime(2090, 1, 2));
        await title(tester, 'Texto legível');
        await more(tester);
        await save(tester);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
      expect(await repo.all('Tasks'), hasLength(2));
    },
  );
}
