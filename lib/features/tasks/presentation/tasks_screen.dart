import 'package:flutter/material.dart';
import '../../../core/widgets/skeleton_page.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});
  @override
  Widget build(BuildContext context) => const SkeletonPage(
    title: 'Tarefas',
    description: 'Ainda não tens tarefas.',
    children: [],
  );
}
