import 'package:flutter/material.dart';

class SkeletonPage extends StatelessWidget {
  const SkeletonPage({
    required this.title,
    required this.description,
    required this.children,
    super.key,
  });
  final String title, description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 32, 20, 112),
    children: [
      Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.headlineLarge),
      ),
      const SizedBox(height: 8),
      Text(description, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 32),
      ...children,
    ],
  );
}

class InsetGroup extends StatelessWidget {
  const InsetGroup({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: children[i],
            ),
          ],
        ],
      ),
    ),
  );
}
