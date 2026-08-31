import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/shared_widgets.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final List<String> _tasks = [];
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final text = _controller.text.trim();
    setState(() {
      if (text.isEmpty) {
        _error = "Task title can't be empty.";
      } else if (text.length < 3) {
        _error = 'Title must be at least 3 characters.';
      } else if (_tasks.contains(text)) {
        _error = 'This task already exists.';
      } else {
        _tasks.insert(0, text);
        _controller.clear();
        _error = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: 'Task List', subtitle: _tasks.isEmpty ? 'No tasks yet' : '${_tasks.length} tasks', showBack: true),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: 'Add a new task',
                    controller: _controller,
                    hint: 'e.g. Confirm supplier invoice',
                    icon: Icons.edit_outlined,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.error_outline, size: 14, color: AppTheme.errorRed),
                      const SizedBox(width: 4),
                      Text(_error!, style: const TextStyle(color: AppTheme.errorRed, fontSize: 12)),
                    ]),
                  ],
                  const SizedBox(height: 12),
                  AppButton(label: 'Add Task', onPressed: _add, icon: Icons.add),
                ],
              ),
            ),
          ),
          Expanded(
            child: _tasks.isEmpty
                ? const Center(child: Text('No tasks yet — add one above.', style: TextStyle(color: AppTheme.slate)))
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => FadeSlideIn(
                index: i,
                child: AppCard(
                  child: Row(
                    children: [
                      Expanded(child: Text(_tasks[i], style: const TextStyle(fontSize: 13, color: AppTheme.ink))),
                      IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed), onPressed: () => setState(() => _tasks.removeAt(i))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
