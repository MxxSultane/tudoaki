import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tudo_aki/app/app.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/widgets/premium_components.dart';
import 'package:tudo_aki/core/theme/premium_tokens.dart';
import 'package:tudo_aki/features/forms.dart';
import 'package:tudo_aki/features/goals/goal_deadline.dart';
import 'support/today_fixture.dart';

Finder field(String label) => find.widgetWithText(TextFormField, label);
Future<void> press(WidgetTester t, Finder f) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await t.pumpAndSettle();
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> open(
  WidgetTester t,
  TodayRepository r, {
  DataRowMap? existing,
}) async {
  await bootToday(t, r);
  showEditor(
    t.element(find.byType(TudoAkiShell)),
    'Meta',
    existing: existing,
    compact: true,
  );
  await t.pumpAndSettle();
}

void main() {
  test(
    'deadline uses civil dates across months, leap years and year boundary',
    () {
      expect(
        goalDeadlineFromDays('1', DateTime(2026, 11, 12, 23, 59)),
        '2026-11-13',
      );
      expect(goalDeadlineFromDays('30', DateTime(2026, 11, 12)), '2026-12-12');
      expect(goalDeadlineFromDays('1', DateTime(2028, 2, 28)), '2028-02-29');
      expect(goalDeadlineFromDays('1', DateTime(2026, 12, 31)), '2027-01-01');
      expect(goalDeadlineFromDays('  ', DateTime(2026)), isNull);
      expect(goalDeadlineLabel('2026-12-31T23:59:58.123+02:00'), '31/12/2026');
      expect(goalDeadlineLabel('2026-12-31T00:30:00+02:00'), '30/12/2026');
    },
  );
  test(
    'deadline rejects invalid or unrepresentable day counts without writing',
    () {
      for (final input in [
        '0',
        '-1',
        '1.5',
        '1,5',
        'abc',
        '9999999999999999999999',
      ]) {
        expect(
          () => goalDeadlineFromDays(input, DateTime(2026)),
          throwsFormatException,
        );
      }
      expect(goalDeadlineFromDays('1', DateTime(2099, 12, 31)), '2100-01-01');
      expect(
        () => goalDeadlineFromDays('2', DateTime(2099, 12, 31)),
        throwsFormatException,
      );
    },
  );

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'goal create $dark/$scale: explicit metric, deadline, focus, keyboard and targets at 320dp',
        (t) async {
          t.view.physicalSize = const Size(320, 640);
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          addTearDown(t.view.resetViewInsets);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          final db = TudoAkiDatabase.memory();
          addTearDown(db.close);
          var now = DateTime(2026, 11, 12, 23, 59);
          final repo = TodayRepository(db, () => now);
          await repo.save('UserPreferences', {
            'theme': dark ? 'dark' : 'light',
          }, id: 1);
          await open(t, repo);
          expect(field('Valor pretendido'), findsNothing);
          expect(find.text('Horizonte'), findsNothing);
          final deadlineLabel = find.descendant(
            of: field('Prazo opcional em dias'),
            matching: find.text('Prazo opcional em dias'),
          );
          final paragraph = t.renderObject<RenderParagraph>(deadlineLabel.last);
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(paragraph.overflow, isNot(TextOverflow.ellipsis));
          await t.enterText(field('Título'), 'Ler com prazer');
          await press(t, find.widgetWithText(FilledButton, 'Criar'));
          expect(await repo.all('Goals'), isEmpty);
          expect(field('Valor pretendido'), findsOneWidget);
          expect(
            t.widget<TextFormField>(field('Valor pretendido')).controller!.text,
            isEmpty,
          );
          expect(
            t
                .widget<TextFormField>(
                  field('Métrica de sucesso (ex.: livros)'),
                )
                .controller!
                .text,
            isEmpty,
          );
          await t.enterText(
            field('Métrica de sucesso (ex.: livros)'),
            'livros',
          );
          await t.enterText(field('Valor pretendido'), '12');
          await t.ensureVisible(field('Prazo opcional em dias'));
          await t.pumpAndSettle();
          await t.enterText(field('Prazo opcional em dias'), '1');
          await t.pumpAndSettle();
          expect(find.text('13/11/2026'), findsOneWidget);
          now = DateTime(
            2026,
            11,
            13,
            0,
            1,
          ); // Freeze the absolute preview, do not restart.
          t.view.viewInsets = const FakeViewPadding(bottom: 280);
          await t.pumpAndSettle();
          await t.ensureVisible(field('Valor pretendido'));
          await t.pumpAndSettle();
          await t.tap(field('Valor pretendido'));
          await t.pumpAndSettle();
          final inputContext = t.element(
            find.descendant(
              of: field('Valor pretendido'),
              matching: find.byType(EditableText),
            ),
          );
          expect(Focus.of(inputContext).hasFocus, isTrue);
          final ancestor = find
              .ancestor(
                of: field('Valor pretendido'),
                matching: find.byType(PremiumFocusOutline),
              )
              .first;
          final ring =
              t
                      .widget<DecoratedBox>(
                        find
                            .descendant(
                              of: ancestor,
                              matching: find.byKey(
                                const ValueKey('premium-focus-ring'),
                              ),
                            )
                            .first,
                      )
                      .decoration
                  as BoxDecoration;
          expect(ring.border!.top.width, 2);
          expect(ring.border!.top.color, PremiumTokens(dark).action);
          for (final f in [
            field('Título'),
            field('Prazo opcional em dias'),
            field('Valor pretendido'),
            find.widgetWithText(FilledButton, 'Criar'),
          ]) {
            final size = t.getSize(f);
            expect(size.width, greaterThanOrEqualTo(48));
            expect(size.height, greaterThanOrEqualTo(48));
          }
          await t.sendKeyEvent(LogicalKeyboardKey.tab);
          await t.pumpAndSettle();
          await press(t, find.widgetWithText(FilledButton, 'Criar'));
          final goal = (await repo.all('Goals')).single;
          expect(goal['due'], '2026-11-13');
          expect(goal['unit'], 'livros');
          expect(goal['target'], 12);
          expect(goal['initial'], 0);
          expect(goal['current'], 0);
          expect(await repo.all('GoalProgress'), isEmpty);
          expect(await repo.all('ExperienceEvents'), isEmpty);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox.shrink());
          await t.pumpAndSettle();
        },
      );
    }
  }

  testWidgets(
    'legacy goal rename preserves exact due, status, history, links and reopens from synthetic file',
    (t) async {
      final dir = Directory.systemTemp.createTempSync('goal-v5-');
      final file = File('${dir.path}/synthetic.sqlite');
      var db = TudoAkiDatabase(NativeDatabase(file));
      try {
        var repo = TodayRepository(db, () => DateTime(2026, 11, 12));
        final parent = await repo.save('Goals', {
          'title': 'Principal',
          'target': 100,
          'created': '2020-01-01',
        });
        final id = await repo.save('Goals', {
          'title': 'Legado',
          'description': ' Texto original ',
          'category': ' Área antiga ',
          'horizon': 'Personalizado',
          'initial': 2,
          'target': 12,
          'current': 3,
          'unit': ' livros ',
          'status': 'completed',
          'due': '2026-12-31T23:59:58.123+02:00',
          'created': '2020-02-29T14:20:30.123Z',
          'parent_id': parent,
        });
        await repo.save('GoalProgress', {
          'goal_id': id,
          'value': 3,
          'recorded_at': '2020-03-01T12:00:00Z',
        });
        await repo.save('GoalMilestones', {
          'goal_id': id,
          'title': 'Etapa',
          'completed': 1,
        });
        await repo.save('Habits', {'title': 'Ler', 'goal_id': id});
        await repo.save('Tasks', {
          'title': 'Capítulo',
          'goal_id': id,
          'created': '2020-01-01',
        });
        final before = await todaySnapshot(repo);
        final original = (await repo.all(
          'Goals',
        )).firstWhere((g) => g['id'] == id);
        await open(t, repo, existing: original);
        await t.enterText(field('Título'), 'Legado revisto');
        await press(t, find.widgetWithText(FilledButton, 'Guardar'));
        final expected = Map<String, Object?>.from(original)
          ..['title'] = 'Legado revisto';
        expect(
          (await repo.all('Goals')).firstWhere((g) => g['id'] == id),
          expected,
        );
        for (final table in [
          'GoalProgress',
          'GoalMilestones',
          'Habits',
          'Tasks',
          'ExperienceEvents',
        ]) {
          expect(await repo.all(table), before[table]);
        }
        await t.pumpWidget(const SizedBox.shrink());
        await t.pumpAndSettle();
        await db.close();
        db = TudoAkiDatabase(NativeDatabase(file));
        repo = TodayRepository(db, () => DateTime(2026, 12, 1));
        expect(
          (await repo.all('Goals')).firstWhere((g) => g['id'] == id),
          expected,
        );
        expect(t.takeException(), isNull);
      } finally {
        await db.close();
        dir.deleteSync(recursive: true);
      }
    },
  );

  testWidgets(
    'deadline edits are explicit, removable, and invalid drafts never save',
    (t) async {
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = TodayRepository(db, () => DateTime(2026, 11, 12));
      final id = await repo.save('Goals', {
        'title': 'Ler',
        'target': 12,
        'unit': 'livros',
        'due': '2027-01-01',
        'created': '2026-01-01',
      });
      await open(t, repo, existing: (await repo.all('Goals')).single);
      await press(t, find.widgetWithText(TextButton, 'Alterar prazo'));
      await t.enterText(field('Prazo opcional em dias'), '1.5');
      await press(t, find.widgetWithText(FilledButton, 'Guardar'));
      expect(find.byType(Editor), findsOneWidget);
      expect((await repo.all('Goals')).single['due'], '2027-01-01');
      await t.enterText(field('Prazo opcional em dias'), '2');
      await press(t, find.widgetWithText(TextButton, 'Editor completo'));
      expect(find.text('Prazo: 14/11/2026 00:00'), findsOneWidget);
      await press(t, find.widgetWithText(FilledButton, 'Guardar'));
      expect((await repo.all('Goals')).single['due'], '2026-11-14');
      showEditor(
        t.element(find.byType(TudoAkiShell)),
        'Meta',
        existing: (await repo.all('Goals')).single,
        compact: true,
      );
      await t.pumpAndSettle();
      await press(t, find.widgetWithText(TextButton, 'Retirar prazo'));
      await press(t, find.widgetWithText(FilledButton, 'Guardar'));
      expect((await repo.all('Goals')).single['due'], isNull);
      expect((await repo.all('Goals')).single['id'], id);
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'real goal detail records numeric progress and reopens without XP or losing history',
    (t) async {
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = TodayRepository(db, () => DateTime(2026, 11, 12));
      final id = await repo.save('Goals', {
        'title': 'Leitura',
        'initial': 2,
        'current': 3,
        'target': 12,
        'unit': 'livros',
        'created': '2026-01-01',
      });
      await bootToday(t, repo);
      GoRouter.of(t.element(find.byType(TudoAkiShell))).push('/goal/$id');
      await t.pumpAndSettle();
      for (final number in ['12', '4']) {
        await press(t, find.widgetWithText(TextButton, 'Registar progresso'));
        await t.enterText(find.byType(TextField), number);
        await press(t, find.widgetWithText(FilledButton, 'Guardar'));
        final row = (await repo.all('Goals')).single;
        expect(row['current'], double.parse(number));
        expect(row['status'], number == '12' ? 'completed' : 'active');
      }
      expect(await repo.all('GoalProgress'), hasLength(2));
      expect(await repo.all('ExperienceEvents'), isEmpty);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
    },
  );
}
