import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final isDark = controller.isDark;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          const AppTopBar(title: 'App Theme', subtitle: 'Choose your preferred appearance', showBack: true),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: AppTheme.forgeAmber, size: 28),
                      const SizedBox(height: 12),
                      Text('Appearance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.onSurface)),
                      const SizedBox(height: 6),
                      Text('Switch the complete app between light and dark mode. The change is applied immediately across all screens.', style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
                      const SizedBox(height: 16),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(isDark ? 'Dark mode' : 'Light mode'),
                        subtitle: Text(isDark ? 'Dark colors are active' : 'Light colors are active'),
                        secondary: Icon(isDark ? Icons.nightlight_round : Icons.wb_sunny_outlined),
                        value: isDark,
                        onChanged: (_) => controller.toggle(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppTheme.successGreen, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Your selected theme is saved locally and will be restored when the app is opened again.', style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
