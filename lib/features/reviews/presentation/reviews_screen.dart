import 'package:flutter/material.dart';
import '../../../core/widgets/legacy_section_page.dart';
import '../../forms.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({this.embedded = false, super.key});
  final bool embedded;
  @override
  Widget build(BuildContext context) => LegacySectionPage(
    title: 'Revisões',
    embedded: embedded,
    builder: (context, ref, data, act) => [
      legacyHeading(
        context,
        'Olhar para trás',
        action: TextButton(
          onPressed: () => showEditor(context, 'Revisão'),
          child: const Text('Nova'),
        ),
      ),
      if (data['PeriodicReviews']!.isEmpty)
        legacyEmpty(
          context,
          'Uma breve reflexão pode ajudar a escolher o próximo passo.',
          'Revisão',
        ),
      ...data['PeriodicReviews']!.reversed.map(
        (r) => Card(
          child: ExpansionTile(
            title: Text('${r['period']} · ${r['day']}'),
            childrenPadding: const EdgeInsets.all(16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Realizações\n${r['achieved']}'),
              const SizedBox(height: 12),
              Text('Pendentes\n${r['pending']}'),
              const SizedBox(height: 12),
              Text('Obstáculos\n${r['obstacles']}'),
              const SizedBox(height: 12),
              Text('Próximas prioridades\n${r['next']}'),
            ],
          ),
        ),
      ),
    ],
  );
}
