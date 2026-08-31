import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import 'browse_products_screen.dart';
import 'business_dashboard_screen.dart';
import 'cart_screen.dart';
import 'client_form_screen.dart';
import 'client_list_screen.dart';
import 'component_demo_screen.dart';
import 'image_picker_screen.dart';
import 'local_storage_screen.dart';
import 'notifications_screen.dart';
import 'product_list_screen.dart';
import 'task_list_screen.dart';
import 'team_tasks_screen.dart';
import 'theme_settings_screen.dart';
import 'weather_screen.dart';

class HomeMenuScreen extends StatelessWidget {
  const HomeMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final items = [
      MenuItem('Clients', 'REST API • CRUD operations', Icons.people_outline, (ctx) => const ClientListScreen(), AppTheme.steelAccent),
      MenuItem('New Client', 'Validated client registration', Icons.person_add_alt_1_outlined, (ctx) => const ClientFormScreen(), AppTheme.successGreen),
      MenuItem('Business Dashboard', 'Tasks, profile & overview', Icons.dashboard_outlined, (ctx) => const BusinessDashboardScreen(), AppTheme.forgeAmber),
      MenuItem('Task List', 'Create and manage tasks', Icons.checklist_outlined, (ctx) => const TaskListScreen(), AppTheme.successGreen),
      MenuItem('Team Tasks', 'REST API task management', Icons.groups_outlined, (ctx) => const TeamTasksScreen(), AppTheme.steelAccent),
      MenuItem('Products', 'Efficient product browsing', Icons.list_alt_outlined, (ctx) => const ProductListScreen(), AppTheme.forgeAmber),
      MenuItem('Browse & Cart', 'Products with shared cart state', Icons.shopping_cart_outlined, (ctx) => const BrowseProductsScreen(), AppTheme.steelAccent),
      MenuItem('Cart', 'View your current cart', Icons.shopping_bag_outlined, (ctx) => const CartScreen(), AppTheme.successGreen),
      MenuItem('Weather', 'API, navigation & favorites', Icons.wb_sunny_outlined, (ctx) => const WeatherCitiesScreen(), AppTheme.forgeAmber),
      MenuItem('Business Notes', 'Notes saved locally', Icons.sticky_note_2_outlined, (ctx) => const LocalStorageScreen(), AppTheme.successGreen),
      MenuItem('Notifications', 'Immediate & scheduled reminders', Icons.notifications_outlined, (ctx) => const NotificationsScreen(), AppTheme.steelAccent),
      MenuItem('Business Photo', 'Camera & gallery integration', Icons.camera_alt_outlined, (ctx) => const ImagePickerScreen(), AppTheme.forgeAmber),
      MenuItem('Component Library', 'Reusable UI components', Icons.widgets_outlined, (ctx) => const ComponentDemoScreen(), AppTheme.successGreen),
      MenuItem('App Theme', 'Light & dark mode', Icons.dark_mode_outlined, (ctx) => const ThemeSettingsScreen(), AppTheme.steelAccent),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                decoration: const BoxDecoration(
                  color: AppTheme.navyDeep,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(color: AppTheme.forgeAmber, borderRadius: BorderRadius.circular(14)),
                          alignment: Alignment.center,
                          child: const Text('TF', style: TextStyle(color: AppTheme.navyDeep, fontSize: 17, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TECNIFORGE', style: TextStyle(color: AppTheme.forgeAmber, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2)),
                              SizedBox(height: 3),
                              Text('Business Autopilot', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
                          child: IconButton(
                            tooltip: 'Theme',
                            onPressed: () => Navigator.push(context, animatedRoute(const ThemeSettingsScreen())),
                            icon: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_outlined, color: AppTheme.forgeAmber, size: 21),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Text('Welcome back 👋', style: TextStyle(color: Color(0xFF9FB0CC), fontSize: 13)),
                    const SizedBox(height: 6),
                    const Text('Everything you need,\nin one place.', style: TextStyle(color: Colors.white, fontSize: 27, height: 1.15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    const Text(
                      'A unified workspace for managing clients, tasks, products, notes and business tools.',
                      style: TextStyle(color: Color(0xFFB8C5D9), fontSize: 12, height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: Row(
                  children: [
                    Expanded(child: HomeStatCard(icon: Icons.apps_outlined, value: '14', label: 'Features', color: AppTheme.steelAccent)),
                    const SizedBox(width: 10),
                    Expanded(child: HomeStatCard(icon: Icons.phone_android_outlined, value: '1', label: 'Unified App', color: AppTheme.forgeAmber)),
                    const SizedBox(width: 10),
                    Expanded(child: HomeStatCard(icon: Icons.verified_outlined, value: 'Ready', label: 'Status', color: AppTheme.successGreen)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  children: [
                    Expanded(child: Text('Explore features', style: TextStyle(color: colors.onSurface, fontSize: 18, fontWeight: FontWeight.w700))),
                    Text('${items.length} available', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    return FadeSlideIn(
                      index: index,
                      child: HomeFeatureCard(
                        item: item,
                        onTap: () => Navigator.push(context, animatedRoute(item.builder(context))),
                      ),
                    );
                  },
                  childCount: items.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.12,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.outlineVariant)),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(color: AppTheme.successGreen.withOpacity(0.12), shape: BoxShape.circle),
                        child: const Icon(Icons.check_circle_outline, color: AppTheme.successGreen, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mini app ready', style: TextStyle(color: colors.onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('Weekly features integrated into one polished Flutter application.', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11, height: 1.35)),
                          ],
                        ),
                      ),
                      const Icon(Icons.verified_rounded, color: AppTheme.successGreen, size: 21),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const HomeStatCard({super.key, required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(15), border: Border.all(color: colors.outlineVariant)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 9),
          Text(value, style: TextStyle(color: colors.onSurface, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10)),
        ],
      ),
    );
  }
}

class HomeFeatureCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;

  const HomeFeatureCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.outlineVariant)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: item.color.withOpacity(0.11), borderRadius: BorderRadius.circular(11)),
                    child: Icon(item.icon, color: item.color, size: 20),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, color: colors.onSurfaceVariant, size: 11),
                ],
              ),
              const Spacer(),
              Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10, height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget Function(BuildContext) builder;
  final Color color;

  const MenuItem(this.title, this.subtitle, this.icon, this.builder, this.color);
}
