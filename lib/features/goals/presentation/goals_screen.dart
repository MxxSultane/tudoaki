import 'package:flutter/material.dart';
import '../../../core/widgets/skeleton_page.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});
  @override
  Widget build(BuildContext context) => const SkeletonPage(
    title: 'Metas',
    description: 'Ainda não tens metas.',
    children: [],
  );
}
