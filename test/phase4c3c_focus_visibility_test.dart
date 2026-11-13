import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudo_aki/core/database/database.dart';
import 'package:tudo_aki/features/academics/study_repository.dart';
import 'phase4c3c_studies_test.dart' show boot;

void main() {
  testWidgets(
    'opening planned focus reveals its primary action without manual scrolling',
    (t) async {
      t.view.physicalSize = const Size(360, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final db = TudoAkiDatabase.memory();
      addTearDown(db.close);
      final repo = TudoAkiRepository(db);
      final subject = await repo.save('Subjects', {'title': 'Matemática'});
      await repo.save('Subjects', {'title': 'História'});
      await repo.saveStudy(
        title: 'Revisão',
        start: DateTime(2026, 11, 11, 16),
        minutes: 25,
        subjectId: subject,
      );
      await boot(t, repo, () => DateTime(2026, 11, 11, 10, 30));
      final open = find.byTooltip('Abrir foco');
      await t.ensureVisible(open);
      await t.pumpAndSettle();
      await t.tap(open);
      await t.pumpAndSettle();
      expect(
        find.widgetWithText(FilledButton, 'Iniciar foco').hitTestable(),
        findsOneWidget,
      );
      expect(
        (await repo.all('StudySessions')).single['focus_started_at'],
        isNull,
      );
      expect(await repo.all('ExperienceEvents'), isEmpty);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
    },
  );
}
