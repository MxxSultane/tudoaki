import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/skeleton_page.dart';

class AreasScreen extends StatelessWidget {
  const AreasScreen({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
    children: [
      InsetGroup(
        children: [
          for (final area in const [
            ('/weekly-planner', 'Planear semana', 'Eventos e tarefas por dia'),
            ('/habits', 'Hábitos', 'Rotinas e bem-estar'),
            ('/academics', 'Estudos', 'Disciplinas, prazos e foco'),
            ('/finance', 'Finanças', 'Movimentos e poupanças'),
            ('/progress', 'Progresso', 'Resultados e conquistas'),
            ('/reviews', 'Revisões', 'Reflectir e ajustar'),
            ('/profile', 'Definições', 'Aparência, moeda e dados'),
          ])
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(area.$2),
              subtitle: Text(
                area.$3,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onTap: () => context.push(area.$1),
            ),
        ],
      ),
      const SizedBox(height: 24),
      Text(
        'A tua vida, organizada num só lugar.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class AreaScaffold extends StatelessWidget {
  const AreaScaffold({required this.title, required this.child, super.key});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      leading: IconButton(
        tooltip: 'Voltar',
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: child,
        ),
      ),
    ),
  );
}
