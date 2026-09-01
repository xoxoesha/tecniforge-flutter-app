import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/cart_state.dart';
import 'services/notifications_service.dart';
import 'services/push_notifications_service.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

// ---------------------------------------------------------------------------
// TecniForge — Unified app
//
// One MaterialApp, one home menu screen. Every feature screen is pushed on
// top via Navigator, and the back button returns to the menu. State that
// needs to be shared across screens (cart, theme) is provided at the top
// via Provider/ChangeNotifier — see services/cart_state.dart and
// theme/app_theme.dart (ThemeController).
// ---------------------------------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications();
  await initPushNotifications();
  runApp(
    // ChangeNotifierProvider makes CartState/ThemeController reachable from
    // every screen below it in the widget tree — the "store" that
    // Redux/Context would provide in React/React Native.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartState()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: const TecniForgeApp(),
    ),
  );
}

class TecniForgeApp extends StatelessWidget {
  const TecniForgeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TecniForge',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: context.watch<ThemeController>().mode,
      home: const SplashScreen(),
    );
  }
}
