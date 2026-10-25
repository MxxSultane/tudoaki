import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/database/schema.dart';
import 'package:tudo_aki/features/agenda/domain/agenda_items.dart';
import 'package:tudo_aki/features/weekly_planner/domain/weekly_planner_cubit.dart';

void main() {
  test(
    'date-only planning survives native reopen and export without adding a time',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'tudoaki-weekly-',
      );
      final file = File('${directory.path}/db.sqlite');
      var db = TudoAkiDatabase(NativeDatabase(file));
      await TudoAkiRepository(db).save('Tasks', {
        'title': 'Planear',
        'created': '2026-10-25T16:00:00',
        'due': '2026-10-26',
      });
      await db.close();
      db = TudoAkiDatabase(NativeDatabase(file));
      try {
        final repo = TudoAkiRepository(db);
        final task = (await repo.all('Tasks')).single;
        expect(task['due'], '2026-10-26');
        final snapshot = {
          for (final table in exportTables) table: await repo.all(table),
        };
        expect(
          agendaItemsForDay(snapshot, DateTime(2026, 10, 26)).single.allDay,
          isTrue,
        );
        final json = jsonDecode(await repo.exportJson());
        expect(json['Tasks'][0]['due'], '2026-10-26');
        expect(json['schemaVersion'], 5);
      } finally {
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'Sunday opens next Monday; other days open their current week',
    () async {
      final sunday = WeeklyPlannerCubit(DateTime(2026, 10, 25, 21));
      final wednesday = WeeklyPlannerCubit(DateTime(2026, 10, 28));
      addTearDown(sunday.close);
      addTearDown(wednesday.close);
      expect(sunday.state.monday, DateTime(2026, 10, 26));
      expect(sunday.state.end, DateTime(2026, 11, 1));
      expect(wednesday.state.monday, DateTime(2026, 10, 26));
      expect(sunday.state.day, DateTime(2026, 10, 26));
      sunday.selectDate(DateTime(2026, 10, 25));
      expect(sunday.state.monday, DateTime(2026, 10, 19));
      expect(sunday.state.dayIndex, 6);
    },
  );

  test(
    'civil navigation crosses years and keeps the selected weekday and type',
    () async {
      final cubit = WeeklyPlannerCubit(DateTime(2027, 1, 3));
      addTearDown(cubit.close);
      expect(cubit.state.monday, DateTime(2027, 1, 4));
      cubit.selectDay(2);
      cubit.kind(PlanKind.event);
      cubit.move(-1);
      expect(cubit.state.monday, DateTime(2026, 12, 28));
      expect(cubit.state.day, DateTime(2026, 12, 30));
      expect(cubit.state.kind, PlanKind.event);
      cubit.move(1);
      expect(cubit.state.day, DateTime(2027, 1, 6));
    },
  );

  test(
    'boundary weeks only select valid days without breaking the picker',
    () async {
      final cubit = WeeklyPlannerCubit(DateTime(2000));
      addTearDown(cubit.close);
      expect(cubit.state.day, DateTime(2000));
      expect(cubit.canPrevious, isFalse);
      cubit.move(-1);
      cubit.selectDay(0);
      expect(cubit.state.day, DateTime(2000));
      cubit.selectDate(DateTime(2100, 12, 31));
      expect(cubit.canNext, isFalse);
      cubit.move(1);
      expect(cubit.state.day, DateTime(2100, 12, 31));
      cubit.selectDay(6);
      expect(cubit.state.day, DateTime(2100, 12, 31));
      expect(() => cubit.selectDay(7), throwsArgumentError);
    },
  );

  test(
    'date-only tasks are not midnight appointments and never cause collisions',
    () {
      final data = {for (final table in exportTables) table: <DataRowMap>[]};
      data['Tasks'] = [
        {'id': 1, 'title': 'Sem hora A', 'due': '2026-10-26', 'completed': 0},
        {'id': 2, 'title': 'Sem hora B', 'due': '2026-10-26', 'completed': 0},
        {
          'id': 3,
          'title': 'À meia-noite',
          'due': '2026-10-26T00:00:00',
          'completed': 0,
        },
      ];
      data['CalendarEvents'] = [
        {
          'id': 1,
          'title': 'Evento',
          'start': '2026-10-26T00:00:00',
          'end': '2026-10-26T01:00:00',
          'recurrence': 'none',
        },
      ];
      final items = agendaItemsForDay(data, DateTime(2026, 10, 26));
      expect(items.where((i) => i.allDay), hasLength(2));
      expect(
        items.where((i) => i.allDay).every((i) => !agendaConflict(i, items)),
        isTrue,
      );
      expect(
        agendaConflict(
          items.singleWhere((i) => i.row['title'] == 'À meia-noite'),
          items,
        ),
        isTrue,
      );
      expect(isDateOnly('2026-10-26T00:00:00'), isFalse);
      expect(isDateOnly(null), isFalse);
    },
  );
}
