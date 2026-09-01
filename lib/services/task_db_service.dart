import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/shared_widgets.dart';
import '../models/models.dart';
import '../services/task_db_service.dart';

enum _TaskFilter { all, active, completed }

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _loading = true;
  bool _submitting = false;
  List<LocalTask> _tasks = [];
  _TaskFilter _filter = _TaskFilter.all;
  int _totalCount = 0;
  int _activeCount = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Re-queries SQLite for the current filter plus the counts shown in the
  // subtitle and filter chips — every call here hits the on-device database,
  // not an in-memory list.
  Future<void> _refresh() async {
    setState(() => _loading = true);
    final completedFilter = switch (_filter) {
      _TaskFilter.all => null,
      _TaskFilter.active => false,
      _TaskFilter.completed => true,
    };
    final results = await Future.wait([
      TaskDbService.instance.getTasks(completed: completedFilter),
      TaskDbService.instance.countTasks(),
      TaskDbService.instance.countTasks(completed: false),
    ]);
    if (!mounted) return;
    setState(() {
      _tasks = results[0] as List<LocalTask>;
      _totalCount = results[1] as int;
      _activeCount = results[2] as int;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = "Task title can't be empty.");
      return;
    }
    if (text.length < 3) {
      setState(() => _error = 'Title must be at least 3 characters.');
      return;
    }
    if (_tasks.any((t) => t.title == text)) {
      setState(() => _error = 'This task already exists.');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true; // guards against double-tap while the insert runs
    });
    await TaskDbService.instance.insertTask(text);
    _controller.clear();
    setState(() => _submitting = false);
    await _refresh();
  }

  Future<void> _toggle(LocalTask task) async {
    await TaskDbService.instance.setCompleted(task.id!, !task.completed);
    await _refresh();
  }

  Future<void> _delete(LocalTask task) async {
    await TaskDbService.instance.deleteTask(task.id!);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(
            title: 'Task List',
            subtitle: _totalCount == 0 ? 'No tasks yet' : '$_activeCount active · $_totalCount total',
            showBack: true,
          ),
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
                  AppButton(
                    label: _submitting ? 'Adding…' : 'Add Task',
                    onPressed: _submitting ? () {} : _add,
                    icon: Icons.add,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(label: 'All', selected: _filter == _TaskFilter.all, onTap: () => _setFilter(_TaskFilter.all)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Active', selected: _filter == _TaskFilter.active, onTap: () => _setFilter(_TaskFilter.active)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Completed', selected: _filter == _TaskFilter.completed, onTap: () => _setFilter(_TaskFilter.completed)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.navyPrimary))
                : _tasks.isEmpty
                    ? Center(
                        child: Text(
                          _filter == _TaskFilter.all ? 'No tasks yet — add one above.' : 'Nothing here for this filter.',
                          style: const TextStyle(color: AppTheme.slate),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _tasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final task = _tasks[i];
                          return FadeSlideIn(
                            index: i,
                            child: AppCard(
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: task.completed,
                                    activeColor: AppTheme.navyPrimary,
                                    onChanged: (_) => _toggle(task),
                                  ),
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: task.completed ? AppTheme.slate : AppTheme.ink,
                                        decoration: task.completed ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed),
                                    onPressed: () => _delete(task),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _setFilter(_TaskFilter f) {
    if (f == _filter) return;
    setState(() => _filter = f);
    _refresh();
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.navyPrimary : AppTheme.surface,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: selected ? AppTheme.navyPrimary : AppTheme.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppTheme.ink),
        ),
      ),
    );
  }
}
