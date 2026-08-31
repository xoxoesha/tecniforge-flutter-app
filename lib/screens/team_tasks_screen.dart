import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/shared_widgets.dart';

// A different REST pattern from Clients (which creates/edits full records)
// and Weather (which is read-only): here, tapping a checkbox sends a PATCH
// request to update just one field (`completed`) on the server, with the
// checkbox optimistically flipping immediately and reverting if the request
// fails — a common real-world update pattern.
class TeamTasksScreen extends StatefulWidget {
  const TeamTasksScreen({super.key});
  @override
  State<TeamTasksScreen> createState() => _TeamTasksScreenState();
}

class _TeamTasksScreenState extends State<TeamTasksScreen> {
  LoadState state = LoadState.loading;
  List<TeamTask> tasks = [];
  String errorMessage = '';
  final Set<int> _updatingIds = {}; // tracks which rows show a small spinner while their PATCH is in flight

  static const _url = 'https://jsonplaceholder.typicode.com/todos';

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ---- FETCH (GET) ----
  Future<void> _load() async {
    setState(() => state = LoadState.loading);
    try {
      final res = await http.get(Uri.parse('$_url?_limit=10'));
      if (res.statusCode != 200) throw Exception('Server responded with ${res.statusCode}');
      final List data = jsonDecode(res.body);
      // The fake API never actually persists our PATCH updates — refetching
      // just returns its original static dataset. So we keep our own local
      // record of which ids the user has toggled, and apply it on top of
      // whatever the server returns, so taps don't get silently reset.
      final prefs = await SharedPreferences.getInstance();
      final overrides = prefs.getStringList('team_task_overrides') ?? [];
      final overrideMap = {for (var o in overrides) int.parse(o.split(':')[0]): o.split(':')[1] == '1'};

      setState(() {
        tasks = List.generate(data.length, (i) {
          final json = data[i];
          final id = json['id'] as int;
          return TeamTask(
            id: id,
            title: i < realisticTaskTitles.length ? realisticTaskTitles[i] : 'Task #$id',
            completed: overrideMap[id] ?? (json['completed'] ?? false),
          );
        });
        state = LoadState.success;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        state = LoadState.error;
      });
    }
  }

  // ---- UPDATE (PATCH) ----
  Future<void> _toggle(TeamTask task) async {
    final previous = task.completed;
    setState(() {
      task.completed = !task.completed; // optimistic UI update
      _updatingIds.add(task.id);
    });

    // Save locally right away — this is what actually makes the toggle
    // "stick" when you leave and come back, since the fake API won't.
    final prefs = await SharedPreferences.getInstance();
    final overrides = prefs.getStringList('team_task_overrides') ?? [];
    overrides.removeWhere((o) => o.startsWith('${task.id}:'));
    overrides.add('${task.id}:${task.completed ? '1' : '0'}');
    await prefs.setStringList('team_task_overrides', overrides);

    try {
      final res = await http.patch(
        Uri.parse('${_url}/${task.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'completed': task.completed}),
      );
      if (res.statusCode != 200) throw Exception('Update failed (${res.statusCode})');
    } catch (e) {
      // Revert on failure and tell the user — don't leave the UI showing a
      // state the server never actually confirmed.
      setState(() => task.completed = previous);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingIds.remove(task.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: 'Team Tasks', subtitle: state == LoadState.success ? '${tasks.where((t) => t.completed).length}/${tasks.length} completed' : 'Connected to REST API', showBack: true),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(key: ValueKey(state), child: _body()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    switch (state) {
      case LoadState.loading:
        return const Center(child: CircularProgressIndicator(color: AppTheme.navyPrimary));
      case LoadState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off, color: AppTheme.errorRed, size: 48),
              const SizedBox(height: 12),
              const Text("Couldn't load tasks", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.ink)),
              const SizedBox(height: 4),
              Text(errorMessage, style: const TextStyle(fontSize: 12, color: AppTheme.slate), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              SizedBox(width: 140, child: AppButton(label: 'Retry', onPressed: _load, icon: Icons.refresh)),
            ]),
          ),
        );
      case LoadState.success:
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (ctx, i) {
            final task = tasks[i];
            final isUpdating = _updatingIds.contains(task.id);
            return FadeSlideIn(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  child: Row(
                    children: [
                      isUpdating
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.navyPrimary))
                          : Checkbox(
                        value: task.completed,
                        activeColor: AppTheme.navyPrimary,
                        onChanged: (_) => _toggle(task),
                      ),
                      const SizedBox(width: 6),
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
                    ],
                  ),
                ),
              ),
            );
          },
        );
    }
  }
}
