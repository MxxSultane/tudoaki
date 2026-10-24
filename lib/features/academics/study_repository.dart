import 'package:drift/drift.dart';
import '../../core/database/database.dart';
import 'academic_rules.dart';

extension StudyRepository on TudoAkiRepository {
  Future<DataRowMap> studyById(int id) async {
    final rows = await query('SELECT * FROM StudySessions WHERE id = ?', [
      Variable.withInt(id),
    ]);
    if (rows.isEmpty) throw const FormatException('Esta sessão já não existe.');
    return rows.single;
  }

  Future<int> saveStudy({
    int? id,
    required String title,
    required DateTime start,
    required int minutes,
    int? subjectId,
  }) => db.transaction(() async {
    if (title.trim().isEmpty || minutes < 1 || minutes > 180) {
      throw const FormatException(
        'Defina um título e uma duração entre 1 e 180 minutos.',
      );
    }
    if (id != null) {
      final old = await studyById(id);
      if (old['completed'] == 1 || old['focus_started_at'] != null) {
        throw const FormatException(
          'Uma sessão iniciada preserva o seu registo. Planeie outra sessão para ajustar a duração.',
        );
      }
    }
    return save('StudySessions', {
      'title': title.trim(),
      'start': start.toIso8601String(),
      'minutes': minutes,
      'remaining_seconds': minutes * 60,
      'subject_id': subjectId,
    }, id: id);
  });

  Future<void> startStudy(int id, {DateTime? now}) => db.transaction(() async {
    final at = now ?? DateTime.now();
    final row = await studyById(id);
    if (row['completed'] == 1) {
      throw const FormatException('Esta sessão já foi concluída.');
    }
    if (row['focus_end'] != null) {
      return; // Repeated taps do not reset the deadline.
    }
    final active = await query(
      'SELECT id FROM StudySessions WHERE focus_end IS NOT NULL AND completed = 0',
    );
    if (active.isNotEmpty) {
      throw const FormatException(
        'Pause ou conclua a sessão actual antes de iniciar outra.',
      );
    }
    final seconds = row['remaining_seconds'] as int;
    if (seconds <= 0) {
      throw const FormatException('O tempo desta sessão já terminou.');
    }
    await save('StudySessions', {
      'focus_end': at.toUtc().add(Duration(seconds: seconds)).toIso8601String(),
      'focus_started_at':
          row['focus_started_at'] ?? at.toUtc().toIso8601String(),
    }, id: id);
  });

  Future<void> pauseStudy(int id, {DateTime? now}) => db.transaction(() async {
    final row = await studyById(id);
    if (row['completed'] == 1 || row['focus_end'] == null) return;
    final seconds = focusSecondsRemaining(row, now ?? DateTime.now());
    if (seconds == 0) {
      return; // Preserve the finished deadline for confirmation.
    }
    await save('StudySessions', {
      'focus_end': null,
      'remaining_seconds': seconds,
    }, id: id);
  });

  Future<void> completeStudy(int id, {DateTime? now}) =>
      db.transaction(() async {
        final at = now ?? DateTime.now();
        final row = await studyById(id);
        if (row['completed'] == 1) return;
        if (row['focus_end'] == null || focusSecondsRemaining(row, at) > 0) {
          throw const FormatException(
            'Registe a sessão quando o tempo de foco terminar.',
          );
        }
        await save('StudySessions', {
          'completed': 1,
          'remaining_seconds': 0,
          'focus_end': null,
          'completed_at': at.toUtc().toIso8601String(),
        }, id: id);
        final day = dayKey(at.toLocal());
        final count = await query(
          'SELECT COUNT(*) AS n FROM ExperienceEvents WHERE source LIKE ?',
          [Variable.withString('study:$day:%')],
        );
        if ((count.single['n'] as int) < dailyRewardedStudySessions) {
          await award(
            'study:$day:$id',
            studyExperiencePoints,
            at.toIso8601String(),
          );
        }
      });
}
