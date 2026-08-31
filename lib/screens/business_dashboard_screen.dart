import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});
  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final titles = ['Good morning, Esha', 'Tasks', 'Profile'];
    final subtitles = ["Here's how your business is doing", 'Manage your to-dos', 'Manage your account'];
    final screens = [const _DashTab(), const _TasksTab(), const _ProfileTab()];

    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: titles[_tabIndex], subtitle: subtitles[_tabIndex], showBack: true),
          Expanded(child: screens[_tabIndex]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        backgroundColor: AppTheme.navyDeep,
        indicatorColor: Colors.transparent,
        destinations: [
          NavigationDestination(icon: Icon(Icons.dashboard, color: _tabIndex == 0 ? AppTheme.forgeAmber : const Color(0xFF7C8CAD)), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.checklist, color: _tabIndex == 1 ? AppTheme.forgeAmber : const Color(0xFF7C8CAD)), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.person, color: _tabIndex == 2 ? AppTheme.forgeAmber : const Color(0xFF7C8CAD)), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DashTab extends StatelessWidget {
  const _DashTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: _statCard('Revenue (MTD)', 'Rs 842K', '+12.4%')),
            const SizedBox(width: 10),
            Expanded(child: _statCard('Active Orders', '36', '+4')),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Recent activity', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.ink)),
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            children: [
              _activityRow('Invoice #2291 generated', '2m ago', AppTheme.steelAccent),
              const Divider(height: 20),
              _activityRow('New order — Al-Noor Traders', '18m ago', AppTheme.forgeAmber),
              const Divider(height: 20),
              _activityRow('Inventory sync completed', '1h ago', AppTheme.steelAccent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, String delta) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.slate)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.ink)),
        const SizedBox(height: 4),
        Text(delta, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.successGreen)),
      ],
    ),
  );

  Widget _activityRow(String name, String time, Color color) => Row(
    children: [
      Icon(Icons.check_circle, color: color, size: 16),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 13, color: AppTheme.ink)),
            Text(time, style: const TextStyle(fontSize: 11, color: AppTheme.slate)),
          ],
        ),
      ),
    ],
  );
}

class _TasksTab extends StatefulWidget {
  const _TasksTab();
  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab> {
  final List<Map<String, String>> _tasks = [
    {'title': 'Confirm supplier invoice', 'priority': 'High'},
    {'title': 'Review deployment logs', 'priority': 'Low'},
  ];

  @override
  Widget build(BuildContext context) {
    if (_tasks.isEmpty) {
      return const Center(child: Text('No tasks yet.', style: TextStyle(color: AppTheme.slate)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final t = _tasks[i];
        final color = t['priority'] == 'High' ? AppTheme.errorRed : (t['priority'] == 'Med' ? AppTheme.forgeAmber : AppTheme.steelAccent);
        return AppCard(
          child: Row(
            children: [
              AppBadge(label: t['priority']!, color: color),
              const SizedBox(width: 10),
              Expanded(child: Text(t['title']!, style: const TextStyle(fontSize: 13, color: AppTheme.ink))),
              IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed), onPressed: () => setState(() => _tasks.removeAt(i))),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: AppTheme.navyPrimary, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Text('EA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Esha Arooh', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.ink)),
                Text('Business Owner · Sahiwal SME Hub', style: TextStyle(fontSize: 12, color: AppTheme.slate)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Row(
            children: const [
              Icon(Icons.settings_outlined, color: AppTheme.steelAccent, size: 18),
              SizedBox(width: 12),
              Expanded(child: Text('Business settings', style: TextStyle(fontSize: 13, color: AppTheme.ink))),
              Icon(Icons.chevron_right, color: Color(0xFFC4CAD6)),
            ],
          ),
        ),
      ],
    );
  }
}
