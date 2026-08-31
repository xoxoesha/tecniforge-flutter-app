import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import 'home_menu_screen.dart';

// Shown for a couple seconds on launch, then replaces itself with the home
// menu (using pushReplacement so the splash isn't left on the back stack).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(animatedRoute(const HomeMenuScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDeep,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: AppTheme.forgeAmber, borderRadius: BorderRadius.circular(18)),
              alignment: Alignment.center,
              child: const Text('TF', style: TextStyle(color: AppTheme.navyDeep, fontSize: 28, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 20),
            const Text('TECNIFORGE', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 3)),
            const SizedBox(height: 6),
            const Text('Business Autopilot', style: TextStyle(color: Color(0xFF9FB0CC), fontSize: 12)),
            const SizedBox(height: 32),
            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppTheme.forgeAmber, strokeWidth: 2.5)),
          ],
        ),
      ),
    );
  }
}
