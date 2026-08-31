import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ComponentDemoScreen extends StatefulWidget {
  const ComponentDemoScreen({super.key});
  @override
  State<ComponentDemoScreen> createState() => _ComponentDemoScreenState();
}

class _ComponentDemoScreenState extends State<ComponentDemoScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppTopBar(title: 'Component Library', subtitle: 'Reusable pieces, one theme', showBack: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Badges', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.ink)),
                  const SizedBox(height: 8),
                  const Wrap(spacing: 8, children: [
                    AppBadge(label: 'High', color: AppTheme.errorRed),
                    AppBadge(label: 'Med', color: AppTheme.forgeAmber),
                    AppBadge(label: 'Low', color: AppTheme.steelAccent),
                  ]),
                  const SizedBox(height: 20),
                  const Text('Card', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.ink)),
                  const SizedBox(height: 8),
                  AppCard(
                    onTap: () {},
                    child: const Row(children: [
                      Icon(Icons.business, color: AppTheme.steelAccent, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Al-Noor Traders', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppTheme.ink)),
                          Text('Tap to view details', style: TextStyle(fontSize: 11, color: AppTheme.slate)),
                        ]),
                      ),
                      Icon(Icons.chevron_right, color: Color(0xFFC4CAD6)),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  const Text('Text field', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.ink)),
                  const SizedBox(height: 8),
                  AppTextField(label: 'Client name', controller: _nameController, hint: 'e.g. Ayesha Khan', icon: Icons.person_outline),
                  const SizedBox(height: 20),
                  const Text('Buttons', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.ink)),
                  const SizedBox(height: 8),
                  AppButton(label: 'Primary action', onPressed: () {}, icon: Icons.check),
                  const SizedBox(height: 10),
                  AppButton(label: 'Secondary action', onPressed: () {}, variant: AppButtonVariant.secondary),
                  const SizedBox(height: 10),
                  AppButton(label: 'Delete', onPressed: () {}, variant: AppButtonVariant.danger, icon: Icons.delete_outline),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
