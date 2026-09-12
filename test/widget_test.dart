// WIDGET TEST — a "smoke test" for the app's entry point. Confirms the app
// launches without crashing, shows the splash screen first, then
// automatically navigates to the home menu after the splash delay.
//
// This replaces the old default counter test, which referenced `MyApp` —
// a class that no longer exists in this project (the app widget is now
// `TecniForgeApp`) — so the old test could not even compile.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tecniforge_flutterapp/main.dart';
import 'package:tecniforge_flutterapp/services/cart_state.dart';
import 'package:tecniforge_flutterapp/theme/app_theme.dart';

void main() {
  testWidgets('App shows splash screen, then navigates to the home menu', (tester) async {
    // TecniForgeApp expects CartState/ThemeController from Provider,
    // same as the real app sets up in main.dart.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartState()),
          ChangeNotifierProvider(create: (_) => ThemeController()),
        ],
        child: const TecniForgeApp(),
      ),
    );

    // Splash screen is shown first.
    expect(find.text('TECNIFORGE'), findsOneWidget);
    expect(find.text('Business Autopilot'), findsOneWidget);

    // Splash screen auto-navigates after a 2-second delay — fast-forward
    // past it instead of actually waiting.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Home menu should now be showing its feature grid.
    expect(find.text('Explore features'), findsOneWidget);
    expect(find.text('Clients'), findsOneWidget);
  });
}