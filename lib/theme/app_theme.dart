import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  AppTheme._();
  static const navyDeep = Color(0xFF0B1E3D);
  static const navyPrimary = Color(0xFF16305C);
  static const steelAccent = Color(0xFF3D6DB5);
  static const forgeAmber = Color(0xFFE8A33D);
  static const canvas = Color(0xFFF5F7FA);
  static const ink = Color(0xFF1A1D29);
  static const slate = Color(0xFF6B7280);
  static const errorRed = Color(0xFFC0392B);
  static const successGreen = Color(0xFF1D8A5A);
  static const cardBorder = Color(0xFFE7EAF0);
  static const radiusSm = 10.0;
  static const radiusMd = 14.0;

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: canvas,
    colorScheme: ColorScheme.fromSeed(seedColor: navyPrimary, brightness: Brightness.light, primary: navyPrimary, error: errorRed),
    cardColor: Colors.white,
    dividerColor: cardBorder,
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF10141C),
    colorScheme: ColorScheme.fromSeed(
      seedColor: steelAccent,
      brightness: Brightness.dark,
      primary: const Color(0xFF7FA8E8),
      secondary: forgeAmber,
      surface: const Color(0xFF171D27),
      error: const Color(0xFFFF6B5E),
    ),
    cardColor: const Color(0xFF171D27),
    dividerColor: const Color(0xFF2B3442),
  );

  static ThemeData get themeData => lightTheme;
}

class ThemeController extends ChangeNotifier {
  static const _prefsKey = 'app_theme_mode';
  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  ThemeController() { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_prefsKey) == 'dark') {
      _mode = ThemeMode.dark;
      notifyListeners();
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> toggle() => setMode(isDark ? ThemeMode.light : ThemeMode.dark);
}
