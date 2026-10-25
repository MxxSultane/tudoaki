import 'package:flutter_test/flutter_test.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/core/database/schema.dart';
import 'package:tudo_aki/features/agenda/domain/agenda_cubit.dart';
import 'package:tudo_aki/features/agenda/domain/agenda_items.dart';

void main() {
  WorkspaceSnapshot empty() => {for (final table in exportTables) table: []};

  test(
    'calendar merges tasks, events and classes chronologically without copying records',
    () {
      final data = empty();
      data['Tasks'] = [
        {'id': 1, 'title': 'Ler', 'due': '2026-10-26T08:00:00', 'completed': 0},
      ];
      data['CalendarEvents'] = [
        {
          'id': 1,
          'title': 'Reunião',
          'start': '2026-10-26T10:00:00',
          'end': '2026-10-26T11:00:00',
          'recurrence': 'weekly',
        },
      ];
      data['Subjects'] = [
        {'id': 1, 'title': 'Matemática'},
      ];
      data['ClassSchedules'] = [
        {
          'id': 1,
          'subject_id': 1,
          'weekday': 1,
          'start_minute': 9 * 60,
          'end_minute': 10 * 60,
          'active_from': '2026-10-01',
          'active_until': '2026-12-31',
        },
      ];
      final items = agendaItemsForDay(data, DateTime(2026, 10, 26));
      expect(items.map((i) => i.row['title']), [
        'Ler',
        'Aula · Matemática',
        'Reunião',
      ]);
      expect(items.where((i) => agendaConflict(i, items)), isEmpty);
      final followingWeek = agendaItemsForDay(data, DateTime(2026, 11, 2));
      expect(followingWeek, hasLength(2));
      expect(followingWeek.every((i) => !i.task), isTrue);
      expect(data['CalendarEvents'], hasLength(1));
      expect(data['Tasks'], hasLength(1));
    },
  );

  test(
    'task instants collide inside blocks, excluding completed tasks and adjacent boundaries',
    () {
      final data = empty();
      data['CalendarEvents'] = [
        {
          'id': 1,
          'title': 'Primeiro',
          'start': '2026-10-25T09:00:00',
          'end': '2026-10-25T10:00:00',
          'recurrence': 'none',
        },
        {
          'id': 2,
          'title': 'Segundo',
          'start': '2026-10-25T10:00:00',
          'end': '2026-10-25T11:00:00',
          'recurrence': 'none',
        },
      ];
      data['Tasks'] = [
        {
          'id': 1,
          'title': 'Concluída',
          'due': '2026-10-25T09:30:00',
          'completed': 1,
        },
        {
          'id': 2,
          'title': 'Pendente',
          'due': '2026-10-25T10:00:00',
          'completed': 0,
        },
      ];
      final items = agendaItemsForDay(data, DateTime(2026, 10, 25));
      expect(
        agendaConflict(
          items.firstWhere((i) => i.row['title'] == 'Primeiro'),
          items,
        ),
        isFalse,
      );
      expect(
        agendaConflict(
          items.firstWhere((i) => i.row['title'] == 'Concluída'),
          items,
        ),
        isFalse,
      );
      expect(
        agendaConflict(
          items.firstWhere((i) => i.row['title'] == 'Segundo'),
          items,
        ),
        isTrue,
      );
      expect(
        agendaConflict(
          items.firstWhere((i) => i.row['title'] == 'Pendente'),
          items,
        ),
        isTrue,
      );
    },
  );

  test(
    'calendar navigation stays inside picker bounds with civil weeks and months',
    () async {
      final cubit = AgendaCubit(DateTime(2026, 1, 31));
      addTearDown(cubit.close);
      cubit.mode('Mês');
      cubit.move(1);
      expect(cubit.state.day, DateTime(2026, 2, 1));
      cubit.mode('Semana');
      cubit.move(1);
      expect(cubit.state.day, DateTime(2026, 2, 8));
      cubit.select(DateTime(2100, 12, 31));
      cubit.move(1);
      expect(cubit.state.day, DateTime(2100, 12, 31));
      cubit.select(DateTime(1999));
      expect(cubit.state.day, DateTime(2000));
    },
  );
}
