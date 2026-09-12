// WIDGET TEST — checks the shared AppButton component (used on almost
// every screen: Add Task, Save Client, Retry, etc). Runs without a real
// phone; Flutter builds the widget in memory and simulates a tap.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecniforge_flutterapp/widgets/shared_widgets.dart';

void main() {
  group('AppButton', () {
    testWidgets('shows the given label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AppButton(label: 'Add Task', onPressed: () {}))),
      );

      expect(find.text('Add Task'), findsOneWidget);
    });

    testWidgets('calls onPressed exactly once when tapped', (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AppButton(label: 'Save', onPressed: () => tapCount++))),
      );

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(tapCount, 1);
    });

    testWidgets('shows an icon when one is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppButton(label: 'Add Task', onPressed: () {}, icon: Icons.add)),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows no icon when none is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AppButton(label: 'Save', onPressed: () {}))),
      );

      expect(find.byType(Icon), findsNothing);
    });
  });
}