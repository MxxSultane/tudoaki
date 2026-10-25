import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database.dart';
import '../core/database/schema.dart';
import '../features/progress/progress_rules.dart';
import '../core/notifications/reminders.dart';

final repositoryProvider = Provider<TudoAkiRepository>((ref) {
  final db = TudoAkiDatabase.local();
  ref.onDispose(() {
    db.close();
  });
  return TudoAkiRepository(db);
});
final remindersProvider = Provider<Reminders>((_) => Reminders());
final dataProvider = FutureProvider<Map<String, List<DataRowMap>>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  await repo.syncAchievements();
  return {for (final table in exportTables) table: await repo.all(table)};
});
