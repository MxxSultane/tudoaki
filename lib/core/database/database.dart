import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'schema.dart';

class TudoAkiDatabase extends GeneratedDatabase {
  TudoAkiDatabase(super.executor);
  factory TudoAkiDatabase.memory() => TudoAkiDatabase(NativeDatabase.memory());
  factory TudoAkiDatabase.local() => TudoAkiDatabase(
    LazyDatabase(() async {
      final directory = await getApplicationSupportDirectory();
      await directory.create(recursive: true);
      return NativeDatabase.createInBackground(
        // Keep the existing storage filename so branding updates preserve user data.
        File(path.join(directory.path, 'lifeos.sqlite')),
      );
    }),
  );
  @override
  int get schemaVersion => 2;
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) => _applySchema([...schemaV1, ...schemaV2]),
    onUpgrade: (_, from, to) async {
      if (from == 1 && to == 2) {
        await _applySchema(schemaV2);
        return;
      }
      throw StateError(
        'Migração não suportada: $from → $to. Preserve a base de dados.',
      );
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _applySchema(List<String> statements) => transaction(() async {
    for (final sql in statements) {
      await customStatement(sql);
    }
    // Commit schema changes and their version together, including after a crash.
    await customStatement('PRAGMA user_version = $schemaVersion');
  });
}

typedef DataRowMap = Map<String, dynamic>;
String dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
double goalProgress(num initial, num target, num current) => target <= initial
    ? 0
    : ((current - initial) / (target - initial)).clamp(0, 1).toDouble();

// No double parsing: 0,10 MT is always exactly 10 centavos.
int moneyCents(String input) {
  final match = RegExp(r'^(\d+)(?:[,.](\d{1,2}))?$').firstMatch(input.trim());
  if (match == null) {
    throw const FormatException('Use um valor como 1250,50');
  }
  final cents =
      int.parse(match[1]!) * 100 + int.parse((match[2] ?? '').padRight(2, '0'));
  if (cents <= 0 || cents > 9007199254740991) {
    throw const FormatException('Valor fora do intervalo permitido');
  }
  return cents;
}

class TudoAkiRepository {
  TudoAkiRepository(this.db);
  final TudoAkiDatabase db;
  Future<List<DataRowMap>> query(
    String sql, [
    List<Variable> args = const [],
  ]) async => (await db.customSelect(sql, variables: args).get())
      .map((row) => row.data)
      .toList();
  Future<List<DataRowMap>> all(String table) {
    if (!exportTables.contains(table)) {
      throw ArgumentError('Tabela inválida');
    }
    return query('SELECT * FROM $table');
  }

  Future<void> write(String sql, [List<Object?> args = const []]) =>
      db.customStatement(sql, args);
  Future<int> save(
    String table,
    DataRowMap data, {
    int? id,
  }) => db.transaction(() async {
    if (!exportTables.contains(table) || data.isEmpty) {
      throw ArgumentError('Dados inválidos');
    }
    if (data.keys.any((key) => !RegExp(r'^[a-z_]+$').hasMatch(key))) {
      throw ArgumentError('Campo inválido');
    }
    final fields = data.keys.toList();
    if (id == null) {
      await write(
        'INSERT INTO $table (${fields.join(',')}) VALUES (${List.filled(fields.length, '?').join(',')})',
        data.values.toList(),
      );
      return (await query('SELECT last_insert_rowid() AS id')).first['id']
          as int;
    }
    await write(
      'UPDATE $table SET ${fields.map((f) => '$f = ?').join(',')} WHERE id = ?',
      [...data.values, id],
    );
    return id;
  });
  Future<void> delete(String table, int id) async {
    if (!exportTables.contains(table)) {
      throw ArgumentError('Tabela inválida');
    }
    await write('DELETE FROM $table WHERE id = ?', [id]);
  }

  Future<void> taskDone(int id, bool done, {DateTime? at}) =>
      db.transaction(() async {
        final rows = await query('SELECT id FROM Tasks WHERE id = ?', [
          Variable.withInt(id),
        ]);
        if (rows.isEmpty) {
          throw StateError('Tarefa inexistente');
        }
        final now = (at ?? DateTime.now()).toIso8601String();
        await write(
          'UPDATE Tasks SET completed = ?, completed_at = ? WHERE id = ?',
          [done ? 1 : 0, done ? now : null, id],
        );
        if (done) {
          await award('task:$id', 10, now);
        }
      });
  Future<void> award(String source, int points, String now) async {
    final enabled = (await all('UserPreferences')).first['gamification'] == 1;
    if (enabled) {
      await write(
        'INSERT OR IGNORE INTO ExperienceEvents(source, points, created) VALUES(?,?,?)',
        [source, points, now],
      );
    }
  }

  Future<void> toggleHabit(int id, DateTime date) => db.transaction(() async {
    final day = dayKey(date);
    final found = await query(
      'SELECT id FROM HabitCompletions WHERE habit_id = ? AND day = ?',
      [Variable.withInt(id), Variable.withString(day)],
    );
    if (found.isEmpty) {
      await write('INSERT INTO HabitCompletions(habit_id,day) VALUES(?,?)', [
        id,
        day,
      ]);
      await award('habit:$id:$day', 5, date.toIso8601String());
    } else {
      await write(
        'DELETE FROM HabitCompletions WHERE habit_id = ? AND day = ?',
        [id, day],
      );
    }
  });
  Future<void> updateMetric(int id, double value) => db.transaction(() async {
    if (!value.isFinite) {
      throw ArgumentError('Valor inválido');
    }
    await write(
      'UPDATE Goals SET current = ?, status = CASE WHEN ? >= target THEN \'completed\' ELSE \'active\' END WHERE id = ?',
      [value, value, id],
    );
    await save('GoalProgress', {
      'goal_id': id,
      'value': value,
      'recorded_at': DateTime.now().toIso8601String(),
    });
  });
  Future<String> exportJson() async {
    final data = <String, dynamic>{
      'schemaVersion': db.schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
    };
    for (final table in exportTables) {
      data[table] = await all(table);
    }
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> erase() => db.transaction(() async {
    for (final table in exportTables.reversed) {
      await write('DELETE FROM $table');
    }
    await write('INSERT INTO UserPreferences(id) VALUES(1)');
    // Keep AUTOINCREMENT sequences: a newly created item must not reuse a pending notification ID.
  });
}

DateTime? occurrenceOn(DataRowMap event, DateTime date) {
  final start = DateTime.parse(event['start'] as String);
  final first = DateTime(start.year, start.month, start.day);
  final requested = DateTime(date.year, date.month, date.day);
  if (requested.isBefore(first)) {
    return null;
  }
  final repeat = event['recurrence'];
  if (repeat == 'none' && dayKey(start) != dayKey(date)) {
    return null;
  }
  if (repeat == 'weekly' && start.weekday != date.weekday) {
    return null;
  }
  return DateTime(date.year, date.month, date.day, start.hour, start.minute);
}
