import 'package:flutter/material.dart';
import '../../../app/providers.dart';
import '../../../core/widgets/legacy_section_page.dart';

import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/brand.dart';
import '../../finance/finance_rules.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({this.embedded = false, super.key});
  final bool embedded;
  @override
  Widget build(BuildContext context) => LegacySectionPage(
    title: 'Perfil',
    embedded: embedded,
    builder: (context, ref, data, act) {
      final prefs = data['UserPreferences']!.first;
      final repo = ref.read(repositoryProvider);
      return [
        if (!embedded) ...[
          legacyHeading(context, 'Organize as suas áreas'),
          for (final item in {
            '/habits': ('Hábitos e bem-estar', Icons.spa_outlined),
            '/academics': ('Estudos', Icons.school_outlined),
            '/finance': ('Finanças', Icons.account_balance_wallet_outlined),
            '/reviews': ('Revisões', Icons.rate_review_outlined),
          }.entries)
            Card(
              child: ListTile(
                leading: Icon(item.value.$2),
                title: Text(item.value.$1),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(item.key),
              ),
            ),
        ],
        legacyHeading(context, 'Preferências'),
        DropdownButtonFormField<String>(
          key: ValueKey('theme-${prefs['theme']}'),
          initialValue: prefs['theme'] as String,
          decoration: const InputDecoration(labelText: 'Aparência'),
          items: const [
            DropdownMenuItem(value: 'system', child: Text('Seguir sistema')),
            DropdownMenuItem(value: 'light', child: Text('Claro')),
            DropdownMenuItem(value: 'dark', child: Text('Escuro')),
          ],
          onChanged: (value) => act(() async {
            await repo.save('UserPreferences', {'theme': value}, id: 1);
          }),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: ValueKey('default-currency-${prefs['currency']}'),
          initialValue: prefs['currency'] as String,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Moeda para novos registos',
          ),
          items: [
            for (final entry in currencyLabels.entries)
              DropdownMenuItem(
                value: entry.key,
                child: Text(
                  entry.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) => act(() async {
            if (value != null) {
              await repo.save('UserPreferences', {'currency': value}, id: 1);
            }
          }),
        ),
        const Text(
          'Aplica-se a novos registos. Os valores existentes mantêm a moeda original. Sem conversão cambial.',
        ),
        SwitchListTile(
          title: const Text('Gamificação'),
          subtitle: const Text('XP opcional, sem penalizações.'),
          value: prefs['gamification'] == 1,
          onChanged: (value) => act(() async {
            await repo.save('UserPreferences', {
              'gamification': value ? 1 : 0,
            }, id: 1);
          }),
        ),
        legacyHeading(context, 'Os seus dados'),
        const Text(
          'Guardados localmente neste dispositivo. A aplicação não implementa encriptação. Sem conta nem analytics externos.',
        ),
        ListTile(
          leading: const Icon(Icons.ios_share),
          title: const Text('Exportar dados JSON'),
          onTap: () => act(() async {
            final json = await repo.exportJson();
            await SharePlus.instance.share(
              ShareParams(
                text: json,
                subject: '${TudoAkiBrand.name} — exportação de dados',
              ),
            );
          }),
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Apagar todos os dados'),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Apagar todos os dados?'),
                content: const Text(
                  'Esta acção não pode ser desfeita. Exporte primeiro se quiser guardar uma cópia.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Apagar'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await act(() async {
                await ref.read(remindersProvider).cancelAll();
                await repo.erase();
              });
            }
          },
        ),
      ];
    },
  );
}
