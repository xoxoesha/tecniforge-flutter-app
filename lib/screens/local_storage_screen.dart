import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class LocalStorageScreen extends StatefulWidget {
  const LocalStorageScreen({super.key});
  @override
  State<LocalStorageScreen> createState() => _LocalStorageScreenState();
}

class _LocalStorageScreenState extends State<LocalStorageScreen> {
  final _controller = TextEditingController();
  int _visitCount = 0;
  bool _saved = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final note = prefs.getString('business_note') ?? '';
    final count = (prefs.getInt('visit_count') ?? 0) + 1;
    await prefs.setInt('visit_count', count);
    setState(() {
      _controller.text = note;
      _visitCount = count;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('business_note', _controller.text);
    setState(() => _saved = true);
  }

  Future<void> _clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('business_note');
    setState(() {
      _controller.clear();
      _saved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppTopBar(title: 'Business Notes', subtitle: 'Saved locally — persists across restarts', showBack: true),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: AppTheme.navyPrimary, size: 20),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('App opened', style: TextStyle(fontSize: 11, color: AppTheme.slate)),
                          Text('$_visitCount time${_visitCount == 1 ? '' : 's'}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.ink)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppTextField(label: 'Quick note', controller: _controller, hint: 'e.g. Follow up with Al-Noor Traders'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: AppButton(label: 'Save', onPressed: _save, icon: Icons.save)),
                    const SizedBox(width: 10),
                    Expanded(child: AppButton(label: 'Clear', onPressed: _clear, variant: AppButtonVariant.secondary, icon: Icons.delete_outline)),
                  ],
                ),
                if (_saved) ...[
                  const SizedBox(height: 10),
                  const Row(children: [
                    Icon(Icons.check_circle, color: AppTheme.successGreen, size: 14),
                    SizedBox(width: 6),
                    Text('Saved — close and reopen the app to verify it persists.', style: TextStyle(color: AppTheme.successGreen, fontSize: 11)),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
