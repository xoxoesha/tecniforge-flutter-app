import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/notifications_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _titleController = TextEditingController(text: 'Follow up with client');
  final _bodyController = TextEditingController(text: "Don't forget to call Al-Noor Traders about invoice #2291");
  int _delaySeconds = 10;
  String? _lastAction;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  static const _channelId = 'tecniforge_reminders';
  static const _channelName = 'Reminders';

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Scheduled reminders from TecniForge',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<void> _sendNow() async {
    await notificationsPlugin.show(
      0,
      _titleController.text.isEmpty ? 'TecniForge reminder' : _titleController.text,
      _bodyController.text,
      _details,
    );
    setState(() => _lastAction = 'Sent immediately');
  }

  Future<void> _scheduleDelayed() async {
    // zonedSchedule hands the notification off to Android's own alarm
    // system, so it fires at the exact scheduled time even if the app
    // has been fully closed — unlike Future.delayed, which only works
    // while the app process is still alive.
    final scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(seconds: _delaySeconds));
    await notificationsPlugin.zonedSchedule(
      1,
      _titleController.text.isEmpty ? 'TecniForge reminder' : _titleController.text,
      _bodyController.text,
      scheduledTime,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  void _startSchedule() {
    setState(() => _lastAction = 'Scheduled — will fire in $_delaySeconds seconds. You can leave this screen.');
    _scheduleDelayed();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppTopBar(title: 'Notifications', subtitle: 'Schedule local reminders', showBack: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(label: 'Title', controller: _titleController, icon: Icons.title),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Message', controller: _bodyController, icon: Icons.notes),
                  const SizedBox(height: 20),
                  const Text('Delay before scheduled notification', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.slate)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [5, 10, 30, 60].map((s) {
                      final selected = _delaySeconds == s;
                      return ChoiceChip(
                        label: Text('${s}s'),
                        selected: selected,
                        onSelected: (_) => setState(() => _delaySeconds = s),
                        selectedColor: AppTheme.navyPrimary,
                        labelStyle: TextStyle(color: selected ? Colors.white : AppTheme.ink, fontSize: 12),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50), side: const BorderSide(color: AppTheme.cardBorder)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  AppButton(label: 'Send Now', onPressed: _sendNow, icon: Icons.flash_on),
                  const SizedBox(height: 10),
                  AppButton(label: 'Schedule Reminder', onPressed: _startSchedule, variant: AppButtonVariant.secondary, icon: Icons.schedule),
                  if (_lastAction != null) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_lastAction!, style: const TextStyle(fontSize: 12, color: AppTheme.ink))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
