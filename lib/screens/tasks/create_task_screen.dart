import 'package:flutter/material.dart';
import 'task_form_screen.dart';

/// Backward-compatible wrapper around [TaskFormScreen].
class CreateTaskScreen extends StatelessWidget {
  final int? initialProjectId;

  const CreateTaskScreen({super.key, this.initialProjectId});

  @override
  Widget build(BuildContext context) {
    return TaskFormScreen(initialProjectId: initialProjectId);
  }
}
